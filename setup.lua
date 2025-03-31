local liquidations = require "liquidations"
local agent_utils = require "agent_utils"
local json = require "json"

local mod = {}

-- Setup the agent
function mod.setup()
  print(Colors.green .. "Welcome to you new liquidator agent for " .. Colors.blue .. "LiquidOps" .. Colors.green .. "!" .. Colors.reset)
  print(Colors.gray .. "Thank you for becoming part of the protocol:)" .. Colors.reset)
  print(Colors.blue .. "Setting up your process..." .. Colors.reset)

  if not ao.env.Process.Tags["Cron-Interval"] then
    return print(Colors.red .. "No cronjob set up for this process, please spawn a new one" .. Colors.reset)
  end

  local syncRes = mod.syncInfo()
  if not syncRes then return end

  Handlers.remove("setup")
  Handlers.add(
    "setup.syncInfo",
    function (msg)
      if not agent_utils.isAuthorized(msg.From) then return false end
      return msg.Tags.Action == "Sync-Protocol"
    end,
    mod.syncInfo
  )
  Handlers.add(
    "liquidations.findOpportunities",
    { Action = "Cron" },
    liquidations.findOpportunities
  )
  Handlers.add(
    "liquidations.pauseResume",
    function (msg)
      if not agent_utils.isAuthorized(msg.From) then return false end
      return msg.Tags.Action == "Pause" or msg.Tags.Action == "Resume"
    end,
    liquidations.pauseResume
  )

  print(Colors.gray .. "The agent is now running. You can always pause liquidation discovery with Action = " .. Colors.blue .. "Pause" .. Colors.reset)
end

-- Sync protocol info
function mod.syncInfo()
  print(Colors.blue .. "Obtaining protocol info..." .. Colors.reset)

  ---@type boolean, Token[]|nil, table<string, string>|nil
  local obtained, tokens, cfg = pcall(function ()
    -- get info
    local res = ao.send({ Target = Controller, Action = "Info" }).receive()

    -- parse if needed
    if type(res.Data) == "table" then
      return res.Data, res.Tags
    end

    return json.decode(res.Data), res.Tags
  end)

  if not obtained or not tokens or not cfg then
    print(Colors.red .. "Something went wrong while obtaining protocol info:|" .. Colors.reset)
    return false
  end

  Tokens = tokens
  MaxDiscount = tonumber(cfg["Max-Discount"])
  DiscountInterval = tonumber(cfg["Discount-Interval"])

  print(Colors.green .. "Loaded protocol info!" .. Colors.reset)
  print(Colors.yellow .. "\nProtocol info is synced on liquidations, but it can be triggered manually with the Action =" .. Colors.blue "Sync-Protocol" .. Colors.yellow .. " handler. Keep in mind that if the protocol info is not up to date, your process will not be able to liquidate." .. Colors.reset)
  print(Colors.gray .. "The agent is running in Focus-Mode = " .. Colors.blue .. FocusMode .. Colors.gray .. ". Read more about this in the agent's readme" .. Colors.reset)
end

return mod
