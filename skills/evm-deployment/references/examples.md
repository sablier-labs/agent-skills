# Deployment Examples

Real-world examples from Monad mainnet deployment (Chain ID: 143).

## Etherscan V2 API Verification

Monad uses MonadScan (Etherscan-compatible). Foundry doesn't support it natively:

```
Error: No known Etherscan API URL for chain 143
```

**Solution:** Use Etherscan V2 API with explicit `--verifier-url`:

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
  0x1feB172238638897B13b69C65feB508a0a96b35D \
  src/libraries/LockupMath.sol:LockupMath \
  --verifier etherscan \
  --verifier-url "https://api.etherscan.io/v2/api?chainid=143" \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --watch
```

## Bytecode Mismatch Resolution

Verification failed with "bytecode does not match" despite same Solidity version:

```
Error: Bytecode does not match
```

**Root Cause:** `node_modules` had drifted from deployment state.

**Solution:**

```bash
# Find deployment commit from SDK broadcast
cat ../sdk/deployments/airdrops/v1.4/broadcasts/monad.json | jq -r '.commit'
# Output: cec949f

# Checkout and reinstall
git checkout cec949f
bun install

# Rebuild and verify
FOUNDRY_PROFILE=optimized forge build
FOUNDRY_PROFILE=optimized forge verify-contract ...
```

## Proxy Pattern Verification (Comptroller)

Comptroller uses ERC1967 proxy. The broadcast shows 3 transactions:

```json
{
  "transactions": [
    { "contractName": "SablierComptroller", "contractAddress": "0x53de3a..." },
    { "contractName": "ERC1967Proxy", "contractAddress": "0x0000008A..." },
    { "contractName": null, "function": "initialize(address)" }
  ]
}
```

**Verify Implementation:**

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
  0x53de3a712d2b6657e92fa2452d58a6b823f86920 \
  src/SablierComptroller.sol:SablierComptroller \
  --verifier etherscan \
  --verifier-url "https://api.etherscan.io/v2/api?chainid=143" \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --watch
```

**Verify Proxy:**

```bash
# Get initialize calldata from broadcast
INIT_CALLDATA=$(jq -r '.transactions[2].transaction.input' broadcast/.../run-latest.json)

# Encode constructor args
CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address,bytes)" \
  0x53de3a712d2b6657e92fa2452d58a6b823f86920 \
  $INIT_CALLDATA)

FOUNDRY_PROFILE=optimized forge verify-contract \
  0x0000008ABbFf7a84a2fE09f9A9b74D3BC2072399 \
  node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy \
  --verifier etherscan \
  --verifier-url "https://api.etherscan.io/v2/api?chainid=143" \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $CONSTRUCTOR_ARGS \
  --watch
```

## Campaign Deployment (Airdrops)

### MerkleInstant Campaign

```bash
FOUNDRY_PROFILE=optimized forge script \
  scripts/solidity/CreateMerkleInstant.s.sol:CreateMerkleInstant \
  --broadcast \
  --rpc-url monad \
  --private-key $PRIVATE_KEY \
  --sig "run(address)" \
  0xaB15e653cD3bBCe7B7412f81056a450BC0f2e7B9 \
  -vvv
```

**Output:**

```
== Return ==
merkleInstant: 0xEEd8aBF8D93Df0185d5A683Dff7DC00F656aD61C
```

### MerkleLL Campaign (with Lockup + Token)

```bash
FOUNDRY_PROFILE=optimized forge script \
  scripts/solidity/CreateMerkleLL.s.sol:CreateMerkleLL \
  --broadcast \
  --rpc-url monad \
  --private-key $PRIVATE_KEY \
  --sig "run(address,address,address)" \
  0x7DcAB43465c1EbDA92133c92262a6c55394dD69e \
  0x003f5393f4836f710d492ad98d89f5bfccf1c962 \
  0x6D64Fc0BB0291C6A4F416eC1C379815C06967EaF \
  -vvv
```

## Factory-Created Contract Verification

Campaigns are deployed via factory using CREATE2. Constructor args are embedded in `initCode`.

### Extract Constructor Args

```bash
# Get initCode from broadcast
jq -r '.transactions[0].transaction.input' \
  broadcast/CreateMerkleInstant.s.sol/143/run-latest.json > /tmp/initcode.txt
```

```python
# Python script to extract args
data = open('/tmp/initcode.txt').read().strip()
# Solidity 0.8.29 metadata hash ending
idx = data.find('64736f6c634300081d0033')
if idx != -1:
    args = data[idx + len('64736f6c634300081d0033'):]
    print('0x' + args)
```

### Verify Campaign

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
  0xEEd8aBF8D93Df0185d5A683Dff7DC00F656aD61C \
  src/SablierMerkleInstant.sol:SablierMerkleInstant \
  --verifier etherscan \
  --verifier-url "https://api.etherscan.io/v2/api?chainid=143" \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args 0x000000000000000000... \
  --watch
```

## Complete Monad Deployment Summary

### Lockup Protocol

| Contract            | Address                                      |
| ------------------- | -------------------------------------------- |
| LockupMath          | `0x1feB172238638897B13b69C65feB508a0a96b35D` |
| LockupNFTDescriptor | `0x619E7f9832522EDeBd883482Cd3d84653A050725` |
| SablierBatchLockup  | `0x4FCACf614E456728CaEa87f475bd78EC3550E20B` |
| SablierLockup       | `0x003F5393F4836f710d492AD98D89F5BFCCF1C962` |

### Flow Protocol

| Contract          | Address                                      |
| ----------------- | -------------------------------------------- |
| FlowNFTDescriptor | `0xf51BB8bd1cfc7C890dB68c39dCCA67CAd7810Ce4` |
| SablierFlow       | `0x0340a829b6dC3aDF7710a5bAF1970914af4977f5` |

### Comptroller

| Contract       | Address                                      |
| -------------- | -------------------------------------------- |
| Implementation | `0x53de3a712d2b6657e92fa2452d58a6b823f86920` |
| Proxy          | `0x0000008ABbFf7a84a2fE09f9A9b74D3BC2072399` |

### Airdrops Factories

| Contract                    | Address                                      |
| --------------------------- | -------------------------------------------- |
| SablierFactoryMerkleInstant | `0xaB15e653cD3bBCe7B7412f81056a450BC0f2e7B9` |
| SablierFactoryMerkleLL      | `0x7DcAB43465c1EbDA92133c92262a6c55394dD69e` |
| SablierFactoryMerkleLT      | `0xfA2Bf3EDdEfE67631BfFA5C53b621A9C6BEbc9C3` |
| SablierFactoryMerkleVCA     | `0xCdCc46A7759dE01271E533BBC3b0F32899545a76` |

### Airdrops Campaigns (Test)

| Contract             | Address                                      |
| -------------------- | -------------------------------------------- |
| SablierMerkleInstant | `0xEEd8aBF8D93Df0185d5A683Dff7DC00F656aD61C` |
| SablierMerkleLL      | `0x24B114Ce16a6B7A0CE1C1548e2843A97D07FE879` |
| SablierMerkleLT      | `0x618BC29c7bDAd6e5e86D3cD0c9c31EeA2Ab71d9F` |
| SablierMerkleVCA     | `0x256cFd4829cf25A61021EAe6AD498E600b28bC4f` |
