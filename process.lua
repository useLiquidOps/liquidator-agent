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

Colors.yellow = "\27[33m"

-- setup can be called again if it didn't work
Handlers.add(
  "setup.setup",
  { Action = "Setup", From = ao.env.Process.Owner },
  setup.setup
)
Handlers.add(
  "wallet.depositGate",
  Handlers.utils.continue({ Action = "Credit-Notice" }),
  wallet.depositGate
)
Handlers.add(
  "wallet.depoist",
  { Action = "Credit-Notice", Sender = ao.env.Process.Owner },
  wallet.deposit
)

setup.setup()
