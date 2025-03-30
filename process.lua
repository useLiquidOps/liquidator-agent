local agent_utils = require ".agent_utils"
local setup = require "setup"
local wallet = require "wallet"

-- liquidops controller
Controller = Controller or "SmmMv0rJwfIDVM3RvY2-P729JFYwhdGSeGo2deynbfY"

---@alias Token { id: string; ticker: string; denomination: number; oToken: string; }
---@type Token[]
Tokens = Tokens or {}
MaxDiscount = MaxDiscount or 0
DiscountInterval = DiscountInterval or 0
Oracle = Oracle or ""
---@type table<string, string>
Balances = Balances or {}
---@type string[]
Admins = Admins or {}

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
  "wallet.depositGate",
  Handlers.utils.continue({ Action = "Credit-Notice" }),
  wallet.depositGate
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
  "wallet.withdraw",
  function (msg)
    if not agent_utils.isAuthorized(msg.From) then return false end
    return msg.Tags.Action == "Withdraw"
  end,
  wallet.withdraw
)

setup.setup()
