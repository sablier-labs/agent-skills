# Sablier-Supported EVM Chain Explorers

Source: resolved `blockExplorers.default` from `sablier.evm.chains` in `sablier@3.11.2`.
Each row reflects the explorer that `sablier` itself will route to (viem default + Sablier overrides).

## Mainnets

| Chain key   | Chain ID | Display name  | Explorer name              | Explorer URL                      |
| ----------- | -------- | ------------- | -------------------------- | --------------------------------- |
| `abstract`  | 2741     | Abstract      | Etherscan                  | https://abscan.org                |
| `arbitrum`  | 42161    | Arbitrum      | Arbiscan                   | https://arbiscan.io               |
| `avalanche` | 43114    | Avalanche     | Snowscan                   | https://snowscan.xyz              |
| `base`      | 8453     | Base          | Basescan                   | https://basescan.org              |
| `berachain` | 80094    | Berachain     | Berascan                   | https://berascan.com              |
| `blast`     | 81457    | Blast         | Blastscan                  | https://blastscan.io              |
| `bsc`       | 56       | BNB Chain     | BscScan                    | https://bscscan.com               |
| `chiliz`    | 88888    | Chiliz        | Explorer                   | https://chiliscan.com             |
| `coreDao`   | 1116     | Core Dao      | CoreDao                    | https://scan.coredao.org          |
| `denergy`   | 369369   | Denergy       | Explorer                   | https://explorer.denergychain.com |
| `gnosis`    | 100      | Gnosis        | Gnosisscan                 | https://gnosisscan.io             |
| `hyperevm`  | 999      | HyperEVM      | HyperEVMScan               | https://hyperevmscan.io           |
| `lightlink` | 1890     | Lightlink     | LightLink Phoenix Explorer | https://phoenix.lightlink.io      |
| `linea`     | 59144    | Linea Mainnet | Etherscan                  | https://lineascan.build           |
| `mainnet`   | 1        | Ethereum      | Etherscan                  | https://etherscan.io              |
| `mode`      | 34443    | Mode          | Modescan                   | https://modescan.io               |
| `monad`     | 143      | Monad         | Explorer                   | https://monadscan.com             |
| `morph`     | 2818     | Morph         | Morph Explorer             | https://explorer.morphl2.io       |
| `optimism`  | 10       | OP Mainnet    | Optimism Explorer          | https://optimistic.etherscan.io   |
| `polygon`   | 137      | Polygon       | PolygonScan                | https://polygonscan.com           |
| `ronin`     | 2020     | Ronin         | Ronin Explorer             | https://app.roninchain.com        |
| `scroll`    | 534352   | Scroll        | Scrollscan                 | https://scrollscan.com            |
| `sei`       | 1329     | Sei Network   | Explorer                   | https://seiscan.io                |
| `sonic`     | 146      | Sonic         | Sonic Explorer             | https://sonicscan.org             |
| `sophon`    | 50104    | Sophon        | Explorer                   | https://sophscan.xyz              |
| `superseed` | 5330     | Superseed     | Superseed Explorer         | https://explorer.superseed.xyz    |
| `taiko`     | 167000   | Taiko         | Etherscan                  | https://taikoscan.io              |
| `tangle`    | 5845     | Tangle        | Explorer                   | https://explorer.tangle.tools     |
| `unichain`  | 130      | Unichain      | Uniscan                    | https://uniscan.xyz               |
| `xdc`       | 50       | XDC           | XDCScan                    | https://xdcscan.com               |
| `zksync`    | 324      | ZKsync Era    | ZKsync Explorer            | https://explorer.zksync.io        |

## Testnets

| Chain key            | Chain ID | Display name           | Explorer name              | Explorer URL                             |
| -------------------- | -------- | ---------------------- | -------------------------- | ---------------------------------------- |
| `arbitrumSepolia`    | 421614   | Arbitrum Sepolia       | Arbiscan                   | https://sepolia.arbiscan.io              |
| `baseSepolia`        | 84532    | Base Sepolia           | Basescan                   | https://sepolia.basescan.org             |
| `battlechainTestnet` | 627      | BattleChain Testnet    | BattleChain Explorer       | https://explorer.testnet.battlechain.com |
| `lineaSepolia`       | 59141    | Linea Sepolia          | Etherscan                  | https://sepolia.lineascan.build          |
| `optimismSepolia`    | 11155420 | OP Sepolia             | Blockscout                 | https://optimism-sepolia.blockscout.com  |
| `sepolia`            | 11155111 | Sepolia                | Etherscan                  | https://sepolia.etherscan.io             |
| `superseedSepolia`   | 53302    | Superseed Sepolia      | Superseed Sepolia Explorer | https://sepolia-explorer.superseed.xyz   |
| `zksyncSepolia`      | 300      | ZKsync Sepolia Testnet | ZKsync Explorer            | https://sepolia.explorer.zksync.io       |

## Notes

- The `Explorer name` column reproduces what `sablier@3.11.2` emits verbatim, even when terse (e.g. `"Explorer"` for Chiliz, Denergy, Monad, Sei, Sophon, Tangle, and the chain `chiliz` exports). Use the URL to disambiguate.
- `optimismSepolia` (chain ID 11155420) defaults to a **Blockscout** instance, not Etherscan.
- ZKsync (`zksync`, `zksyncSepolia`) uses ZKsync's own explorer at `explorer.zksync.io` / `sepolia.explorer.zksync.io`, not an Etherscan-family URL.
- Avalanche uses **Snowscan** (`snowscan.xyz`), an explicit Sablier override of viem's default.
- Sablier defines two custom chains not in viem core: `denergy` (369369) and `tangle` (5845).
- Ronin's explorer (`app.roninchain.com`) does not follow the Etherscan `/address/<addr>` pattern. If a Ronin link is needed, verify the path against the explorer UI before constructing it.
