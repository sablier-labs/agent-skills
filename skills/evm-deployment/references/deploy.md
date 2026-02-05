# Deploy Contracts

## Prerequisites

Gather before deployment:

| Requirement        | How to Check/Get                                          |
| ------------------ | --------------------------------------------------------- |
| Chain ID           | Ask user if unknown                                       |
| Deployment type    | `deterministic` (CREATE2) or `non-deterministic` (CREATE) |
| PRIVATE_KEY        | Must be in `.env`, load with `source .env`                |
| RPC endpoint       | Must exist in `foundry.toml` under `[rpc_endpoints]`      |
| Explorer URL       | Ask user (prefer Etherscan-compatible)                    |
| @sablier/evm-utils | Run `bun install` to ensure latest                        |

## RPC Configuration

If RPC not in `foundry.toml`, configure it:

### Option 1: Routemesh (preferred)

```bash
# Construct URL
RPC_URL="https://lb.routeme.sh/rpc/<CHAIN_ID>/${ROUTEMESH_API_KEY}"

# Test connectivity using deployer address
cast balance $(cast wallet address --private-key $PRIVATE_KEY) --ether --rpc-url $RPC_URL
```

### Option 2: Chainlist.org (fallback)

Search https://chainlist.org/ and test the RPC:

```bash
cast balance $(cast wallet address --private-key $PRIVATE_KEY) --ether --rpc-url $RPC_URL
```

### Add to foundry.toml

Add alphabetically under `[rpc_endpoints]`:

```toml
<chain_name> = "<RPC_URL>"
```

## Deployment Commands

### Deterministic (CREATE2) - preferred

```bash
FOUNDRY_PROFILE=optimized forge script \
  scripts/solidity/<DETERMINISTIC_SCRIPT> \
  --broadcast \
  --rpc-url <chain_name> \
  --private-key $PRIVATE_KEY \
  --sig "run()" \
  -vvv
```

### Non-deterministic (CREATE)

```bash
FOUNDRY_PROFILE=optimized forge script \
  scripts/solidity/<NON_DETERMINISTIC_SCRIPT> \
  --broadcast \
  --rpc-url <chain_name> \
  --private-key $PRIVATE_KEY \
  --sig "run()" \
  -vvv
```

### Script Names by Protocol

| Protocol     | Deterministic                               | Non-deterministic              |
| ------------ | ------------------------------------------- | ------------------------------ |
| Comptroller  | `DeployDeterministicComptrollerProxy.s.sol` | `DeployComptrollerProxy.s.sol` |
| ERC20 Faucet | `DeployDeterministicERC20Faucet.s.sol`      | `DeployERC20Faucet.s.sol`      |
| Flow         | `DeployDeterministicProtocol.s.sol`         | `DeployProtocol.s.sol`         |
| Lockup       | `DeployDeterministicProtocol.s.sol`         | `DeployProtocol.s.sol`         |
| Airdrops     | `DeployDeterministicFactories.s.sol`        | `DeployFactories.s.sol`        |

### Verification Flags

For Etherscan-compatible explorers, append:

```bash
  --verify \
  --verifier etherscan \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

If foundry does not support the chain, use the following command:

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
<CONTRACT_ADDRESS> <CONTRACT_NAME> \
--verifier etherscan \
--verifier-url "https://api.etherscan.io/v2/api?chainid=<CHAIN_ID>" \
--etherscan-api-key $ETHERSCAN_API_KEY \
--watch
```

For other verifiers: https://getfoundry.sh/forge/reference/verify-contract

**Note:** Prefer Etherscan. Supported chains: https://docs.etherscan.io/supported-chains

## Deployed Contracts by Protocol

### Comptroller

| Contract           | Description               | Notes                                                                                                                |
| ------------------ | ------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| SablierComptroller | Core comptroller contract | Skip if already deployed, this can be verified through `getComptroller` in `BaseScript.sol` in `@sablier/evm-utils`. |
| ERC20 Faucet       | ERC20 token faucet        | Always deploy                                                                                                        |

### Flow

| Contract          | Description             | Notes                                      |
| ----------------- | ----------------------- | ------------------------------------------ |
| FlowNFTDescriptor | NFT metadata renderer   | Skipped if in `NFTDescriptorAddresses.sol` |
| SablierFlow       | Core streaming contract | Always deploy                              |

### Lockup

| Contract            | Description             | Notes                                            |
| ------------------- | ----------------------- | ------------------------------------------------ |
| LockupNFTDescriptor | NFT metadata renderer   | Skipped if in `LockupNFTDescriptorAddresses.sol` |
| SablierLockup       | Core streaming contract | Always deploy                                    |
| SablierBatchLockup  | Batch operations        | Always deploy                                    |

### Airdrops

| Contract                    | Description                    | Notes         |
| --------------------------- | ------------------------------ | ------------- |
| SablierFactoryMerkleInstant | Merkle Instant airdrop factory | Always deploy |
| SablierFactoryMerkleLL      | Merkle LL airdrop factory      | Always deploy |
| SablierFactoryMerkleLT      | Merkle LT airdrop factory      | Always deploy |
| SablierFactoryMerkleVCA     | Merkle VCA airdrop factory     | Always deploy |

