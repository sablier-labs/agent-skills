# Solana Lockup Stream Creation

## Program

The Sablier Lockup program on Solana supports Linear (LL) and Tranched (LT) streams. Dynamic (LD) streams are not available on Solana.

Look up the deployed program ID at the [Solana Deployments page](https://docs.sablier.com/solana/deployment-addresses). Do not hardcode the address.

## Prerequisites

Before calling any create instruction:

1. **Fund the funder's ATA.** The funder must have an Associated Token Account (ATA) for the deposit token with sufficient balance.
2. **Include the creation fee.** Send approximately $1 USD worth of SOL to the Sablier treasury in the same transaction. See the main SKILL.md for details on treasury address verification.

## Required Accounts (All Instructions)

Every create instruction requires the same set of accounts:

| Account                    | Type            | Description                                                                      |
| -------------------------- | --------------- | -------------------------------------------------------------------------------- |
| `funder`                   | Signer, mutable | Pays rent and provides tokens                                                    |
| `funder_ata`               | Mutable         | Funder's ATA for the deposit token                                               |
| `recipient`                | Read-only       | Receives the stream NFT                                                          |
| `sender`                   | Read-only       | Has cancel authority (can differ from funder)                                    |
| `treasury`                 | Read-only       | Sablier Treasury PDA — derive from Lockup program ID + seeds `[b"treasury"]`     |
| `stream_nft_collection`    | Mutable         | Stream NFT collection PDA, seeds: `[b"stream_nft_collection"]`                   |
| `deposit_token_mint`       | Read-only       | SPL Token mint for the deposited token                                           |
| `stream_data`              | Init            | PDA storing stream state, seeds: `[b"stream_data", stream_nft.key()]`            |
| `stream_data_ata`          | Init            | ATA for deposit tokens owned by `stream_data`                                    |
| `stream_nft`               | Init            | MPL Core asset (NFT), seeds: `[b"stream_nft", sender.key(), salt.to_le_bytes()]` |
| `associated_token_program` | Program         | Associated Token Program                                                         |
| `deposit_token_program`    | Program         | Token Program or Token-2022                                                      |
| `mpl_core_program`         | Program         | Metaplex Core Program                                                            |
| `system_program`           | Program         | System Program                                                                   |

## PDA Derivation

### Stream NFT

```
seeds = [b"stream_nft", sender_pubkey, salt_le_bytes]
```

The `salt` is a `u128` value serialized as little-endian bytes. Each `(sender, salt)` pair produces a unique stream NFT address. Callers must use a unique salt for each stream created by the same sender. Use a random `u128` (e.g., 16 random bytes interpreted as a little-endian integer) to avoid collisions with previously created streams.

### Stream Data

```
seeds = [b"stream_data", stream_nft_pubkey]
```

Derived from the stream NFT address.

### Treasury

```
seeds = [b"treasury"]
program_id = <Lockup program ID from deployment-addresses page>
```

Derive using `findProgramAddress([Buffer.from("treasury")], lockupProgramId)`. The Lockup program ID is listed at the [Solana Deployment Addresses](https://docs.sablier.com/solana/deployment-addresses) page.

## Linear (LL) Streams

### create_with_timestamps_ll

Create a linear stream with absolute Unix timestamps.

**Instruction parameters:**

| Parameter             | Type   | Description                               |
| --------------------- | ------ | ----------------------------------------- |
| `salt`                | `u128` | Unique nonce for PDA derivation           |
| `deposit_amount`      | `u64`  | Total tokens (in token decimals)          |
| `start_time`          | `u64`  | Unix timestamp when streaming begins      |
| `cliff_time`          | `u64`  | Unix timestamp for cliff (0 = no cliff)   |
| `end_time`            | `u64`  | Unix timestamp when all tokens unlock     |
| `start_unlock_amount` | `u64`  | Tokens unlocked instantly at `start_time` |
| `cliff_unlock_amount` | `u64`  | Tokens unlocked instantly at `cliff_time` |
| `is_cancelable`       | `bool` | Whether sender can cancel the stream      |

### create_with_durations_ll

Create a linear stream with relative durations. Timestamps are calculated from the current block time.

**Instruction parameters:**

| Parameter             | Type   | Description                                |
| --------------------- | ------ | ------------------------------------------ |
| `salt`                | `u128` | Unique nonce for PDA derivation            |
| `deposit_amount`      | `u64`  | Total tokens (in token decimals)           |
| `cliff_duration`      | `u64`  | Seconds from start to cliff (0 = no cliff) |
| `total_duration`      | `u64`  | Seconds from start to end                  |
| `start_unlock_amount` | `u64`  | Tokens unlocked instantly at start         |
| `cliff_unlock_amount` | `u64`  | Tokens unlocked instantly at cliff         |
| `is_cancelable`       | `bool` | Whether sender can cancel the stream       |

### Validation Rules

- `deposit_amount > 0`
- `start_time > 0` (timestamps variant)
- `start_time < end_time`
- If `cliff_time > 0`: `start_time < cliff_time < end_time`
- If `cliff_time == 0`: `cliff_unlock_amount` must be 0
- `start_unlock_amount + cliff_unlock_amount <= deposit_amount`
- Durations variant: `total_duration > 0`, `cliff_duration < total_duration`

### Unlock Calculation

Same as EVM:

1. Before `start_time`: 0 tokens
2. At `start_time`: `start_unlock_amount` available
3. At `cliff_time` (if set): `cliff_unlock_amount` added
4. Between cliff/start and end: linear interpolation of remaining tokens
5. At `end_time`: all tokens unlocked

## Tranched (LT) Streams

### create_with_timestamps_lt

Create a tranched stream with absolute Unix timestamps.

**Instruction parameters:**

| Parameter       | Type           | Description                                |
| --------------- | -------------- | ------------------------------------------ |
| `salt`          | `u128`         | Unique nonce for PDA derivation            |
| `start_time`    | `u64`          | Unix timestamp before first tranche        |
| `tranches`      | `Vec<Tranche>` | Array of `{ amount: u64, timestamp: u64 }` |
| `is_cancelable` | `bool`         | Whether sender can cancel the stream       |

The `deposit_amount` is the sum of all tranche amounts (calculated by the program).

### create_with_durations_lt

Create a tranched stream with relative durations.

**Instruction parameters:**

| Parameter           | Type       | Description                                                             |
| ------------------- | ---------- | ----------------------------------------------------------------------- |
| `salt`              | `u128`     | Unique nonce for PDA derivation                                         |
| `tranche_amounts`   | `Vec<u64>` | Token amounts for each tranche                                          |
| `tranche_durations` | `Vec<u64>` | Duration in seconds (first from start time, rest from previous tranche) |
| `is_cancelable`     | `bool`     | Whether sender can cancel the stream                                    |

`tranche_amounts` and `tranche_durations` must have the same length.

### Validation Rules

- At least one tranche
- Maximum **30 tranches** per stream
- `start_time > 0` (timestamps variant)
- `start_time < first tranche timestamp`
- Tranche timestamps strictly ascending
- All tranche amounts > 0
- Sum of tranche amounts = deposit amount

### Unlock Calculation

```
streamed = sum of all tranche.amount where tranche.timestamp <= current_time
```

Tokens unlock in discrete steps — nothing streams between tranches.

## Stream NFT

Each stream mints an MPL Core asset (NFT) owned by the recipient. The NFT name follows the format:

```
"Sablier [LL|LT] Stream #[first 5 chars of stream_nft key]...[last 5 chars of stream_nft key]"
```
