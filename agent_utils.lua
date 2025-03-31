local utils = require ".utils"

local mod = {}

-- Convert a biginteger with a denomination to a float string
---@param val Bint|string Bigint value
---@param denomination number Denomination
function mod.denominatedNumber(val, denomination)
  local stringVal = tostring(val)
  local len = #stringVal

  if stringVal == "0" then return "0" end

  -- if denomination is greater than or equal to the string length, prepend "0."
  if denomination >= len then
    return "0." .. string.rep("0", denomination - len) .. string.gsub(stringVal, "0+$", "")
  end

  -- insert decimal point at the correct position from the back
  local integer_part = string.sub(stringVal, 1, len - denomination)
  local fractional_part = string.gsub(
    string.sub(stringVal, len - denomination + 1),
    "0+$",
    ""
  )

  -- if the fractional_part is 0, then we only need to return the integer part
  if fractional_part == "" then
    return integer_part
  end

  return integer_part .. "." .. fractional_part
end

-- Check if an address is allowed to interact with the agent
---@param addr string Address to check
function mod.isAuthorized(addr)
  if addr == ao.env.Process.Id or addr == ao.env.Process.Owner then return true end
  return utils.includes(addr, Admins)
end

-- Knuth shuffle implementation for a table
---@generic T : unknown
---@param t T[] The table to shuffle
function mod.shuffle(t)
  local tLen = #t
  for i = tLen, 2, -1 do
    local j = math.random(i)
    t[i], t[j] = t[j], t[i]
  end
end

return mod
