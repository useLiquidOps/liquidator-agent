local bint = require ".bint"(512)
local utils = require ".utils"
local tokenUtils = require ".token"
local json = require "json"

local mod = {}

-- Do not let 3rd party tokens or 3rd parties to deposit
---@type HandlerFunction
function mod.depositGate(msg)
  local sender = msg.Tags.Sender
  local token = utils.find(function (t) return t.id == msg.From end, Tokens)

  if sender == ao.env.Process.Owner and token ~= nil then return end

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

  Balances[token.id] = bint(Balances[token.id] or "0") + bint(msg.Tags.Quantity)

  print(
    Colors.green ..
    "New deposit of " ..
    Colors.blue ..
    tokenUtils.denominatedNumber(msg.Tags.Quantity, token.denomination) ..
    " " ..
    token.ticker ..
    Colors.green ..
    "!"
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
      tokenUtils.denominatedNumber(Balances[token.id] or "0", token.denomination) ..
      " " ..
      token.ticker ..
      Colors.reset
    )
  end

  if msg.From ~= ao.env.Process.Id then
    msg.reply({ Data = json.encode(Balances) })
  end
end

return mod
