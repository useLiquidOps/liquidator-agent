# LiquidOps Liquidator Agent

## Setup

To get started, clone this repo and in the project folder, create an aos process, with a cron interval. This will be the interval in which liquidations will be checked by the agent. Remember, you cannot modify it after creating the process.

```sh
aos "My LiquidOps Liquidator" --cron 2-minutes
```

Load the agent with the following command:

```sh
.load process.lua
```

This will load in the agent and all the dependencies and begin the setup. If you need to change the protocol controller id (this is not recommended), change it before loading the liquidator agent:

```lua
Controller = "otherid"
```

## Getting the agent's balances

The following code prints out the agent's balance sheet:

```lua
Send({
  Target = ao.id, -- or if sending from another process, then the liquidator's id
  Action = "Balances"
})
```

## Depositing

You can transfer any token to your agent that is supported by the protocol. The agent will use these funds to liquidate users in your behalf. The recipient of the transfer should be the agent process id, which can be obtained with the following Lua code:

```lua
ao.id
```

## Withdrawing

You can withdraw tokens any time from the agent:

```lua
Send({
  Target = ao.id, -- or if sending from another process, then the liquidator's id
  Action = "Withdraw",
  Token = "tokenprocessid", -- the id of the withdrawn token's process
  Quantity = "15",
  Recipient = "your_address"
})
```

## Pausing and resuming the agent

You can pause or resume the liquidator. When resumed, it won't look for new opportunities to liquidate:

```lua
Send({
  Target = ao.id, -- or if sending from another process, then the liquidator's id
  Action = "Pause" -- or "Resume" 
})
```

You can also just update the global state in aos:

```lua
Paused = true -- or false
```
