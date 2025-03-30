local mod = {}

-- Discover liquidations and try to liquidate them
---@type HandlerFunction
function mod.findOpportunities()
  if Paused then return end
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
  end
end

return mod
