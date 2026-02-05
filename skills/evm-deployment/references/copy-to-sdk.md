# Copy to SDK

Update SDK repository with deployment artifacts.

## Prerequisites

| Requirement     | How to Get                                 |
| --------------- | ------------------------------------------ |
| Chain ID        | From deployment step                       |
| Chain name      | Lowercase, e.g., `ethereum`, `arbitrum`    |
| Deployment type | `deterministic` or `non-deterministic`     |
| SDK path        | Usually `../sdk` relative to protocol repo |
| Version         | From `package.json` → `v<major.minor>`     |

## SDK Path Structure

```
sdk/deployments/<protocol>/<version>/
├── broadcasts/
│   └── <chain_name>.json
├── README.md
└── (in src/evm/releases/<protocol>/<version>/)
    └── deployments.ts
```

## Step 1: Copy Broadcast File

```bash
cp broadcast/<SCRIPT_NAME>/<CHAIN_ID>/run-latest.json \
   <SDK_PATH>/deployments/<protocol>/<version>/broadcasts/<chain_name>.json
```

## Step 2: Update README.md

Edit `<SDK_PATH>/deployments/<protocol>/<version>/README.md`

### Deterministic Deployment

Add to `Mainnets` table (alphabetically):

```markdown
| <ChainName> | ChainID <ID>, Version <VERSION> |
```

### Non-deterministic Deployment

Add to `Exceptions` section:

```markdown
For <ChainName>, `CREATE` is used instead of `CREATE2`.
```

And to `Mainnets` table:

```markdown
| <ChainName> | No Salt |
```

Note: For Comptroller, the README.md follows a different structure. Always refer to the README.md in deployment
directory for the specific protocol.

## Step 3: Update deployments.ts

Edit `<SDK_PATH>/src/evm/releases/<protocol>/<version>/deployments.ts`

Note: For Comptroller, edit `<SDK_PATH>/src/evm/comptroller.ts`

### Comptroller Protocol

```typescript
get(chains.<chainName>.id, {
  [SABLIER_COMPTROLLER]: [DEFAULT_COMPTROLLER_ADDRESS, <BLOCK_NUMBER>],
}),
```

### Flow Protocol

Add alphabetically in `mainnets` array:

```typescript
get(chains.<chainName>.id, {
  [manifest.FLOW_NFT_DESCRIPTOR]: "<NFT_DESCRIPTOR_ADDRESS>",
  [manifest.SABLIER_FLOW]: ["<FLOW_ADDRESS>", <BLOCK_NUMBER>],
}),
```

### Lockup Protocol

```typescript
get(chains.<chainName>.id, {
  [manifest.LOCKUP_NFT_DESCRIPTOR]: "<NFT_DESCRIPTOR_ADDRESS>",
  [manifest.SABLIER_LOCKUP]: ["<LOCKUP_ADDRESS>", <BLOCK_NUMBER>],
  [manifest.SABLIER_BATCH_LOCKUP]: "<BATCH_LOCKUP_ADDRESS>", // if deployed
}),
```

### Airdrops Protocol

```typescript
get(chains.<chainName>.id, {
  [manifest.SABLIER_MERKLE_FACTORY]: ["<FACTORY_ADDRESS>", <BLOCK_NUMBER>],
}),
```

## Extracting Values from Broadcast

| Field          | Location in broadcast JSON                                          |
| -------------- | ------------------------------------------------------------------- |
| Main Address   | `returns.<contractName>.value`                                      |
| NFT Descriptor | `returns.nftDescriptor.value` OR from `*NFTDescriptorAddresses.sol` |
| Block Number   | Receipt where `contractAddress` matches → `blockNumber` (hex)       |

### Convert block number

```bash
cast --to-dec 0xABB1A  # → 703258
```

## NFT Descriptor Handling

If NFT descriptor was **not deployed** (reused from existing):

- Get address from `scripts/solidity/*NFTDescriptorAddresses.sol`
- Still add to deployments.ts with the existing address
- Note in deployment summary that descriptor was reused
