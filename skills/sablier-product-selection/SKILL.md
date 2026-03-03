---
name: sablier-product-selection
description: This skill should be used when the user asks "which Sablier product should I use", "how do I distribute tokens", "should I use Lockup or Flow", "what type of vesting stream", "linear vs tranched vs dynamic", "best way to do token vesting", "how to set up payroll streaming", or needs help choosing between Sablier Lockup, Flow, and Airdrops for their token distribution use case.
---

# Sablier Product Selection

## Overview

Sablier offers three products for onchain token distribution. This skill helps choose the right one for a given use
case, then routes to the appropriate creation skill.

| Product      | Purpose                                                    | Chains       |
| ------------ | ---------------------------------------------------------- | ------------ |
| **Lockup**   | Vesting with a fixed schedule — tokens locked upfront      | EVM + Solana |
| **Flow**     | Open-ended streaming — adjustable rate, no upfront deposit | EVM only     |
| **Airdrops** | Merkle-tree distribution to many recipients                | EVM + Solana |

**Creation skills:**

- Lockup streams (LL, LD, LT) → `sablier-lockup-creation`
- Flow streams → `sablier-flow-creation`
- Merkle Airdrops → `sablier-airdrop-creation`

## Decision Tree

Follow this tree from top to bottom. Each question narrows down the recommended product and chain.

```
Q1: What kind of token distribution do you need?
├─ Vesting (fixed schedule, tokens locked upfront) ──► Q2
├─ Airdrop (distribute to many recipients) ──► see `sablier-airdrop-creation` skill
└─ Payroll / ongoing payments ──► Q6

Q2: Do you need a custom unlock curve (exponential, logarithmic, etc.)?
├─ Yes ──► Q3
└─ No ──► Q5

Q3: Must you use Solana?
├─ Yes ──► Q4
└─ No ──► ✅ LD (Dynamic) on EVM — see `sablier-lockup-creation`

Q4: Can the curve be approximated with discrete unlock steps?
├─ Yes ──► ✅ LT (Tranched) on Solana — see `sablier-lockup-creation`
└─ No ──► ✅ LL (Linear) on Solana — see `sablier-lockup-creation`

Q5: Do tokens unlock continuously or at discrete intervals?
├─ Continuously (with optional cliff and/or start unlock) ──► ✅ LL (Linear) on EVM or Solana
│  see `sablier-lockup-creation`
└─ At discrete intervals (monthly, quarterly, milestones) ──► ✅ LT (Tranched) on EVM or Solana
   see `sablier-lockup-creation`

Q6: Must you use Solana?
├─ Yes ──► Q10
└─ No ──► Q7

Q7: Is the payment open-ended (no fixed end date)?
├─ Yes ──► ✅ Flow on EVM — see `sablier-flow-creation`
└─ No ──► Q8

Q8: Do you need to adjust the payment rate over time?
├─ Yes ──► ✅ Flow on EVM — see `sablier-flow-creation`
└─ No ──► Q9

Q9: Do you want periodic payouts (e.g., monthly salary tranches)?
├─ Yes ──► ✅ LT (Tranched) on EVM — see `sablier-lockup-creation`
└─ No (continuous streaming) ──► ✅ Flow on EVM — see `sablier-flow-creation`

Q10: Do you want periodic payouts (e.g., monthly salary tranches)?
├─ Yes ──► ✅ LT (Tranched) on Solana — see `sablier-lockup-creation`
└─ No (continuous streaming) ──► ✅ LL (Linear) on Solana — see `sablier-lockup-creation`
```

## Quick Reference

| Use Case                      | Recommended | Chain        | Creation Skill             |
| ----------------------------- | ----------- | ------------ | -------------------------- |
| Vesting with cliff            | LL          | EVM + Solana | `sablier-lockup-creation`  |
| Simple linear vesting         | LL          | EVM + Solana | `sablier-lockup-creation`  |
| Quarterly/monthly unlocks     | LT          | EVM + Solana | `sablier-lockup-creation`  |
| Milestone-based unlocks       | LT          | EVM + Solana | `sablier-lockup-creation`  |
| Custom unlock curve           | LD          | EVM only     | `sablier-lockup-creation`  |
| Open-ended payroll            | Flow        | EVM only     | `sablier-flow-creation`    |
| Adjustable-rate payroll       | Flow        | EVM only     | `sablier-flow-creation`    |
| Continuous payroll (EVM)      | Flow        | EVM only     | `sablier-flow-creation`    |
| Payroll with monthly tranches | LT          | EVM + Solana | `sablier-lockup-creation`  |
| Continuous payroll (Solana)   | LL          | Solana       | `sablier-lockup-creation`  |
| Airdrop to many recipients    | Merkle      | EVM + Solana | `sablier-airdrop-creation` |

## Product Comparison

### Lockup — Vesting Streams

Tokens are locked upfront and released over time according to a fixed schedule. Three stream shapes:

- **Linear (LL)** — Constant unlock rate with optional start unlock and cliff. EVM + Solana.
- **Dynamic (LD)** — Custom curve via configurable segments with exponents. EVM only.
- **Tranched (LT)** — Discrete unlocks at specific timestamps. EVM + Solana.

All Lockup positions are represented as NFTs (ERC-721 on EVM, MPL Core on Solana).

### Flow — Payment Streams

Open-ended streaming with no fixed end date. Key features:

- Adjustable rate in real time without recreating the stream
- Pause and resume support
- No upfront deposit required — sender tops up as needed
- EVM only

### Airdrops — Merkle Distribution

Merkle-tree based distribution for large recipient sets:

- Gas-optimized claiming — recipients pay their own claim gas
- Optional vesting — tokens can stream after claim
- Clawback support for unclaimed allocations
- EVM + Solana
