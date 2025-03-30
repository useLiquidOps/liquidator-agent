local mod = {}

-- Convert a biginteger with a denomination to a float string
---@param val Bint|string Bigint value
---@param denomination number Denomination
function mod.denominatedNumber(val, denomination)
  local stringVal = tostring(val)
  local len = #stringVal

  if stringVal == "0" then return "0.0" end

  -- if denomination is greater than or equal to the string length, prepend "0."
  if denomination >= len then
    return "0." .. string.rep("0", denomination - len) .. stringVal
  end

  -- insert decimal point at the correct position from the back
  local integer_part = string.sub(stringVal, 1, len - denomination)
  local fractional_part = string.sub(stringVal, len - denomination + 1)

  return integer_part .. "." .. fractional_part
end

return mod
