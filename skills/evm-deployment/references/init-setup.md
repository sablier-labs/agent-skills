# Initial Setup

Create initial setup for deployed contracts. Includes Init scripts for Flow/Lockup and campaign creation for Airdrops.

## Prerequisites

| Requirement         | Source                                                                                            |
| ------------------- | ------------------------------------------------------------------------------------------------- |
| Protocol address    | From deployment step                                                                              |
| ERC20 token address | Ask user (must have mintable token or sufficient balance) or use the one deployed as ERC20 Faucet |
| PRIVATE_KEY         | Load from `.env` via `source .env`                                                                |
| RPC                 | Configured in `foundry.toml`                                                                      |

## Step 1: Get Deployer Address

```bash
cast wallet address --private-key $PRIVATE_KEY
```

## Step 2: Check ERC20 Balance

```bash
# Check token balance (returns raw wei)
cast call <TOKEN_ADDRESS> "balanceOf(address)(uint256)" <DEPLOYER_ADDRESS> --rpc-url <chain_name>

# Convert to human readable
cast --to-unit $(cast call <TOKEN_ADDRESS> "balanceOf(address)(uint256)" <DEPLOYER_ADDRESS> --rpc-url <chain_name>) ether
```

Required: ~1,000,000 tokens (1e24 wei for 18 decimal token)

## Step 3: Mint Tokens (if needed)

```bash
cast send <TOKEN_ADDRESS> "mint(address,uint256)" <DEPLOYER_ADDRESS> 1000000000000000000000000 \
  --rpc-url <chain_name> \
  --private-key $PRIVATE_KEY
```

## Step 4: Run Init Script

### Flow Protocol

```bash
FOUNDRY_PROFILE=optimized forge script scripts/Init.s.sol:Init \
  --broadcast \
  --rpc-url <chain_name> \
  --private-key $PRIVATE_KEY \
  --sig "run(address,address)" \
  <FLOW_ADDRESS> \
  <TOKEN_ADDRESS> \
  -vvv
```

**What Init.s.sol does (Flow):**

1. Approves Flow contract for token spending
2. Creates 10 streams with rates 0.0000001 → 0.000001 tokens/sec
3. Deposits 2 tokens into stream #1
4. Pauses streams #2 and #3
5. Refunds 0.1 tokens from stream #1
6. Restarts stream #3 with new rate
7. Voids stream #7

### Lockup Protocol

```bash
FOUNDRY_PROFILE=optimized forge script scripts/solidity/Init.s.sol:Init \
  --broadcast \
  --rpc-url <chain_name> \
  --private-key $PRIVATE_KEY \
  --sig "run(address,address)" \
  <LOCKUP_ADDRESS> \
  <TOKEN_ADDRESS> \
  -vvv
```

**What Init.s.sol does (Lockup):**

- Creates various stream types (Linear with `granularity`, Dynamic, Tranched)
- Tests different cliff configurations
- Creates cancelable and non-cancelable streams

## Notes

- **Idempotency warning:** Re-running will fail if streams already modified (paused/voided)
- Script location varies: `scripts/Init.s.sol` or `scripts/solidity/Init.s.sol`
- Check the actual script for exact signature if it differs

## Airdrops Protocol

Airdrops uses campaign creation scripts instead of Init scripts.

### Campaign Scripts

| Script                       | Function Signature                                                         | Description            |
| ---------------------------- | -------------------------------------------------------------------------- | ---------------------- |
| `CreateMerkleInstant.s.sol`  | `run(SablierFactoryMerkleInstant factory)`                                 | Instant token airdrops |
| `CreateMerkleLL.s.sol`       | `run(SablierFactoryMerkleLL factory, ISablierLockup lockup, IERC20 token)` | Linear vesting         |
| `CreateMerkleLT.s.sol`       | `run(SablierFactoryMerkleLT factory, ISablierLockup lockup, IERC20 token)` | Tranched vesting       |
| `CreateMerkleVCA.s.sol`      | `run(SablierFactoryMerkleVCA factory)`                                     | VCA vesting            |
| `CreateMerkleExecute.s.sol`  | `run(SablierFactoryMerkleExecute factory)`                                 | Execute on claim       |

### Pre-Deployment Configuration

Edit the script to set campaign parameters:

```solidity
// Required for all campaigns
params.campaignName = "Campaign Name";
params.campaignStartTime = uint40(block.timestamp);
params.claimType = ClaimType.DEFAULT; // or ATTEST, EXECUTE
params.expiration = uint40(block.timestamp + 30 days);
params.initialAdmin = <ADMIN_ADDRESS>;
params.ipfsCID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
params.merkleRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;
params.token = IERC20(<TOKEN_ADDRESS>);

// MerkleLL only:
params.granularity = 0; // 0 = sentinel for 1 second
```

**Notes:**

- For LL/LT campaigns, token is passed as function argument, not in params.
- All campaigns require `ClaimType` (DEFAULT, ATTEST, or EXECUTE) which controls which claim functions are enabled.
- MerkleLL campaigns require `granularity` (uint40) for configurable unlock step sizes (aligns with Lockup v4.0).
- MerkleVCA: `aggregateAmount` is set in `ConstructorParams`, not as a separate function argument.
- MerkleExecute: requires `selector` (bytes4) and `target` (address) for the function to call on claim.

### Deploy Campaign

#### MerkleInstant / MerkleVCA (factory-only args)

```bash
FOUNDRY_PROFILE=optimized forge script scripts/solidity/CreateMerkleInstant.s.sol:CreateMerkleInstant \
  --broadcast \
  --rpc-url <chain_name> \
  --private-key $PRIVATE_KEY \
  --sig "run(address)" \
  <FACTORY_ADDRESS> \
  -vvv
```

#### MerkleLL / MerkleLT (factory + lockup + token args)

```bash
FOUNDRY_PROFILE=optimized forge script scripts/solidity/CreateMerkleLL.s.sol:CreateMerkleLL \
  --broadcast \
  --rpc-url <chain_name> \
  --private-key $PRIVATE_KEY \
  --sig "run(address,address,address)" \
  <FACTORY_ADDRESS> \
  <LOCKUP_ADDRESS> \
  <TOKEN_ADDRESS> \
  -vvv
```

### Verify Campaign Contracts

Campaigns are created via factory (CREATE2). Constructor args are embedded in the factory call's `initCode`.

1. **Extract initCode from broadcast**:

   ```bash
   jq -r '.transactions[0].transaction.input' \
     broadcast/CreateMerkleInstant.s.sol/<CHAIN_ID>/run-latest.json > /tmp/initcode.txt
   ```

2. **Find constructor args** (after Solidity metadata hash):

   ```python
   data = open('/tmp/initcode.txt').read().strip()
   idx = data.find('64736f6c634300081d0033')  # Solidity 0.8.29
   if idx != -1:
       args = data[idx + len('64736f6c634300081d0033'):]
       print('0x' + args)
   ```

3. **Verify**:

   ```bash
   FOUNDRY_PROFILE=optimized forge verify-contract \
     <CAMPAIGN_ADDRESS> \
     src/SablierMerkleInstant.sol:SablierMerkleInstant \
     --verifier etherscan \
     --verifier-url "https://api.etherscan.io/v2/api?chainid=<CHAIN_ID>" \
     --etherscan-api-key $ETHERSCAN_API_KEY \
     --constructor-args <EXTRACTED_ARGS> \
     --watch
   ```

### Notes

- Scripts have hardcoded dummy parameters (merkleRoot, IPFS CID) for testing
- For production, update merkleRoot with actual Merkle tree root
- Campaign addresses returned in broadcast JSON `returns` field
