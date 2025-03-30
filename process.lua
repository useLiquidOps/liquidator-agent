local setup = require "setup"

-- liquidops controller
Controller = "SmmMv0rJwfIDVM3RvY2-P729JFYwhdGSeGo2deynbfY"

---@alias Token { id: string; ticker: string; denomination: number; oToken: string; }
---@type Token[]
Tokens = Tokens or {}
MaxDiscount = 0
DiscountInterval = 0
Oracle = ""

-- setup can be called again if it didn't work
Handlers.add(
  "setup.setup",
  { Action = "Setup", From = ao.env.Process.Owner },
  setup.setup
)

setup.setup()
