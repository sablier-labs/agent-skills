# Batch Lockup Stream Creation

## EVM

`SablierLockup` inherits [`Batch`](https://github.com/sablier-labs/evm-utils/blob/main/src/Batch.sol), which exposes a `payable` `batch()` function that executes an array of encoded calls via `delegatecall`. This allows creating multiple streams — including mixed types (LL, LD, LT) — in a single transaction, with creation fees included.

```solidity
function batch(bytes[] calldata calls) external payable returns (bytes[] memory results);
```

### Prerequisites

1. **Approve tokens to the Lockup contract.** The batch call executes on `SablierLockup` itself (via `delegatecall`), so tokens are pulled from the caller by the Lockup contract — not a separate batch contract.
2. **Include the total creation fee.** Send `~$1 USD × number of streams` worth of native token as `msg.value`. Since `batch()` is `payable` and each sub-call sees the same `msg.value` via `delegatecall`, the total fee covers all streams.

### Approach

1. Encode each create call as calldata using `abi.encodeCall`.
2. Pass the array of encoded calls to `lockup.batch{ value: totalFee }(calls)`.

Each call can use any create function from [evm-lockup.md](evm-lockup.md) — you can mix LL, LD, and LT streams in the same batch.

### Example

```solidity
// Create an LL and an LT stream in a single transaction
bytes[] memory calls = new bytes[](2);
calls[0] = abi.encodeCall(lockup.createWithDurationsLL, (llParams, unlockAmounts, durations));
calls[1] = abi.encodeCall(lockup.createWithTimestampsLT, (ltParams, tranches));

// Fee: ~$1 per stream in native token
lockup.batch{ value: totalFee }(calls);
```


## Solana

On Solana, there is no separate batch program. To create multiple streams, include multiple create instructions in a single transaction, each with a **unique salt**.

### Approach

1. Build one create instruction per stream (e.g., `create_with_timestamps_ll`, `create_with_durations_lt`) using the parameters from [solana-lockup.md](solana-lockup.md).
2. Assign a unique `salt` (random `u128`) to each instruction — this ensures each stream gets a unique PDA.
3. Include a `SystemProgram.transfer` fee instruction per stream (~$1 USD in SOL to the treasury). See the main SKILL.md for treasury derivation details.
4. Combine all instructions into a single Solana transaction.

### Limits

Solana transactions are capped at **1232 bytes**. The number of streams per transaction depends on the instruction size, which varies by stream type and number of tranches. Test with small batches first.
