local utils = require ".utils"
local bint = require ".bint"(512)

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
  local integerPart = string.sub(stringVal, 1, len - denomination)
  local fractionalPart = string.gsub(
    string.sub(stringVal, len - denomination + 1),
    "0+$",
    ""
  )

  -- if the fractional_part is 0, then we only need to return the integer part
  if fractionalPart == "" then
    return integerPart
  end

  return integerPart .. "." .. fractionalPart
end

-- Convert a float/number to a biginteger with a denomination
---@param val number|string Float/number value
---@param denomination number Denomination
function mod.integerRepresentation(val, denomination)
  local integerPart, fractionalPart = string.match(tostring(val), "([^%.]+)%.?(.*)")

  if fractionalPart == "" or fractionalPart == "0" then
    return bint(integerPart .. string.rep("0", denomination))
  end

  local fracLen = #fractionalPart
  if denomination > fracLen then
    fractionalPart = fractionalPart .. string.rep("0", denomination - fracLen)
  elseif denomination < fracLen then
    fractionalPart = string.sub(fractionalPart, 1, denomination)
  end

  return bint(integerPart .. fractionalPart)
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

-- Find index in table
---@generic T : unknown
---@param fn fun(val: T): boolean The find function that receives the current element and returns true if it matches, false if it doesn't
---@param t T[] Array to find the index in
---@return integer|nil
function mod.findIndex(fn, t)
  for index, value in ipairs(t) do
    if fn(value) then
      return index
    end
  end
  return nil
end

-- Get the value of one token quantity in another
-- token quantity
---@param from { ticker: string, quantity: Bint, denomination: number } From token ticker, quantity and denomination
---@param to { ticker: string, denomination: number } Target token ticker and denomination
---@param rawPrices RawPrices Pre-fetched prices
---@return Bint
function mod.getValueInToken(from, to, rawPrices)
  -- prices
  local fromPrice = oracle.getUSDDenominated(rawPrices[from.ticker].price)
  local toPrice = oracle.getUSDDenominated(rawPrices[to.ticker].price)

  -- get value of the "from" token quantity in USD with extra precision
  local usdValue = bint.udiv(
    from.quantity * fromPrice,
    bint("1" .. string.rep("0", from.denomination))
  )

  -- convert usd value to the token quantity
  -- accouting for the denomination
  return bint.udiv(
    usdValue * bint("1" .. string.rep("0", to.denomination)),
    toPrice
  )
end

return mod
