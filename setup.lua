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

  mod.syncInfo()
  Handlers.remove("setup")
  Handlers.add(
    "setup.syncInfo",
    { Action = "Sync-Protocol", From = ao.env.Process.Owner },
    mod.syncInfo
  )
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
    return print(Colors.red .. "Something went wrong while obtaining protocol info:|" .. Colors.reset)
  end

  Tokens = tokens
  Oracle = cfg.Oracle
  MaxDiscount = tonumber(cfg["Max-Discount"])
  DiscountInterval = tonumber(cfg["Discount-Interval"])

  print(Colors.green .. "Loaded protocol info!" .. Colors.reset)
  print(Colors.blue .. "Please keep in mind that any protocol updates require you to call the Action='Sync-Protocol' handler!" .. Colors.reset)
end

return mod
