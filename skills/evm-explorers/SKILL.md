---
name: evm-explorers
description: This skill should be used when the user asks to "open on explorer", "block explorer URL", "Etherscan link", "Arbiscan link", "view tx on explorer", "explorer for chain X", or needs to construct a link to an address, transaction, or contract on a Sablier-supported EVM chain. Provides the canonical default block explorer (URL and human-readable name) for every chain shipped by the `sablier` npm package.
---

# EVM Explorers

## Overview

Resolve the canonical default block explorer for any chain supported by the [`sablier`](https://www.npmjs.com/package/sablier) npm package.

For every chain in `sablier@3.11.2` the skill records:

- Chain key (the export name in `sablier.evm.chains`)
- Chain ID
- Display name
- Explorer name
- Explorer base URL

Use this when constructing links to addresses, transactions, blocks, or contracts on chains used by Sablier products.

## Source of truth

The canonical data is the resolved `blockExplorers.default` field on each chain in `sablier.evm.chains` (a re-export of `viem/chains`, with Sablier overrides applied).

Reference table: [`references/explorers.md`](references/explorers.md).

If the user explicitly asks the skill to refresh the data, reproduce it with:

```bash
mkdir -p /tmp/sablier-explorers && cd /tmp/sablier-explorers
[ -f package.json ] || npm init -y >/dev/null
npm install sablier@latest >/dev/null
node --input-type=module -e "
import { evm } from 'sablier';
const rows = Object.entries(evm.chains).map(([key, c]) => ({
  key, id: c.id, name: c.name,
  explorerName: c.blockExplorers?.default?.name,
  explorerUrl: c.blockExplorers?.default?.url,
  testnet: c.testnet === true,
}));
console.log(JSON.stringify(rows, null, 2));
"
```

Do **not** install `sablier` as part of normal skill execution — the table in `references/explorers.md` is authoritative. Only refresh when the user requests it.

## Resolution rules

1. **Match by chain key first** (e.g. `arbitrum`, `zksync`, `optimismSepolia`). The keys are the `sablier.evm.chains` export names.
2. **Fall back to chain ID** (e.g. `42161` → arbitrum). Always prefer chain ID when the user provides one — it's unambiguous.
3. **Match by display name** as a last resort (case-insensitive). Be careful with overloaded names (e.g. "Optimism" vs "OP Mainnet").
4. **Sepolia variants are distinct chains.** `arbitrum-sepolia` is `https://sepolia.arbiscan.io`, not `https://arbiscan.io`.
5. **If the chain is not in the table, stop.** Do not invent an explorer URL. Tell the user the chain isn't supported by `sablier` and ask them to confirm or fetch upstream `viem/chains` data instead.

## Building links

The default explorer URL is the base. Append the standard path segments:

| Resource    | Path                            | Example                                                       |
| ----------- | ------------------------------- | ------------------------------------------------------------- |
| Address     | `/address/<addr>`               | `https://arbiscan.io/address/0xabc...`                        |
| Transaction | `/tx/<hash>`                    | `https://etherscan.io/tx/0x123...`                            |
| Block       | `/block/<number>`               | `https://basescan.org/block/12345678`                         |
| Token       | `/token/<addr>`                 | `https://polygonscan.com/token/0xdef...`                      |

Etherscan and explorers operated on the Etherscan stack — Arbiscan, Basescan, BscScan, Polygonscan, Optimism Etherscan, Lineascan, Snowscan, Blastscan, Scrollscan, Berascan, Uniscan, Gnosisscan, abscan.org — all follow this scheme. Most other explorers in the table (Blockscout-based, ZKsync's native explorer, `phoenix.lightlink.io`, `seiscan.io`, `monadscan.com`, `sophscan.xyz`, `chiliscan.com`) accept the same `/address`, `/tx`, `/block` segments, but they're operated independently and conventions can drift.

**Ronin (`app.roninchain.com`) does not follow the Etherscan path scheme.** Verify against the explorer UI before constructing a Ronin link.

`getContractExplorerURL(explorerURL, contractAddress)` is also exported by `sablier` if the caller already has a sablier dependency.

## Output format

Default to a compact table when listing:

```markdown
| Chain        | Chain ID | Explorer  | URL                          |
| ------------ | -------- | --------- | ---------------------------- |
| Arbitrum     | 42161    | Arbiscan  | https://arbiscan.io          |
```

For a single chain, return one line: `Arbitrum (42161) → Arbiscan: https://arbiscan.io`.

Honor any explicit format the user requests (JSON, plain URL, etc.).

## Reference files

- [`references/explorers.md`](references/explorers.md) — full mapping of every chain in `sablier.evm.chains` to its default explorer.
