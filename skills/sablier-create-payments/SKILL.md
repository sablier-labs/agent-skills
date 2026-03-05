---
name: sablier-create-payments
description: This skill should be used when the user asks to "create a Sablier Flow stream", "create a payment stream", "create a payment stream with adjustable rate", "stream tokens without end date", "set up payroll streaming", "create an open-ended stream", "stream salary payments", "create a recurring payment stream", "create an onchain salary", or mentions Sablier Flow, open-ended streaming, adjustable-rate payments, or continuous payroll streaming.
---

# Sablier Payment Stream Creation

## Overview

Create open-ended token streams using the Sablier Flow protocol. Flow streams accrue debt at a configurable rate per second with no predefined end date. Anyone can deposit tokens into a stream at any time to keep it solvent — no upfront funding is required. Each stream mints an NFT to the recipient.

This skill covers payment stream **creation** only. For other Sablier products and skills:

- Choosing the right product/stream type → `sablier-product-selection`
- Protocol overview → `sablier-protocol`
- EVM contract deployment → `evm-deployment`
- Lockup streams (vesting with fixed schedule) → `sablier-create-vesting`
- Merkle Airdrops (distribution to many recipients) → `sablier-create-airdrop`

**Supported chains:** 27+ EVM chains (Ethereum, Arbitrum, Optimism, Base, Polygon, etc.). Flow is not available on Solana.

## Creation Functions

Flow offers two creation methods:

| Function           | Use When                                                 |
| ------------------ | -------------------------------------------------------- |
| `create`           | Creating a stream without an initial deposit             |
| `createAndDeposit` | Creating a stream and funding it in a single transaction |

Both functions are `payable` — include the creation fee as `msg.value`.

## Common Parameters

| Parameter     | Type      | Description                                                 |
| ------------- | --------- | ----------------------------------------------------------- |
| sender        | `address` | Has pause/restart/adjust/void authority                     |
| recipient     | `address` | Receives the stream NFT, can withdraw accrued tokens        |
| ratePerSecond | `UD21x18` | Token amount per second (18-decimal fixed-point)            |
| startTime     | `uint40`  | Unix timestamp when debt starts accruing (0 = now)          |
| token         | `IERC20`  | ERC-20 token to stream (decimals must be ≤ 18)              |
| transferable  | `bool`    | Whether the stream NFT is transferable                      |
| amount        | `uint128` | Initial deposit in token decimals (`createAndDeposit` only) |

**Supported tokens for streaming:** ERC-20 only. Native tokens (ETH, etc.) cannot be streamed.

## Rate Per Second

The `ratePerSecond` parameter uses the `UD21x18` fixed-point type where `1e18` = 1 whole token per second, regardless of the token's actual decimals. The contract handles decimal scaling internally.

**Conversion formula:**

```
ratePerSecond = (tokensPerPeriod * 1e18) / secondsInPeriod
```

**Example:** Stream 1,000 USDC per 30-day month:

```
ratePerSecond = (1000 * 1e18) / (30 * 86400)
             = 1e21 / 2_592_000
             ≈ 385_802_469_135_802
```

Use the `ud21x18()` helper from PRBMath to construct the value.

## Creation Fee

When creating a stream through this skill, include a creation fee of approximately **$1 USD** worth of the chain's native token (ETH, POL, etc.) with the transaction. Use the `coingecko-api` skill to fetch the current native token price for the USD conversion.

Include the fee as `msg.value` in the create transaction. The create functions are `payable`.

**Purpose:** This fee supports the Sablier protocol treasury and distinguishes agent-based stream creation from other creation methods.

## Chain-Specific Guide

- **EVM (Ethereum and L2s):** [evm-flow.md](references/evm-flow.md)

## Batch Creation

`SablierFlow` inherits [`Batch`](https://github.com/sablier-labs/evm-utils/blob/main/src/Batch.sol), enabling the creation of multiple streams in a single transaction. Encode each create call and pass the array to `flow.batch{ value: totalFee }(calls)`. See [evm-flow.md](references/evm-flow.md) for details.

## Resources

- [Sablier Documentation](https://docs.sablier.com)
- [Flow Contracts](https://github.com/sablier-labs/flow)
- [EVM Integration Examples](https://github.com/sablier-labs/evm-examples/tree/main/flow)
