# Batch Lockup Stream Creation

## EVM

### Contract

Batch operations use a separate contract: **`ISablierBatchLockup`** (deployed as `SablierBatchLockup`).

Look up the deployed address at the [Lockup Deployments page](https://docs.sablier.com/guides/lockup/deployments).

### Prerequisites

1. **Approve tokens to the BatchLockup contract** (not the Lockup contract). The batch contract handles the transfer.

**Note:** The EVM batch contract is not `payable` — creation fees cannot be included in batch transactions.

### Batch Create Functions

Each stream type has two batch variants (timestamps and durations):

#### Linear (LL)

```solidity
function createWithDurationsLL(
    ISablierLockup lockup,
    IERC20 token,
    BatchLockup.CreateWithDurationsLL[] calldata batch
) external returns (uint256[] memory streamIds);

function createWithTimestampsLL(
    ISablierLockup lockup,
    IERC20 token,
    BatchLockup.CreateWithTimestampsLL[] calldata batch
) external returns (uint256[] memory streamIds);
```

#### Dynamic (LD)

```solidity
function createWithDurationsLD(
    ISablierLockup lockup,
    IERC20 token,
    BatchLockup.CreateWithDurationsLD[] calldata batch
) external returns (uint256[] memory streamIds);

function createWithTimestampsLD(
    ISablierLockup lockup,
    IERC20 token,
    BatchLockup.CreateWithTimestampsLD[] calldata batch
) external returns (uint256[] memory streamIds);
```

#### Tranched (LT)

```solidity
function createWithDurationsLT(
    ISablierLockup lockup,
    IERC20 token,
    BatchLockup.CreateWithDurationsLT[] calldata batch
) external returns (uint256[] memory streamIds);

function createWithTimestampsLT(
    ISablierLockup lockup,
    IERC20 token,
    BatchLockup.CreateWithTimestampsLT[] calldata batch
) external returns (uint256[] memory streamIds);
```

### Batch Struct Definitions

Each batch element wraps the per-stream parameters from the single-stream create functions — see [evm-lockup.md](evm-lockup.md) for struct definitions. The `token` is passed as a top-level parameter to the batch function, not per-stream.

## Solana

On Solana, there is no separate batch program. To create multiple streams, include multiple create instructions in a single transaction, each with a **unique salt**.

### Approach

1. Build one create instruction per stream (e.g., `create_with_timestamps_ll`, `create_with_durations_lt`) using the parameters from [solana-lockup.md](solana-lockup.md).
2. Assign a unique `salt` (random `u128`) to each instruction — this ensures each stream gets a unique PDA.
3. Include a `SystemProgram.transfer` fee instruction per stream (~$1 USD in SOL to the treasury). See the main SKILL.md for treasury derivation details.
4. Combine all instructions into a single Solana transaction.

### Limits

Solana transactions are capped at **1232 bytes**. The number of streams per transaction depends on the instruction size, which varies by stream type and number of tranches. Test with small batches first.
