local agent_utils = require "agent_utils"
local bint = require ".bint"(512)
local utils = require ".utils"
local json = require "json"

local mod = {}

-- Do not let 3rd party tokens or 3rd parties to deposit
---@type HandlerFunction
function mod.depositGate(msg)
  local sender = msg.Tags.Sender
  local token = utils.find(function (t) return t.id == msg.From end, Tokens)

  if agent_utils.isAuthorized(sender) and token ~= nil then return end

  msg.reply({
    Action = "Transfer",
    Recipient = sender,
    Quantity = msg.Tags.Quantity
  })
end

-- Handle deposits
---@type HandlerFunction
function mod.deposit(msg)
  ---@type Token|nil
  local token = utils.find(function (t) return t.id == msg.From end, Tokens)
  if not token then return end

  Balances[token.id] = tostring(bint(Balances[token.id] or "0") + bint(msg.Tags.Quantity))

  print(
    Colors.green ..
    "New deposit of " ..
    Colors.blue ..
    agent_utils.denominatedNumber(msg.Tags.Quantity, token.denomination) ..
    " " ..
    token.ticker ..
    Colors.green ..
    "!" ..
    Colors.reset
  )
end

-- Return process balances
---@type HandlerFunction
function mod.balances(msg)
  print(Colors.gray .. "Latest process balances:" .. Colors.reset)
  for _, token in ipairs(Tokens) do
    print(
      Colors.gray ..
      " - " ..
      Colors.blue ..
      agent_utils.denominatedNumber(Balances[token.id] or "0", token.denomination) ..
      " " ..
      token.ticker ..
      Colors.reset
    )
  end

  if msg.From ~= ao.env.Process.Id then
    msg.reply({ Data = json.encode(Balances) })
  end
end

-- Withdraw funds
---@type HandlerFunction
function mod.withdraw(msg)
  ---@type Token|nil
  local token = utils.find(function (t) return t.id == msg.Tags.Token end, Tokens)
  local quantity = bint(msg.Tags.Quantity)
  local recipient = msg.Tags.Recipient or msg.From

  if not token then
    local err = msg.Tags.Token and "Couldn't withdraw: no balance maintained for token: " .. msg.Tags.Token or
      "Couldn't withdraw: no token provided"

    if msg.From ~= ao.id then
      msg.reply({ Error = err })
    end
    return print(Colors.red .. err .. Colors.reset)
  end

  local balance = bint(Balances[token.id] or "0")

  if bint.ult(balance, quantity) then
    local err = "Not enough balance to withdraw " ..
      agent_utils.denominatedNumber(msg.Tags.Quantity, token.denomination) ..
      " " ..
      token.ticker ..
      ", current balance is " ..
      agent_utils.denominatedNumber(balance, token.denomination) ..
      " " ..
      token.ticker

    if msg.From ~= ao.id then
      msg.reply({ Error = err })
    end
    return print(Colors.red .. err .. Colors.reset)
  end

  print(Colors.blue .. "Withdrawing..." .. Colors.reset)

  local res = ao.send({
    Target = token.id,
    Action = "Transfer",
    Quantity = msg.Tags.Quantity,
    Recipient = recipient
  }).receive()

  if not res.Tags.Error and res.Tags.Action == "Debit-Notice" then
    if Balances[token.id] then
      Balances[token.id] = tostring(
        bint.min(bint.zero(), bint(Balances[token.id]) - bint(res.Tags.Quantity))
      )
    end

    print(
      Colors.green ..
      "Withdrawn " ..
      Colors.blue ..
      agent_utils.denominatedNumber(res.Tags.Quantity, token.denomination) ..
      " " ..
      token.ticker ..
      Colors.green ..
      "!" ..
      Colors.reset
    )

    if msg.From ~= ao.env.Process.Id then
      msg.reply({ Result = "success" })
    end
  else
    print(
      Colors.red ..
      "Failed to withdraw: " ..
      res.Tags.Error or "unknown error" ..
      Colors.reset
    )

    if msg.From ~= ao.env.Process.Id then
      msg.reply({
        Result = "failure",
        Error = res.Tags.Error or "Unknown error"
      })
    end
  end
end

-- This only handles debit notices that are not
-- the result of withdrawing
---@type HandlerFunction
function mod.debitNotice(msg)
  local token = msg.From

  if Balances[token] then
    Balances[token] = tostring(
      bint.min(bint.zero(), bint(Balances[token]) - bint(msg.Tags.Quantity))
    )
  end
end

-- Silently add refunds to the balances
---@type HandlerFunction
function mod.refund(msg)
  Balances[msg.From] = tostring(bint(Balances[msg.From] or "0") + bint(msg.Tags.Quantity))
end

return mod
