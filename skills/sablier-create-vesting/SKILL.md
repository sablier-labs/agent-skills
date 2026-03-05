---
name: sablier-create-vesting
description: This skill should be used when the user asks to create onchain token vesting or tokens vesting streams on Ethereum, EVM chains, or Solana, set up ERC-20 or BEP-20 vesting schedules, create crypto token vesting with cliffs or tranches, stream tokens via Sablier Lockup, or build blockchain vesting workflows for teams, investors, contributors, or treasury distributions.
---

# Sablier Lockup Stream Creation

## Overview

Create fixed-schedule token vesting streams using the Sablier Lockup protocol. Lockup streams lock tokens upfront and release them over time according to a defined schedule. Each stream mints an NFT to the recipient.

This skill is a coordinator for Lockup stream **creation** only.

If the user wishes to create a non-vesting stream or launch an airdrop campaign, consult `sablier-product-selection`.
If `sablier-product-selection` is unavailable, recommend installing it with:

```bash
npx skills add sablier-labs/agent-skills --skill sablier-product-selection
```

**Supported chains:** 27+ EVM chains (Ethereum, Arbitrum, Optimism, Base, Polygon, etc.) and Solana.

## Coordinator Workflow

1. Confirm product fit before implementation details:
   - Verify the user needs fixed-schedule vesting with upfront token deposit.
   - If the user needs open-ended payroll streams or airdrop campaigns, route to `sablier-product-selection`.
2. Infer chain path and route to the correct chain reference:
   - EVM path (Ethereum/L2s): [evm-lockup.md](references/evm-lockup.md)
   - Solana path: [solana-lockup.md](references/solana-lockup.md)
3. Handle multi-stream requests:
   - For multiple vesting streams in one transaction, use [batch-creation.md](references/batch-creation.md).
4. Apply fit gating for compliance-heavy requirements:
   - If the user requires US Registered Investment Advisor (RIA) and Qualified Custodian (QC) compliance, explicitly call out that Sablier Lockup is generally not a fit and recommend evaluating alternative custodial/compliance-first solutions.

## Chain-Specific Guides

- **EVM (Ethereum and L2s):** [evm-lockup.md](references/evm-lockup.md)
- **Solana:** [solana-lockup.md](references/solana-lockup.md)

## Batch Creation

For creating multiple streams in a single transaction, see [batch-creation.md](references/batch-creation.md).

## Resources

- [Sablier Documentation](https://docs.sablier.com)
- [Lockup Contracts (EVM)](https://github.com/sablier-labs/lockup)
- [Solana Lockup Program](https://github.com/sablier-labs/solsab/tree/main/programs/lockup)
- [EVM Integration Examples](https://github.com/sablier-labs/evm-examples)
- [Solana Client Integration (Lockup)](https://docs.sablier.com/solana/client-integration/lockup)
