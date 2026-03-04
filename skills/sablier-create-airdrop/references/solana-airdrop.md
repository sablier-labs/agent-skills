# Solana Merkle Airdrop Creation

## Program

The Sablier Merkle Instant program on Solana supports **instant airdrops only**. Vested airdrops (MerkleLL, MerkleLT, MerkleVCA) are not available on Solana.

Look up the deployed program ID at the [Solana Deployment Addresses](https://docs.sablier.com/solana/deployment-addresses) page. Do not hardcode the address.

## Prerequisites

1. **Generate the Merkle tree and upload to IPFS.** Use the [Merkle API](https://github.com/sablier-labs/merkle-api) — it returns the `merkle_root` and `ipfs_cid` needed for the create instruction. See [merkle-tree.md](merkle-tree.md) for details.
2. **Ensure sufficient SOL.** The creator pays rent-exemption costs for the campaign PDA and its ATA.

## PDA Derivation

### Campaign

```
seeds = [b"campaign", creator_pubkey, merkle_root, start_time_le_bytes, expiration_time_le_bytes, name_bytes, airdrop_token_mint]
```

### Treasury

```
seeds = [b"treasury"]
program_id = <Merkle Instant program ID from deployment-addresses page>
```

## create_campaign Instruction

**Accounts:**

| Account                    | Type            | Description                          |
| -------------------------- | --------------- | ------------------------------------ |
| `creator`                  | Signer, mutable | Campaign creator, pays rent          |
| `airdrop_token_mint`       | Read-only       | SPL Token mint being distributed     |
| `campaign`                 | Init            | Campaign PDA (see derivation above)  |
| `campaign_ata`             | Init            | Campaign's ATA for the airdrop token |
| `airdrop_token_program`    | Program         | Token Program (SPL or Token-2022)    |
| `associated_token_program` | Program         | Associated Token Program             |
| `system_program`           | Program         | System Program                       |

**Parameters:**

| Parameter             | Type       | Description                                  |
| --------------------- | ---------- | -------------------------------------------- |
| `merkle_root`         | `[u8; 32]` | Root hash of the Merkle tree                 |
| `campaign_start_time` | `u64`      | Unix timestamp when claiming opens           |
| `expiration_time`     | `u64`      | Unix timestamp when campaign expires         |
| `name`                | `String`   | Campaign name (max 32 bytes)                 |
| `ipfs_cid`            | `String`   | IPFS CID for Merkle tree data (max 59 bytes) |
| `aggregate_amount`    | `u64`      | Total tokens to distribute                   |
| `recipient_count`     | `u32`      | Number of eligible recipients                |

### Validation Rules

- `name` must be ≤ 32 bytes
- `ipfs_cid` must be ≤ 59 bytes
- `campaign_start_time > 0`
- If `expiration_time > 0`: `expiration_time > campaign_start_time`

**Note:** The default compute unit limit (200k) is insufficient for this instruction. Include a `ComputeBudgetProgram.setComputeUnitLimit` pre-instruction with a higher limit (e.g., 1,000,000 CU).

After creating the campaign, transfer the `aggregate_amount` of tokens to the campaign's ATA to fund it.
