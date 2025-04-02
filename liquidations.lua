local agent_utils = require "agent_utils"
local bint = require ".bint"(512)
local utils = require ".utils"
local json = require "json"

local mod = {}

---@alias CollateralBorrow { token: string, ticker: string, quantity: string }
---@alias QualifyingPosition { target: string, depts: CollateralBorrow[], collaterals: CollateralBorrow[], discount: string }
---@alias RawPrices table<string, { price: number, timestamp: number }>

-- Discover liquidations and try to liquidate them
---@type HandlerFunction
function mod.findOpportunities()
  if Paused then return end

  ---@type string
  local res = ao.send({
    Target = Controller,
    Action = "Get-Liquidations"
  }).receive().Data

  ---@type boolean, { liquidations: QualifyingPosition[], tokens: Token[], maxDiscount: integer, discountInterval: integer, prices: RawPrices, precisionFactor: number }
  local parsed, data = pcall(json.decode, res)

  if not parsed or type(data) ~= "table" then
    return print(Colors.red .. "Could not parse liquidations data" .. Colors.reset)
  end

  Tokens = data.tokens
  MaxDiscount = data.maxDiscount
  DiscountInterval = data.discountInterval

  local zero = bint.zero()

  ---@type table<string, Bint>
  local balances = {}
  for addr, raw in pairs(Balances) do
    balances[addr] = bint(raw)
  end

  -- filter out the opportunities that have dept
  -- in a non zero balance's token
  ---@type QualifyingPosition[]
  local availableLiquidations = {}

  for _, opportunity in ipairs(data.liquidations) do
    for _, dept in ipairs(opportunity.depts) do
      local deptQty = bint(dept.quantity)
      local balanceQty = balances[dept.token]

      if bint.ult(zero, deptQty) and bint.ult(zero, balanceQty) then
        table.insert(availableLiquidations, opportunity)
        goto continue
      end
    end
    ::continue::
  end

  -- shuffle for more randomized liquidations across multiple agents
  -- in the protocol
  if not NoShuffle then
    agent_utils.shuffle(availableLiquidations)
  end

  ---@type table<string, number>
  local denominations = {}
  for _, token in ipairs(Tokens) do
    denominations[token.id] = token.denomination
  end

  for _, opportunity in ipairs(availableLiquidations) do
    for _, dept in ipairs(opportunity.depts) do
      local deptQty = bint(dept.quantity)
      local balanceQty = balances[dept.token]

      for _, collateral in ipairs(opportunity.collaterals) do
        if not utils.includes(collateral.token, BlacklistedTokens) then
          local collateralQty = bint(collateral.quantity)

          -- how much the collateral is worth
          local success, collateralValue = pcall(
            agent_utils.getValueInToken,
            {
              quantity = collateralQty,
              ticker = collateral.ticker,
              denomination = denominations[collateral.token]
            },
            {
              ticker = dept.ticker,
              denomination = denominations[dept.token]
            },
            data.prices
          )

          if success then
            -- apply discount on the collateral value
            if opportunity.discount > 0 then
              collateralValue = bint.udiv(
                collateralValue * bint(100 * data.precisionFactor - opportunity.discount),
                bint(100 * data.precisionFactor)
              )
            end

            -- the maximum the liquidator can liquidate is either the
            -- liquidator balance of the specific token, the dept qty,
            -- or the value of the collateral (whichever is less)
            local liquidateQty = bint.min(deptQty, balanceQty)

            -- expected quantity with discount
            local expectedQty = zero

            if bint.ule(collateralValue, liquidateQty) then
              liquidateQty = collateralValue
              expectedQty = collateralQty
            else
              local success, deptValue = pcall(
                agent_utils.getValueInToken,
                {
                  quantity = liquidateQty,
                  ticker = dept.ticker,
                  denomination = denominations[dept.token]
                },
                {
                  ticker = collateral.ticker,
                  denomination = denominations[collateral.token]
                },
                data.prices
              )

              if success then
                if opportunity.discount > 0 then
                  deptValue = bint.udiv(
                    deptValue * bint(100 * data.precisionFactor + opportunity.discount),
                    bint(100 * data.precisionFactor)
                  )
                end

                expectedQty = deptValue
              else
                print(Colors.yellow .. "Failed to get value for dept " .. dept.ticker .. " in " .. collateral.ticker)
              end
            end

            -- apply slippage
            local maxReceiveQty = expectedQty

            if Slippage >= 0 and not bint.eq(expectedQty, zero) then
              expectedQty = bint.udiv(
                expectedQty * bint(100 * data.precisionFactor - math.floor(Slippage * data.precisionFactor)),
                bint(100 * data.precisionFactor)
              )
            end

            -- liquidate
            if bint.ult(zero, expectedQty) then
              ao.send({
                Target = dept.token,
                Action = "Transfer",
                Quantity = tostring(liquidateQty),
                Recipient = Controller,
                ["X-Action"] = "Liquidate",
                ["X-Target"] = opportunity.target,
                ["X-Reward-Token"] = collateral.token,
                ["X-Min-Expected-Quantity"] = tostring(expectedQty)
              })

              -- if the focus mode is single, then no more liquidations will occur in this message
              if FocusMode == "single" then
                goto stop
              end

              -- if the focus mode is multiple, we need to update the user's position
              dept.quantity = tostring(deptQty - liquidateQty)
              collateral.quantity = tostring(collateralQty - maxReceiveQty)
            end
          else
            print(Colors.yellow .. "Failed to get value for collateral " .. collateral.ticker .. " in " .. dept.ticker)
          end
        end
      end
    end
  end
  ::stop::
end

-- Pause or resume liquidations
---@type HandlerFunction
function mod.pauseResume(msg)
  Paused = msg.Tags.Action == "Pause"

  if Paused then
    print(Colors.yellow .. "Paused liquidation discovery. No new liquidations will occur." .. Colors.reset)
    print(Colors.gray .. "You can always resume liquidation discovery with Action = " .. Colors.blue .. "Resume" .. Colors.reset)
  else
    print(Colors.yellow .. "Resumed liquidation discovery. The agent will start liquidating again." .. Colors.reset)
    print(Colors.gray .. "You can always pause liquidation discovery with Action = " .. Colors.blue .. "Pause" .. Colors.reset)
    print(Colors.gray .. "The agent is running in Focus-Mode = " .. Colors.blue .. FocusMode .. Colors.gray .. ". Read more about this in the agent's readme" .. Colors.reset)
  end
end

return mod
