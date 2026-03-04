# EVM Merkle Airdrop Creation

## Factory Contracts

Each campaign type has a dedicated factory contract that deploys campaign instances via CREATE2:

| Campaign Type | Factory Contract              |
| ------------- | ----------------------------- |
| Instant       | `SablierFactoryMerkleInstant` |
| Linear (LL)   | `SablierFactoryMerkleLL`      |
| Tranched (LT) | `SablierFactoryMerkleLT`      |
| VCA           | `SablierFactoryMerkleVCA`     |

Look up the deployed factory addresses for your target chain at the [Airdrop Deployments page](https://docs.sablier.com/guides/airdrops/deployments). Do not hardcode addresses.

## Prerequisites

1. **Generate the Merkle tree and upload to IPFS.** Use the [Merkle API](https://github.com/sablier-labs/merkle-api) — it returns the `merkleRoot` and `ipfsCID` needed for the factory call. See [merkle-tree.md](merkle-tree.md) for details.
2. **Call the factory** to deploy the campaign contract.
3. **Send the creation fee.** Transfer ~$2 USD worth of native token to the Sablier treasury as a separate transaction. See the main SKILL.md for the treasury address.
4. **Fund the campaign.** Transfer the `aggregateAmount` of tokens to the deployed campaign contract address.

## Instant Campaigns

Tokens transfer immediately to recipients on claim.

### Constructor Params

```solidity
struct ConstructorParams {
    string campaignName;
    uint40 campaignStartTime;
    uint40 expiration;          // 0 = never expires
    address initialAdmin;
    string ipfsCID;
    bytes32 merkleRoot;
    IERC20 token;
}
```

### Factory Function

```solidity
function createMerkleInstant(
    MerkleInstant.ConstructorParams memory params,
    uint256 aggregateAmount,
    uint256 recipientCount
) external returns (ISablierMerkleInstant merkleInstant);
```

## Lockup Linear Campaigns (MerkleLL)

Each claim creates a Lockup Linear stream with the specified vesting schedule.

### Constructor Params

```solidity
struct ConstructorParams {
    string campaignName;
    uint40 campaignStartTime;
    bool cancelable;
    uint40 cliffDuration;               // seconds, 0 = no cliff
    UD60x18 cliffUnlockPercentage;      // 1e18 = 100%
    uint40 expiration;
    address initialAdmin;
    string ipfsCID;
    ISablierLockup lockup;              // look up at https://docs.sablier.com/guides/lockup/deployments
    bytes32 merkleRoot;
    string shape;                       // stream shape label (see shape values in evm-lockup.md)
    UD60x18 startUnlockPercentage;      // 1e18 = 100%
    IERC20 token;
    uint40 totalDuration;               // total vesting duration in seconds
    bool transferable;
    uint40 vestingStartTime;            // 0 = relative to each claim
}
```

**Vesting start behavior:**
- `vestingStartTime > 0`: All recipients vest from the same absolute timestamp (synchronized).
- `vestingStartTime == 0`: Vesting starts at `block.timestamp` of each individual claim.

### Validation Rules

- `totalDuration > 0`
- If `cliffDuration > 0`: `cliffDuration < totalDuration`
- If `cliffDuration == 0`: `cliffUnlockPercentage` must be 0
- `startUnlockPercentage + cliffUnlockPercentage <= 1e18`

### Factory Function

```solidity
function createMerkleLL(
    MerkleLL.ConstructorParams memory params,
    uint256 aggregateAmount,
    uint256 recipientCount
) external returns (ISablierMerkleLL merkleLL);
```

## Lockup Tranched Campaigns (MerkleLT)

Each claim creates a Lockup Tranched stream with percentage-based unlock steps.

### Constructor Params

```solidity
struct ConstructorParams {
    string campaignName;
    uint40 campaignStartTime;
    bool cancelable;
    uint40 expiration;
    address initialAdmin;
    string ipfsCID;
    ISablierLockup lockup;              // look up at https://docs.sablier.com/guides/lockup/deployments
    bytes32 merkleRoot;
    string shape;                       // stream shape label (see shape values in evm-lockup.md)
    IERC20 token;
    MerkleLT.TrancheWithPercentage[] tranchesWithPercentages;
    bool transferable;
    uint40 vestingStartTime;            // 0 = relative to each claim
}
```

### Tranche Definition

```solidity
struct TrancheWithPercentage {
    UD2x18 unlockPercentage;  // fraction of total claim (1e18 = 100%)
    uint40 duration;          // seconds (first from start, rest from previous tranche)
}
```

**Note on percentage types:** MerkleLT uses `UD2x18` (wraps `uint64`, construct with `ud2x18()`), while MerkleLL and MerkleVCA use `UD60x18` (wraps `uint256`, construct with `ud60x18()`). Both use `1e18 = 100%`.

All tranche percentages must amount to exactly 100%. Use the factory's helper to verify:

```solidity
function isPercentagesSum100(
    MerkleLT.TrancheWithPercentage[] calldata tranches
) external pure returns (bool result);
```

### Validation Rules

- At least one tranche
- All tranche percentages must amount to exactly 100%
- All tranche durations > 0

### Factory Function

```solidity
function createMerkleLT(
    MerkleLT.ConstructorParams memory params,
    uint256 aggregateAmount,
    uint256 recipientCount
) external returns (ISablierMerkleLT merkleLT);
```

## Variable Claim Amount Campaigns (MerkleVCA)

Recipients can claim at any time during the vesting period, but only receive the portion vested so far — unvested tokens are forfeited. Waiting until the end of the vesting period yields the full amount.

### Constructor Params

```solidity
struct ConstructorParams {
    string campaignName;
    uint40 campaignStartTime;
    uint40 expiration;                  // required, must be > 0
    address initialAdmin;
    string ipfsCID;
    bytes32 merkleRoot;
    IERC20 token;
    UD60x18 unlockPercentage;           // immediate unlock fraction (1e18 = 100%)
    uint40 vestingEndTime;              // required, must be > vestingStartTime
    uint40 vestingStartTime;            // required, must be > 0
}
```

### Validation Rules

- `vestingStartTime > 0`
- `vestingEndTime > vestingStartTime`
- `expiration > 0`
- `expiration >= vestingEndTime + 1 week` (recipients need time to claim after vesting ends)
- `unlockPercentage <= 1e18`

### Factory Function

```solidity
function createMerkleVCA(
    MerkleVCA.ConstructorParams memory params,
    uint256 aggregateAmount,
    uint256 recipientCount
) external returns (ISablierMerkleVCA merkleVCA);
```

## Deterministic Addresses

Each factory exposes a `compute*` function to predict the campaign address before deployment:

```solidity
function computeMerkleInstant(
    address campaignCreator,
    MerkleInstant.ConstructorParams memory params
) external view returns (address merkleInstant);
```

Same pattern for `computeMerkleLL`, `computeMerkleLT`, `computeMerkleVCA`.
