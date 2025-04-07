# LiquidOps Liquidator Agent

> **Important**: This codebase has not been audited. LiquidOps and this agent is in Mainnet Beta, please use with caution and be aware of potential risks or limitations.

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

## Admin actions

### Getting the agent's balances

The following code prints out the agent's balance sheet:

```lua
Send({
  Target = ao.id, -- or if sending from another process, then the liquidator's id
  Action = "Balances"
})
```

### Depositing

You can transfer any token to your agent that is supported by the protocol. The agent will use these funds to liquidate users in your behalf. The recipient of the transfer should be the agent process id, which can be obtained with the following Lua code:

```lua
ao.id
```

### Withdrawing

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

### Pausing and resuming the agent

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

### Manually syncing the protocol

By default, the protocol info gets synced on every liquidation. You can trigger it manually:

```lua
Send({
  Target = ao.id,
  Action = "Sync-Protocol"
})
```

### Updating the config

The following message illustrates how the config updating works. It also explains the different configurations. Each can be omitted to avoid updating them:

```lua
Send({
  Target = ao.id,
  Action = "Set-Config",
  ["Focus-Mode"] = "single", -- or "mutliple"
  ["Add-Admin"] = "someaddress", -- process or wallet with authority over the agent (withdrawing, depositing, configuring)
  ["Remove-Admin"] = "admintoremove", -- an admin address to remove
  ["Add-Blacklisted-Token"] = "tokenaddr", -- a token to be blacklisted from liquidating to
  ["Remove-Blacklisted-Token"] = "tokenaddr", -- a token address to be removed from the blacklist
  Shuffle = "enabled", -- or "disabled", it shuffles liquidations for a better chance at liquidating
  Slippage = "1.5", -- slippage percentage to calculate the minimum expected tokens for a liquidation with
  Name = "New process name"
})
```

> Note: the agent process id and the process spawner can never be removed as admins.
