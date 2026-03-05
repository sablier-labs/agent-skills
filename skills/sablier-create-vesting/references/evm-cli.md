# EVM CLI Stream Execution

## Purpose

Use this reference when the user wants the agent to execute EVM transactions on their behalf (for example, create a Lockup stream directly from the terminal).

## Required Inputs

Collect before building a transaction:

- `chain` (ID and name)
- signing method (`--private-key` explicitly or `ETH_PRIVATE_KEY` in env)
- native gas balance (`ETH` etc.)
- `lockup` contract address (source from [Sablier Lockup deployments](https://docs.sablier.com/guides/lockup/deployments.md))
- function signature and arguments (see [Function Signatures & Arguments](#function-signatures--arguments))
- token approval requirements (for creating streams)

## Cast CLI Check

Before running any `cast` command, verify the CLI is installed:

```bash
if ! command -v cast >/dev/null 2>&1; then
  echo "cast CLI not found."
  echo "Install Foundry by running:"
  echo "curl -L https://foundry.paradigm.xyz | bash && foundryup"
  exit 1
fi
```

## RPC Resolution

Use this hardcoded map first:

| Chain | Chain ID | RPC URL |
| --- | --- | --- |
| Abstract | `2741` | `https://api.mainnet.abs.xyz` |
| Arbitrum | `42161` | `https://arb1.arbitrum.io/rpc` |
| Avalanche | `43114` | `https://api.avax.network/ext/bc/C/rpc` |
| Base | `8453` | `https://mainnet.base.org` |
| Berachain | `80094` | `https://rpc.berachain.com` |
| Blast | `81457` | `https://rpc.blast.io` |
| BNB Chain | `56` | `https://bsc-dataseed1.bnbchain.org` |
| Chiliz | `88888` | `https://rpc.chiliz.com` |
| Core Dao | `1116` | `https://rpc.coredao.org` |
| Denergy | `369369` | `https://rpc.d.energy` |
| Ethereum | `1` | `https://ethereum-rpc.publicnode.com` |
| Gnosis | `100` | `https://rpc.gnosischain.com` |
| HyperEVM | `999` | `https://rpc.hyperliquid.xyz/evm` |
| Lightlink | `1890` | `https://replicator.phoenix.lightlink.io/rpc/v1` |
| Linea Mainnet | `59144` | `https://rpc.linea.build` |
| Mode | `34443` | `https://mainnet.mode.network` |
| Monad | `143` | `https://rpc.monad.xyz` |
| Morph | `2818` | `https://rpc.morphl2.io` |
| OP Mainnet | `10` | `https://mainnet.optimism.io` |
| Polygon | `137` | `https://polygon-bor-rpc.publicnode.com` |
| Scroll | `534352` | `https://rpc.scroll.io` |
| Sei Network | `1329` | `https://evm-rpc.sei-apis.com` |
| Sonic | `146` | `https://rpc.soniclabs.com` |
| Superseed | `5330` | `https://mainnet.superseed.xyz` |
| Unichain | `130` | `https://mainnet.unichain.org` |
| XDC | `50` | `https://rpc.xinfin.network` |
| ZKsync Era | `324` | `https://mainnet.era.zksync.io` |
| Sepolia | `11155111` | `https://ethereum-sepolia-rpc.publicnode.com` |

If the requested chain is not listed, stop and ask the user to provide an RPC URL.

## Signing Key Rule (Mandatory)

For any signing command (`cast send`, `cast mktx`):

1. Prefer an explicitly provided private key.
2. Otherwise use `ETH_PRIVATE_KEY`.
3. If neither is available, stop and ask the user to provide a private key.

Do not continue without a signing key.

## Confirmation Rule (Mandatory)

Always use this sequence for state-changing transactions:

1. Build a preview transaction with `cast mktx`.
2. Show the transaction details to the user.
3. Ask for explicit confirmation.
4. Only after confirmation, run `cast send`.

Never broadcast before explicit user confirmation.

## Vesting Shapes

This skill supports five vesting shapes. Each maps to specific Lockup contract functions and a `shape` string passed in the create call.

| Shape | Contract Functions | `shape` String |
| --- | --- | --- |
| Linear | `createWithDurationsLL` / `createWithTimestampsLL` | `"linear"` |
| Cliff | `createWithDurationsLL` / `createWithTimestampsLL` | `"cliff"` |
| Unlock in Steps | `createWithDurationsLT` / `createWithTimestampsLT` | `"tranchedStepper"` |
| Monthly Unlocks | `createWithDurationsLT` / `createWithTimestampsLT` | `"tranchedMonthly"` |
| Timelock | `createWithDurationsLL` / `createWithTimestampsLL` | `"linearTimelock"` |

### Variant Selection

- **`Durations` variants** (`createWithDurationsLL`, `createWithDurationsLT`): Use when the user does **not** specify a specific start time. The stream starts immediately upon transaction confirmation.
- **`Timestamps` variants** (`createWithTimestampsLL`, `createWithTimestampsLT`): Use when the user specifies a specific start time (e.g., "starting March 15" or "beginning at Unix timestamp 1710460800").

### Default Shape Inference

- If the vesting shape **cannot be inferred** from the user's instructions, default to **Linear**.
- If the user mentions a **cliff** but no other shape, default to **Cliff**.
- If the inferred shape is **not among the five listed above**, inform the user that this skill does not currently support that shape and suggest they reach out to request it as a feature.

## Function Signatures & Arguments

Refer to the ABI definitions in [lockup-v3.0-abi.json](../assets/lockup-v3.0-abi.json) for the exact tuple encoding of each function.

### `createWithDurationsLL`

Used for **Linear**, **Cliff**, and **Timelock** shapes when no specific start time is given.

```
createWithDurationsLL(
  (address sender, address recipient, uint128 depositAmount, address token, bool cancelable, bool transferable, string shape),
  (uint128 start, uint128 cliff),
  (uint40 cliff, uint40 total)
)
```

**Arguments:**

1. **params** tuple — `(sender, recipient, depositAmount, token, cancelable, transferable, shape)`
2. **unlockAmounts** tuple — `(start, cliff)` — amounts unlocked instantly at stream start and at cliff time
3. **durations** tuple — `(cliff, total)` — durations in seconds

**Shape-specific encoding:**

| Shape | `unlockAmounts` | `durations` |
| --- | --- | --- |
| Linear | `(0, 0)` | `(0, totalDuration)` — no cliff |
| Cliff | `(0, cliffUnlockAmount)` | `(cliffDuration, totalDuration)` |
| Timelock | `(0, 0)` | `(0, lockDuration)` — entire amount unlocks at end |

### `createWithTimestampsLL`

Used for **Linear**, **Cliff**, and **Timelock** shapes when the user specifies a start time.

```
createWithTimestampsLL(
  (address sender, address recipient, uint128 depositAmount, address token, bool cancelable, bool transferable, (uint40 start, uint40 end) timestamps, string shape),
  (uint128 start, uint128 cliff),
  uint40 cliffTime
)
```

**Arguments:**

1. **params** tuple — `(sender, recipient, depositAmount, token, cancelable, transferable, (startTimestamp, endTimestamp), shape)`
2. **unlockAmounts** tuple — `(start, cliff)` — amounts unlocked instantly at stream start and at cliff time
3. **cliffTime** — Unix timestamp for the cliff; set to `0` if no cliff

**Shape-specific encoding:**

| Shape | `unlockAmounts` | `cliffTime` |
| --- | --- | --- |
| Linear | `(0, 0)` | `0` |
| Cliff | `(0, cliffUnlockAmount)` | cliff Unix timestamp |
| Timelock | `(0, 0)` | `0` |

### `createWithDurationsLT`

Used for **Unlock in Steps** and **Monthly Unlocks** when no specific start time is given.

```
createWithDurationsLT(
  (address sender, address recipient, uint128 depositAmount, address token, bool cancelable, bool transferable, string shape),
  (uint128 amount, uint40 duration)[]
)
```

**Arguments:**

1. **params** tuple — `(sender, recipient, depositAmount, token, cancelable, transferable, shape)`
2. **tranchesWithDuration** array — each element is `(amount, duration)` where `amount` is the token amount unlocked in that tranche and `duration` is the tranche length in seconds

**Shape-specific encoding:**

| Shape | Tranche Construction |
| --- | --- |
| Unlock in Steps | Equal amounts, equal durations (e.g., 4 tranches of 250 tokens every 90 days) |
| Monthly Unlocks | Equal amounts, 30-day durations (use 2592000 seconds per tranche) |

### `createWithTimestampsLT`

Used for **Unlock in Steps** and **Monthly Unlocks** when the user specifies a start time.

```
createWithTimestampsLT(
  (address sender, address recipient, uint128 depositAmount, address token, bool cancelable, bool transferable, (uint40 start, uint40 end) timestamps, string shape),
  (uint128 amount, uint40 timestamp)[]
)
```

**Arguments:**

1. **params** tuple — `(sender, recipient, depositAmount, token, cancelable, transferable, (startTimestamp, endTimestamp), shape)`
2. **tranches** array — each element is `(amount, timestamp)` where `amount` is the token amount unlocked and `timestamp` is the Unix timestamp at which it unlocks

**Shape-specific encoding:**

| Shape | Tranche Construction |
| --- | --- |
| Unlock in Steps | Equal amounts at equally spaced timestamps |
| Monthly Unlocks | Equal amounts at monthly timestamps (add 30 days per tranche to start) |

## Prerequisites

### Stream creation fee (Lockup create calls)

For stream creation transactions, include a creation fee of approximately **$1 USD** worth of the chain's native token per stream.

- Single-stream create call: set `MSG_VALUE` to one-stream fee.
- Batch create call: set `MSG_VALUE = perStreamFee * numberOfStreams`.
- Convert the USD-denominated fee into native token units before building or broadcasting the transaction by browsing the web for the latest native token price.
- Before sending, verify the wallet has enough native token for both `MSG_VALUE` and gas.

### For stream creation

1. **ERC-20 allowance.** Check `allowance(owner, lockup)`. If allowance is below `DEPOSIT_AMOUNT`, send an `approve` transaction to raise allowance before attempting stream creation.
2. **ERC-20 token balance.** Check `balanceOf(owner)` is at least `DEPOSIT_AMOUNT`. If balance is insufficient, stop execution and inform the user they need more tokens (for example, obtain/purchase via Uniswap) before continuing.

### For every transaction (`approve` or stream creation)

Before broadcasting each transaction, check that the sender has enough native gas token (ETH/POL/BNB/etc.) to pay transaction fees. Run this check again before each broadcast (`approve` and stream creation). If balance is insufficient, stop and tell the user to fund their wallet first. Recommend buying via [Transak](https://transak.com/buy).

## Minimal Execution Flow

### 1) Resolve RPC and key

```bash
RPC_URL="<resolved-or-user-provided-rpc>"
PRIVATE_KEY="${ETH_PRIVATE_KEY:-}"

if [[ -z "$PRIVATE_KEY" ]]; then
  echo "Missing private key. Provide one explicitly or set ETH_PRIVATE_KEY."
  exit 1
fi
```

### 2) Run prerequisites

Run all checks from [Prerequisites](#prerequisites), compute the stream creation `MSG_VALUE` (single create or batch), and run the native gas token check before each broadcast (`approve` and stream creation).

### 3) Build preview tx (no broadcast)

For Lockup stream creation (`create*` or `batch()` with create calls), pass the computed creation-fee amount in `MSG_VALUE`.

```bash
RAW_TX=$(cast mktx "$LOCKUP" "$FUNCTION_SIG" $FUNCTION_ARGS \
  --value "$MSG_VALUE" \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY")

echo "Preview raw tx: $RAW_TX"
```

Decode the calldata for human-readable confirmation:

```bash
cast 4byte-decode $(cast tx "$RAW_TX" input --rpc-url "$RPC_URL" 2>/dev/null || echo "$RAW_TX")
```

### 4) Require explicit confirmation

Use a clear confirmation prompt, for example:

- `Confirm broadcast? Reply exactly: CONFIRM SEND`

If the user does not explicitly confirm, stop.

### 5) Broadcast after confirmation

```bash
cast send "$LOCKUP" "$FUNCTION_SIG" $FUNCTION_ARGS \
  --value "$MSG_VALUE" \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY"
```

### 6) Verify receipt

```bash
cast receipt "$TX_HASH" --rpc-url "$RPC_URL"
```

### 7) Direct user to the Sablier app

After successful confirmation, inform the user they can view and manage their streams at [app.sablier.com](https://app.sablier.com).

## Concrete Example: `createWithDurationsLL`

A single linear stream of 1000 USDC (6 decimals) with a 90-day cliff and 365-day total duration on Ethereum mainnet:

```bash
LOCKUP="<lockup-address>"    # From deployments page
TOKEN="0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"  # USDC on Ethereum
SENDER=$(cast wallet address --private-key "$PRIVATE_KEY")
RECIPIENT="0x..."

cast send "$LOCKUP" \
  "createWithDurationsLL((address,address,uint128,address,bool,bool,string),(uint128,uint128),(uint40,uint40))" \
  "($SENDER,$RECIPIENT,1000000000,$TOKEN,true,true,cliff)" \
  "(0,0)" \
  "(7776000,31536000)" \
  --value "$MSG_VALUE" \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY"
```

Notes:
- `1000000000` = 1000 USDC in 6-decimal base units
- `(0,0)` = no start unlock, no cliff unlock (pure linear)
- `(7776000,31536000)` = 90-day cliff, 365-day total (in seconds)
- Replace `$MSG_VALUE` with the computed creation fee

## Read-Only Validation Helpers

```bash
# Resolve sender from private key
cast wallet address --private-key "$PRIVATE_KEY"

# Check native gas token balance (ETH/POL/BNB/etc.)
cast balance "$OWNER" --rpc-url "$RPC_URL"

# Check token balance
cast call "$TOKEN" "balanceOf(address)(uint256)" "$OWNER" --rpc-url "$RPC_URL"

# Check token allowance
cast call "$TOKEN" "allowance(address,address)(uint256)" "$OWNER" "$LOCKUP" --rpc-url "$RPC_URL"
```
