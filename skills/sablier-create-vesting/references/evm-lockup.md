# EVM Lockup Stream Creation

## Contract

All Lockup streams are created through a single contract: **`ISablierLockup`** (deployed as `SablierLockup`).

Look up the deployed address for your target chain at the [Lockup Deployments page](https://docs.sablier.com/guides/lockup/deployments). Do not hardcode addresses.

## Stream Types

EVM Lockup supports three stream shapes:

| Shape    | Code | When to Use                                                                    |
| -------- | ---- | ------------------------------------------------------------------------------ |
| Linear   | LL   | Continuous vesting with optional start unlock and optional cliff               |
| Dynamic  | LD   | Custom unlock curves (exponential/step-like) via segments with per-segment exponent |
| Tranched | LT   | Discrete unlock events at fixed dates (monthly, quarterly, milestone-based)    |

## Common Parameters

All EVM create functions rely on the same core stream metadata:

| Parameter       | Type      | Description                                               |
| --------------- | --------- | --------------------------------------------------------- |
| `sender`        | `address` | Cancel/renounce authority over the stream                 |
| `recipient`     | `address` | Receives the stream NFT and unlocked tokens               |
| `depositAmount` | `uint128` | Total token amount locked upfront (token base units)      |
| `token`         | `IERC20`  | ERC-20 token contract                                     |
| `cancelable`    | `bool`    | Whether sender can cancel the stream                      |
| `transferable`  | `bool`    | Whether the stream NFT can be transferred                 |
| `shape`         | `string`  | UI/indexer display label used by Sablier integrations     |

Express `depositAmount` in the token's smallest unit.

## Creation Fee

Include a creation fee of approximately **$1 USD** worth of the chain's native token with each stream creation.

- Send the fee as `msg.value` in the create transaction.
- All create functions are `payable`.
- For automation, convert USD to native token amount using a price source (for example, `coingecko-api`).

## Prerequisites

Before calling any create function:

1. **Approve the token transfer.** The Lockup contract pulls tokens from the caller. Call `token.approve(lockupAddress, depositAmount)` on the ERC-20 token contract first.
2. **Include the creation fee.** Send approximately $1 USD worth of the native token as `msg.value` with the create transaction.

## Shared Structs

### Lockup.CreateWithDurations

Used by all `createWithDurations*` functions:

```solidity
struct CreateWithDurations {
    address sender;       // Cancel/renounce authority
    address recipient;    // Receives the stream NFT
    uint128 depositAmount; // Total tokens (in token decimals)
    IERC20 token;         // ERC-20 token address
    bool cancelable;      // Whether sender can cancel
    bool transferable;    // Whether stream NFT is transferable
    string shape;         // Display label — see shape parameter section below
}
```

### Lockup.CreateWithTimestamps

Used by all `createWithTimestamps*` functions:

```solidity
struct CreateWithTimestamps {
    address sender;
    address recipient;
    uint128 depositAmount;
    IERC20 token;
    bool cancelable;
    bool transferable;
    Timestamps timestamps; // { uint40 start, uint40 end }
    string shape;
}
```

### Lockup.Timestamps

```solidity
struct Timestamps {
    uint40 start; // Unix timestamp when streaming begins
    uint40 end;   // Unix timestamp when all tokens are unlocked
}
```

## Linear (LL) Streams

### Type-Specific Structs

```solidity
// LockupLinear.UnlockAmounts
struct UnlockAmounts {
    uint128 start; // Tokens unlocked instantly at start_time
    uint128 cliff; // Tokens unlocked instantly at cliff_time
}

// LockupLinear.Durations
struct Durations {
    uint40 cliff; // Seconds from start to cliff (0 = no cliff)
    uint40 total; // Seconds from start to end
}
```

### Function Signatures

```solidity
function createWithDurationsLL(
    Lockup.CreateWithDurations calldata params,
    LockupLinear.UnlockAmounts calldata unlockAmounts,
    LockupLinear.Durations calldata durations
) external payable returns (uint256 streamId);

function createWithTimestampsLL(
    Lockup.CreateWithTimestamps calldata params,
    LockupLinear.UnlockAmounts calldata unlockAmounts,
    uint40 cliffTime // 0 = no cliff
) external payable returns (uint256 streamId);
```

### Validation Rules

- `depositAmount > 0`
- `startTime > 0` (timestamps variant; durations variant auto-sets to `block.timestamp`)
- `start < end` (timestamps) or `total > 0` (durations)
- If cliff is set: `start < cliff < end`
- If no cliff: `unlockAmounts.cliff` must be 0
- `unlockAmounts.start + unlockAmounts.cliff <= depositAmount`
- `durations.cliff < durations.total` (durations variant)

### Unlock Calculation

Tokens unlock in phases:

1. At `start`: `unlockAmounts.start` instantly available
2. At `cliff` (if set): `unlockAmounts.cliff` added
3. Between cliff/start and end: remaining tokens unlock linearly
4. At `end`: all tokens unlocked

## Dynamic (LD) Streams — EVM Only

### Type-Specific Structs

```solidity
// LockupDynamic.Segment
struct Segment {
    uint128 amount;    // Tokens unlocked in this segment
    UD2x18 exponent;   // Curve shape (fixed-point, 2 decimals)
    uint40 timestamp;  // Unix timestamp when segment ends
}

// LockupDynamic.SegmentWithDuration
struct SegmentWithDuration {
    uint128 amount;
    UD2x18 exponent;
    uint40 duration; // Seconds (first from start time, rest from previous segment end)
}
```

**Exponent values:**

- `1e18` (1.0): linear
- `< 1e18` (e.g., `0.5e18`): concave (fast start, slow finish)
- `> 1e18` (e.g., `2e18`): convex (slow start, fast finish)

Use the `ud2x18(value)` helper from PRBMath to construct exponent values.

### Function Signatures

```solidity
function createWithDurationsLD(
    Lockup.CreateWithDurations calldata params,
    LockupDynamic.SegmentWithDuration[] calldata segments
) external payable returns (uint256 streamId);

function createWithTimestampsLD(
    Lockup.CreateWithTimestamps calldata params,
    LockupDynamic.Segment[] calldata segments
) external payable returns (uint256 streamId);
```

### Validation Rules

- `depositAmount > 0`
- `startTime > 0` (timestamps variant; durations variant auto-sets to `block.timestamp`)
- At least one segment
- Segment timestamps strictly ascending
- Last segment timestamp = `timestamps.end`
- Sum of all segment amounts = `depositAmount`
- All exponents > 0

## Tranched (LT) Streams

### Type-Specific Structs

```solidity
// LockupTranched.Tranche
struct Tranche {
    uint128 amount;    // Tokens unlocked at this tranche
    uint40 timestamp;  // Unix timestamp when tranche unlocks
}

// LockupTranched.TrancheWithDuration
struct TrancheWithDuration {
    uint128 amount;
    uint40 duration; // Seconds (first from start time, rest from previous tranche)
}
```

### Function Signatures

```solidity
function createWithDurationsLT(
    Lockup.CreateWithDurations calldata params,
    LockupTranched.TrancheWithDuration[] calldata tranches
) external payable returns (uint256 streamId);

function createWithTimestampsLT(
    Lockup.CreateWithTimestamps calldata params,
    LockupTranched.Tranche[] calldata tranches
) external payable returns (uint256 streamId);
```

### Validation Rules

- `depositAmount > 0`
- `startTime > 0` (timestamps variant; durations variant auto-sets to `block.timestamp`)
- At least one tranche
- Tranche timestamps strictly ascending
- `start < first_tranche_timestamp`
- Sum of all tranche amounts = `depositAmount`
- All tranche amounts > 0

## Timestamps vs. Durations (EVM)

| Variant          | When to Use                    | Start Time                     |
| ---------------- | ------------------------------ | ------------------------------ |
| `WithTimestamps` | Known exact dates              | You specify `timestamps.start` |
| `WithDurations`  | Relative timing ("starts now") | Auto-set to `block.timestamp`  |

With durations, the contract calculates absolute timestamps by adding durations to `block.timestamp`. This means the stream starts immediately when the transaction is mined.

## The `shape` Parameter

The `shape` field is a string used by the Sablier UI and indexers to display stream information correctly. Use one of the values from the [SDK shape definitions](https://github.com/sablier-labs/sdk/blob/main/src/shapes/enums.ts):

- Linear (LL): `"linear"`, `"cliff"`, `"linearUnlockLinear"`, `"linearUnlockCliff"`, `"linearTimelock"`
- Dynamic (LD): `"dynamicExponential"`, `"dynamicCliffExponential"`, `"dynamicMonthly"`, `"dynamicStepper"`, `"dynamicTimelock"`, `"dynamicUnlockCliff"`, `"dynamicUnlockLinear"`, `"dynamicDoubleUnlock"`
- Tranched (LT): `"tranchedStepper"`, `"tranchedMonthly"`, `"tranchedBackweighted"`, `"tranchedTimelock"`
