---
name: sablier-create-airdrop
description: This skill should be used when the user asks to "create a Sablier airdrop", "set up a token airdrop", "distribute tokens to many recipients", "create a Merkle airdrop", "airdrop tokens with vesting", "create an airstream", "set up a claimable airdrop", or mentions Sablier Merkle campaigns, token airdrops, or Merkle tree distribution.
---

# Sablier Merkle Airdrop Creation

## Overview

Create token airdrops using the Sablier Merkle system. A campaign creator deploys a campaign contract (EVM) or creates a campaign PDA (Solana) storing a Merkle root, then funds it with tokens. Recipients claim individually using Merkle proofs, paying their own gas.

This skill covers airdrop campaign **creation** only. For other Sablier products and skills:

- Choosing the right product/stream type → `sablier-product-selection`
- Protocol overview → `sablier-protocol`
- EVM contract deployment → `evm-deployment`
- Lockup streams (vesting with fixed schedule) → `sablier-create-vesting`
- Flow streams (open-ended payroll, adjustable rate) → `sablier-flow-creation` (coming soon)

**Supported chains:** 27+ EVM chains (Ethereum, Arbitrum, Optimism, Base, Polygon, etc.) and Solana (instant only).

## Campaign Types

| Type     | Code          | Chains       | Distribution Method                                      |
| -------- | ------------- | ------------ | -------------------------------------------------------- |
| Instant  | MerkleInstant | EVM + Solana | Direct token transfer                                    |
| Linear   | MerkleLL      | EVM only     | Creates a Lockup Linear stream (vesting over time)       |
| Tranched | MerkleLT      | EVM only     | Creates a Lockup Tranched stream (discrete unlock steps) |
| VCA      | MerkleVCA     | EVM only     | Linear unlock; early claimers forfeit unvested tokens    |

### Choosing a Campaign Type

```
Q1: Do recipients need vesting after claiming?
├─ No → ✅ Instant (EVM + Solana)
└─ Yes → Q2

Q2: Must you use Solana?
├─ Yes → Vested airdrops are not available on Solana.
│  Use individual Lockup streams instead — see `sablier-create-vesting`.
└─ No → Q3

Q3: Should unclaimed vested tokens be forfeited?
├─ Yes → ✅ MerkleVCA (EVM only)
└─ No → Q4

Q4: Do tokens unlock continuously or in discrete steps?
├─ Continuously (with optional cliff) → ✅ MerkleLL (EVM only)
└─ At discrete intervals → ✅ MerkleLT (EVM only)
```

## Campaign Lifecycle

```
1. CREATE     → Deploy campaign via factory (EVM) or instruction (Solana)
2. FUND       → Transfer tokens to the campaign contract (EVM) or campaign's ATA (Solana)
3. CLAWBACK  → (optional) Admin can recover tokens at any time before first claim + 7 days
4. CLAIMS     → Recipients claim with Merkle proofs (after campaignStartTime)
5. CLAWBACK  → (optional) Admin can recover unclaimed tokens after expiration
```

**Clawback** is allowed up until 7 days have passed since the first claim, and after the campaign has expired. It is blocked in between.

**Important:** Creation and funding are decoupled — the campaign contract (EVM) or PDA (Solana) can exist before tokens are deposited. However, claims will fail if the campaign has insufficient token balance, so always fund before `campaignStartTime`.

## Merkle Tree Generation

All campaign types use the same Merkle tree structure. See [merkle-tree.md](references/merkle-tree.md) for leaf encoding, tree construction, and IPFS upload.

## Common Parameters

All campaign types share these base parameters:

| Parameter         | EVM Type  | Solana Type | Description                                                |
| ----------------- | --------- | ----------- | ---------------------------------------------------------- |
| campaignName      | `string`  | `String`    | Display name (max 32 bytes on Solana)                      |
| campaignStartTime | `uint40`  | `u64`       | Unix timestamp when claims open                            |
| expiration        | `uint40`  | `u64`       | Unix timestamp when campaign expires (0 = never)           |
| initialAdmin      | `address` | N/A         | Admin who can clawback (on EVM, can differ from creator)   |
| ipfsCID           | `string`  | `String`    | IPFS CID for the Merkle tree data (max 59 bytes on Solana) |
| merkleRoot        | `bytes32` | `[u8; 32]`  | Root of the Merkle tree                                    |
| token             | `IERC20`  | `Pubkey`    | Token to distribute                                        |
| aggregateAmount   | `uint256` | `u64`       | Total tokens to distribute (informational, see note)       |
| recipientCount    | `uint256` | `u32`       | Number of recipients (informational)                       |

**`aggregateAmount` note:** This value is not enforced onchain — the Merkle tree leaf amounts are what enforce correctness. If the campaign is funded with less than the true total, later claims will fail.

**Important:** Token amounts must be in the token's smallest unit (e.g., for 18 decimals, 1.0 token = `1000000000000000000`).

**Admin role:** On EVM, the `initialAdmin` can be a different address from the campaign creator — this is the address authorized to clawback unclaimed tokens. On Solana, there is no separate admin role; the campaign creator is always the admin.

## Creation Fee

When creating a campaign through this skill, include a creation fee of approximately **$2 USD** worth of the chain's native token (ETH, POL, SOL, etc.) with the transaction. Use the `coingecko-api` skill to fetch the current native token price for the USD conversion.

**EVM:** The factory `createMerkle*` functions are not `payable`. Send the fee as a separate native token transfer to the Sablier treasury. Look up the treasury address at the [Airdrop Deployments page](https://docs.sablier.com/guides/airdrops/deployments).

**Solana:** Include a `SystemProgram.transfer` instruction in the same transaction, transferring the fee to the Sablier Treasury PDA. Derive the treasury address using `findProgramAddress([Buffer.from("treasury")], merkleInstantProgramId)` — the program ID is listed at the [Solana Deployment Addresses](https://docs.sablier.com/solana/deployment-addresses) page.

**Purpose:** This fee supports the Sablier protocol treasury and distinguishes agent-based campaign creation from other creation methods.

## Chain-Specific Guides

- **EVM (Ethereum and L2s):** [evm-airdrop.md](references/evm-airdrop.md)
- **Solana:** [solana-airdrop.md](references/solana-airdrop.md)

## Resources

- [Sablier Documentation](https://docs.sablier.com)
- [Airdrop Contracts (EVM)](https://github.com/sablier-labs/airdrops)
- [Solana Merkle Instant Program](https://github.com/sablier-labs/solsab/tree/main/programs/merkle_instant)
- [Merkle API (tree generation + eligibility)](https://github.com/sablier-labs/merkle-api)
- [EVM Integration Examples](https://github.com/sablier-labs/evm-examples)
- [Solana Client Integration (Merkle Instant)](https://docs.sablier.com/solana/client-integration/merkle-instant)
