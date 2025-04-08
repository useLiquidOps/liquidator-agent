local agent_utils = require "agent_utils"
local utils = require ".utils"
local setup = require "setup"
local wallet = require "wallet"
local config = require "config"
local json = require "json"

-- liquidops controller
Controller = Controller or "SmmMv0rJwfIDVM3RvY2-P729JFYwhdGSeGo2deynbfY"

---@alias Token { id: string; ticker: string; denomination: number; oToken: string; }
---@type Token[]
Tokens = Tokens or {}
MaxDiscount = MaxDiscount or 0
DiscountInterval = DiscountInterval or 0
---@type table<string, string>
Balances = Balances or {}
---@type string[]
Admins = Admins or {}
Paused = Paused or false
NoShuffle = NoShuffle or false
---@type "single"|"multiple"
FocusMode = FocusMode or "single"
---@type string[]
BlacklistedTokens = BlacklistedTokens or {}
Slippage = Slippage or 1

Colors.yellow = "\27[33m"

-- setup can be called again if it didn't work
Handlers.add(
  "setup.setup",
  function (msg)
    if not agent_utils.isAuthorized(msg.From) then return false end
    return msg.Tags.Action == "Setup"
  end,
  setup.setup
)
Handlers.add(
  "process.info",
  { Action = "Info" },
  function (msg)
    msg.reply({
      Name = Name or ao.env.Process.Owner .. "'s liquidator agent",
      Admins = json.encode(Admins),
      Status = Paused and "Paused" or "Running",
      ["Focus-Mode"] = FocusMode
    })
  end
)
Handlers.add(
  "process.configure",
  function (msg)
    if not agent_utils.isAuthorized(msg.Tags.Sender) then return false end
    return msg.Tags.Action == "Set-Config"
  end,
  config.update
)
Handlers.add(
  "wallet.depositGate",
  Handlers.utils.continue({ Action = "Credit-Notice" }),
  wallet.depositGate
)
Handlers.add(
  "wallet.refund",
  function (msg)
    if msg.Tags.Action ~= "Credit-Notice" then return false end
    local token = msg.From
    local sender = msg.Tags.Sender

    -- token has to be one of the supported tokens
    ---@param t Token
    if utils.find(function (t) return t.id == token end, Tokens) == nil then return false end

    return sender == Controller or utils.find(
      ---@param t Token
      function (t) return t.oToken == sender end,
      Tokens
    ) ~= nil
  end,
  wallet.refund -- silent deposit
)
Handlers.add(
  "wallet.deposit",
  function (msg)
    if not agent_utils.isAuthorized(msg.Tags.Sender) then return false end
    return msg.Tags.Action == "Credit-Notice"
  end,
  wallet.deposit
)
Handlers.add(
  "wallet.balances",
  { Action = "Balances" },
  wallet.balances
)
Handlers.add(
  "wallet.withdraw",
  function (msg)
    if not agent_utils.isAuthorized(msg.From) then return false end
    return msg.Tags.Action == "Withdraw"
  end,
  wallet.withdraw
)
Handlers.add(
  "wallet.debitNotice",
  { Action = "Debit-Notice" },
  wallet.debitNotice
)

setup.setup()
