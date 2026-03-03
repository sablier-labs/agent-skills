# Lockup Stream Type Guide

For help choosing between Sablier products (Lockup vs. Flow vs. Airdrops), see the `sablier-product-selection` skill.
This page covers only the Lockup stream types: LL, LD, and LT.

## Lockup Type Summary

### Linear (LL)

- Simplest to configure — just start, end, optional start unlock, and optional cliff
- Tokens unlock at a constant rate between cliff (or start) and end
- Optional instant unlock at stream start (`start_unlock_amount`) and at cliff (`cliff_unlock_amount`)
- Best for: standard vesting, fixed-schedule payroll, linear unlock schedules
- Available on EVM and Solana

### Dynamic (LD) — EVM Only

- Most flexible — compose any curve from segments
- Each segment has an exponent controlling the curve shape:
  - Exponent = 1: linear (same as LL within that segment)
  - Exponent < 1: concave (fast start, slow finish)
  - Exponent > 1: convex (slow start, fast finish)
- Best for: custom unlock curves, exponential vesting, complex multi-phase schedules

### Tranched (LT)

- Discrete unlocks — tokens unlock in fixed amounts at specific timestamps
- No streaming between tranches (step function)
- Best for: quarterly unlocks, monthly unlocks, milestone-based vesting, periodic payroll
- Max 30 tranches on Solana, gas-bounded on EVM
- Available on EVM and Solana

## Common Configurations

### 4-Year Vesting with 1-Year Cliff (LL)

Standard startup vesting. Use Linear with:

- Start: grant date
- Cliff: 1 year after start (25% unlocks at cliff)
- End: 4 years after start
- `start_unlock_amount`: 0
- `cliff_unlock_amount`: 25% of total

### Quarterly Unlocks Over 2 Years (LT)

Use Tranched with 8 tranches, each unlocking 12.5% of total:

- 8 tranches, each with `amount = total / 8`
- Timestamps spaced 3 months apart

### Continuous Payroll on Solana (LL)

Use Linear with:

- Start: employment start date
- End: contract end date (or a far-future date for indefinite arrangements)
- `cliff_time`: 0 (no cliff)
- `start_unlock_amount`: 0
- `cliff_unlock_amount`: 0