## Broadcast File Location

| Deployment Type   | Path Pattern                                                      |
| ----------------- | ----------------------------------------------------------------- |
| Deterministic     | `broadcast/<DETERMINISTIC_SCRIPT>/<CHAIN_ID>/run-latest.json`     |
| Non-deterministic | `broadcast/<NON_DETERMINISTIC_SCRIPT>/<CHAIN_ID>/run-latest.json` |

## Manual Verification

Use Playwright to check verification status on the explorer.

### Method 1: Forge CLI (preferred)

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
  <CONTRACT_ADDRESS> \
  src/<Contract>.sol:<Contract> \
  --rpc-url <chain_name> \
  --verifier etherscan \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

### Method 2: Etherscan V2 API (for unsupported chains)

When Foundry doesn't support the chain natively (e.g., "No known Etherscan API URL for chain X"):

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
  <CONTRACT_ADDRESS> \
  src/<Contract>.sol:<Contract> \
  --verifier etherscan \
  --verifier-url "https://api.etherscan.io/v2/api?chainid=<CHAIN_ID>" \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --watch
```

**Note:** Check supported chains at https://docs.etherscan.io/supported-chains

### Method 3: Standard JSON Input (manual fallback)

Generate the JSON:

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
  <CONTRACT_ADDRESS> \
  src/<Contract>.sol:<Contract> \
  --show-standard-json-input > <chain_name>_<Contract>.json
```

Then via Playwright:

1. Navigate to contract page on explorer
2. Click "Verify & Publish"
3. Compiler: from `foundry.toml` → `solc` field
4. License: BUSL-1.1
5. Method: Standard JSON Input
6. Upload generated JSON file
7. Submit

## Troubleshooting

### Bytecode Mismatch

If verification fails with "bytecode does not match":

1. **Check deployment commit** - Find in SDK broadcast JSON or deployment records
2. **Checkout exact commit**:
   ```bash
   git checkout <DEPLOYMENT_COMMIT>
   ```
3. **Reinstall dependencies**:
   ```bash
   bun install
   ```
4. **Rebuild**:
   ```bash
   FOUNDRY_PROFILE=optimized forge build
   ```
5. **Retry verification**

Root cause: `node_modules` drift from deployment state causes different compilation output.

### Proxy Pattern Verification (Comptroller)

Comptroller uses ERC1967 proxy pattern. Verify **both** contracts:

1. **Find addresses** in broadcast JSON - look for 3 transactions:

   - Implementation deployment
   - Proxy deployment
   - Initialize call

2. **Verify implementation**:

   ```bash
   FOUNDRY_PROFILE=optimized forge verify-contract \
     <IMPLEMENTATION_ADDRESS> \
     src/SablierComptroller.sol:SablierComptroller \
     --verifier etherscan \
     --verifier-url "https://api.etherscan.io/v2/api?chainid=<CHAIN_ID>" \
     --etherscan-api-key $ETHERSCAN_API_KEY \
     --watch
   ```

3. **Verify proxy** (use node_modules path):

   ```bash
   FOUNDRY_PROFILE=optimized forge verify-contract \
     <PROXY_ADDRESS> \
     node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy \
     --verifier etherscan \
     --verifier-url "https://api.etherscan.io/v2/api?chainid=<CHAIN_ID>" \
     --etherscan-api-key $ETHERSCAN_API_KEY \
     --constructor-args $(cast abi-encode "constructor(address,bytes)" <IMPLEMENTATION_ADDRESS> <INITIALIZE_CALLDATA>) \
     --watch
   ```

### Factory-Created Contract Verification (Campaigns)

Contracts created via factory (CREATE2) need constructor args extracted from broadcast `initCode`:

1. **Get initCode** from broadcast JSON:

   ```bash
   jq -r '.transactions[0].transaction.input' broadcast/<Script>/<CHAIN_ID>/run-latest.json > /tmp/initcode.txt
   ```

2. **Extract constructor args** (Python):

   ```python
   data = open('/tmp/initcode.txt').read().strip()
   # Find Solidity metadata hash ending (0.8.29 example)
   idx = data.find('64736f6c634300081d0033')
   if idx != -1:
       args = data[idx + len('64736f6c634300081d0033'):]
       print('0x' + args)
   ```

   Metadata hash pattern: `64736f6c6343` = "solcC" + version bytes + `0033`

   - 0.8.29: `64736f6c634300081d0033`
   - 0.8.28: `64736f6c634300081c0033`

3. **Verify with extracted args**:

   ```bash
   FOUNDRY_PROFILE=optimized forge verify-contract \
     <CONTRACT_ADDRESS> \
     src/<Contract>.sol:<Contract> \
     --verifier etherscan \
     --verifier-url "https://api.etherscan.io/v2/api?chainid=<CHAIN_ID>" \
     --etherscan-api-key $ETHERSCAN_API_KEY \
     --constructor-args <EXTRACTED_ARGS> \
     --watch
   ```

**Note:** `--guess-constructor-args` doesn't work with custom `--verifier-url`.
