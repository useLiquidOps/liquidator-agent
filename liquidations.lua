local agent_utils = require "agent_utils"
local bint = require ".bint"(512)
local utils = require ".utils"
local json = require "json"

local mod = {}

---@alias CollateralBorrow { token: string, ticker: string, quantity: string }
---@alias QualifyingPosition { depts: CollateralBorrow[], collaterals: CollateralBorrow[], discount: string }
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

  ---@type boolean, { liquidations: QualifyingPosition[], tokens: Token[], maxDiscount: integer, discountInterval: integer, prices: RawPrices }
  local parsed, data = pcall(json.decode, res)

  if not parsed or type(data) ~= "table" then
    return print(Colors.red .. "Could not parse liquidations data" .. Colors.reset)
  end

  Tokens = data.tokens
  MaxDiscount = data.maxDiscount
  DiscountInterval = data.discountInterval

  agent_utils.shuffle(data.liquidations)

  ---@type table<string, Bint>
  local balances = {}
  for addr, raw in pairs(Balances) do
    balances[addr] = bint(raw)
  end
  local zero = bint.zero()

  for _, opportunity in ipairs(data.liquidations) do
    for _, dept in ipairs(opportunity.depts) do
      local deptQty = bint(dept.quantity)
      local balanceQty = balances[dept.token]

      if not bint.ule(deptQty, zero) and not bint.ule(balanceQty, zero) then
        local liquidateQty = bint.min(deptQty, balanceQty)


      end
    end
  end
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
