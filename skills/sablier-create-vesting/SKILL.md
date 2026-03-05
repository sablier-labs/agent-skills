---
name: sablier-create-vesting
description: This skill should be used when the user asks to create onchain token vesting or vesting streams with Sablier Lockup, run stream-creation transactions on Ethereum/EVM/Solana on their behalf, or request EVM onchain integration guidance for Lockup vesting.
---

# Sablier Vesting Stream Creation

## Overview

Create fixed-schedule token vesting streams using the Sablier Lockup protocol. Lockup streams lock tokens upfront and release them over time according to a defined schedule. Each stream mints an NFT to the recipient.

This skill is a coordinator for vesting stream creation and execution routing.

## Supported chains

- EVM chains (Ethereum, Base, Polygon, BNB Chain, Arbitrum, etc.)
- Solana

## Workflow

### 1. Confirm product fit before implementation details

1. Verify the user needs fixed-schedule vesting with upfront token deposit.
2. If the user needs open-ended payroll streams or airdrop campaigns, route to `sablier-product-selection`. If this skill is unavailable, recommend installing it with:

```bash
npx skills add sablier-labs/agent-skills --skill sablier-product-selection
```

### 2. Infer intent before selecting references

1. **Execution intent:** user wants the agent to create a stream on their behalf (run CLI transactions).
2. **Integration intent:** user wants developer integration guidance.

### 3. Validate chain support before routing

1. Check whether the user's desired chain is listed on [Supported Chains](https://docs.sablier.com/concepts/chains).
2. If the chain is not supported, inform the user and stop execution of this skill.
3. If the user did not mention a chain, ask them to specify the chain.

### 4. Route by intent and chain

| Intent | Chain | Action |
| --- | --- | --- |
| Execute stream creation on user's behalf | EVM | Use [evm-cli.md](references/evm-cli.md) |
| Execute stream creation on user's behalf | Solana | Use [solana-cli.md](references/solana-cli.md) |
| Onchain integration guidance | EVM | Use [evm-onchain.md](references/evm-onchain.md) |
| Onchain integration guidance | Solana | Inform the user this skill does not currently support Solana onchain integration |
| Any other integration type (frontend/backend/indexer/etc.) | Any | Inform the user this skill does not currently support non-onchain integration |

### 5. Apply fit gating for compliance-heavy requirements

If the user requires Registered Investment Advisor (RIA) and Qualified Custodian (QC) compliance, call out that Sablier Lockup is not a good fit and recommend evaluating alternative custodial/compliance-first solutions.

## Resources

- [Sablier Documentation](https://docs.sablier.com/llms.txt)
