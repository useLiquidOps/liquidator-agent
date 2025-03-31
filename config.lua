local agent_utils = require "agent_utils"
local utils = require ".utils"

local mod = {}

---@type HandlerFunction
function mod.update(msg)
  local newFocusMode = msg.Tags["Focus-Mode"]
  if newFocusMode and utils.includes(string.lower(newFocusMode), { "single", "multiple" }) then
    FocusMode = string.lower(newFocusMode)
  end

  if msg.Tags["Add-Admin"] then
    table.insert(Admins, msg.Tags["Add-Admin"])
  end

  if msg.Tags["Remove-Admin"] then
    local idx = agent_utils.findIndex(
      function (val) return val == msg.Tags["Remove-Admin"] end,
      Admins
    )

    if idx then
      table.remove(Admins, idx)
    end
  end

  if msg.Tags["Add-Blacklisted-Token"] then
    table.insert(BlacklistedTokens, msg.Tags["Add-Blacklisted-Token"])
  end

  if msg.Tags["Remove-Blacklisted-Token"] then
    local idx = agent_utils.findIndex(
      function (val) return val == msg.Tags["Remove-Blacklisted-Token"] end,
      BlacklistedTokens
    )

    if idx then
      table.remove(BlacklistedTokens, idx)
    end
  end
end

return mod
