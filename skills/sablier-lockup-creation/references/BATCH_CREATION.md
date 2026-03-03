# Batch Lockup Stream Creation (EVM Only)

Batch stream creation is currently available on EVM only.

## Contract

Batch operations use a separate contract: **`ISablierBatchLockup`** (deployed as `SablierBatchLockup`).

Look up the deployed address at the
[Lockup Deployments page](https://docs.sablier.com/guides/lockup/deployments).

## Prerequisites

1. **Approve tokens to the BatchLockup contract** (not the Lockup contract). The batch contract handles the transfer.
2. **Include the creation fee.** Send approximately $1 USD worth of native token per stream as `msg.value`. See the main
   SKILL.md for details.

## Batch Create Functions

Each stream type has two batch variants (timestamps and durations):

### Linear (LL)

```solidity
function createWithDurationsLL(
    ISablierLockup lockup,
    IERC20 token,
    BatchLockup.CreateWithDurationsLL[] calldata batch
) external payable returns (uint256[] memory streamIds);

function createWithTimestampsLL(
    ISablierLockup lockup,
    IERC20 token,
    BatchLockup.CreateWithTimestampsLL[] calldata batch
) external payable returns (uint256[] memory streamIds);
```

### Dynamic (LD)

```solidity
function createWithDurationsLD(
    ISablierLockup lockup,
    IERC20 token,
    BatchLockup.CreateWithDurationsLD[] calldata batch
) external payable returns (uint256[] memory streamIds);

function createWithTimestampsLD(
    ISablierLockup lockup,
    IERC20 token,
    BatchLockup.CreateWithTimestampsLD[] calldata batch
) external payable returns (uint256[] memory streamIds);
```

### Tranched (LT)

```solidity
function createWithDurationsLT(
    ISablierLockup lockup,
    IERC20 token,
    BatchLockup.CreateWithDurationsLT[] calldata batch
) external payable returns (uint256[] memory streamIds);

function createWithTimestampsLT(
    ISablierLockup lockup,
    IERC20 token,
    BatchLockup.CreateWithTimestampsLT[] calldata batch
) external payable returns (uint256[] memory streamIds);
```

## Batch Struct Definitions

Each batch element wraps the per-stream parameters from the single-stream create functions (see
[EVM_LOCKUP.md](EVM_LOCKUP.md) for the base struct definitions).

```solidity
// Linear — durations variant
struct CreateWithDurationsLL {
    address sender;
    address recipient;
    uint128 depositAmount;
    bool cancelable;
    bool transferable;
    LockupLinear.Durations durations;
    LockupLinear.UnlockAmounts unlockAmounts;
    string shape;
}

// Linear — timestamps variant
struct CreateWithTimestampsLL {
    address sender;
    address recipient;
    uint128 depositAmount;
    bool cancelable;
    bool transferable;
    Lockup.Timestamps timestamps;
    uint40 cliffTime;
    LockupLinear.UnlockAmounts unlockAmounts;
    string shape;
}

// Dynamic — durations variant
struct CreateWithDurationsLD {
    address sender;
    address recipient;
    uint128 depositAmount;
    bool cancelable;
    bool transferable;
    LockupDynamic.SegmentWithDuration[] segmentsWithDuration;
    string shape;
}

// Dynamic — timestamps variant
struct CreateWithTimestampsLD {
    address sender;
    address recipient;
    uint128 depositAmount;
    bool cancelable;
    bool transferable;
    uint40 startTime;
    LockupDynamic.Segment[] segments;
    string shape;
}

// Tranched — durations variant
struct CreateWithDurationsLT {
    address sender;
    address recipient;
    uint128 depositAmount;
    bool cancelable;
    bool transferable;
    LockupTranched.TrancheWithDuration[] tranchesWithDuration;
    string shape;
}

// Tranched — timestamps variant
struct CreateWithTimestampsLT {
    address sender;
    address recipient;
    uint128 depositAmount;
    bool cancelable;
    bool transferable;
    uint40 startTime;
    LockupTranched.Tranche[] tranches;
    string shape;
}
```

**Note:** The `token` is passed as a top-level parameter to the batch function, not per-stream. For the full source, see
the [BatchLockup types](https://github.com/sablier-labs/lockup/blob/main/src/types/BatchLockup.sol).

## CSV Upload via Sablier UI

The Sablier web interface at [app.sablier.com](https://app.sablier.com) supports bulk stream creation via CSV upload.

### Capabilities

- Create up to **280 streams** in a single batch
- Downloadable CSV templates available in the UI
- Supports all three stream types (LL, LD, LT)

### Workflow

1. Navigate to the stream creation page on [app.sablier.com](https://app.sablier.com)
2. Select "CSV Upload" as the creation method
3. Download the template for your chosen stream type
4. Fill in recipient addresses, amounts, and schedule parameters
5. Upload the completed CSV
6. Review the preview and confirm the transaction

### CSV Format Notes

- Amounts should be in human-readable format (e.g., `1000` not `1000000000000000000`)
- Addresses must be valid checksummed Ethereum addresses
- Timestamps use Unix epoch format
- Download the latest template from the UI to ensure compatibility with the current version

## Limits

- **UI batch**: up to 280 streams per transaction
- **On-chain batch**: limited by block gas limit (varies by chain)
- **Practical recommendation**: test with small batches first, then scale up
