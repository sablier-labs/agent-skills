# EVM CLI Stream Execution

## Purpose

Use this reference when the user wants the agent to execute EVM transactions on their behalf (for example, create a Lockup stream directly from the terminal).

For developer-side smart contract integration details, use [evm-onchain.md](evm-onchain.md).

## Required Inputs

Collect before building a transaction:

- `chain` (name)
- `lockup` contract address (source from [Sablier Lockup deployments](https://docs.sablier.com/guides/lockup/deployments.md))
- function signature and arguments (for example `createWithTimestampsLL(...)` + args)
- `msg.value` for creation fee (if required)
- token approval requirements (if required)
- signing method (`--private-key` explicitly or `ETH_PRIVATE_KEY` in env)

## Tooling Check (Mandatory)

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
| Ethereum | `1` | `https://ethereum-rpc.publicnode.com` |
| Base | `8453` | `https://mainnet.base.org` |
| Arbitrum One | `42161` | `https://arb1.arbitrum.io/rpc` |
| Optimism | `10` | `https://mainnet.optimism.io` |
| Polygon | `137` | `https://polygon-bor-rpc.publicnode.com` |
| BNB Chain | `56` | `https://bsc-dataseed.bnbchain.org` |
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

### 2) Optional prerequisite tx (approve)

```bash
cast send "$TOKEN" "approve(address,uint256)" "$LOCKUP" "$DEPOSIT_AMOUNT" \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY"
```

### 3) Build preview tx (no broadcast)

```bash
RAW_TX=$(cast mktx "$LOCKUP" "$FUNCTION_SIG" $FUNCTION_ARGS \
  --value "$MSG_VALUE" \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY")

echo "Preview raw tx: $RAW_TX"
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

## Read-Only Validation Helpers

```bash
# Resolve sender from private key
cast wallet address --private-key "$PRIVATE_KEY"

# Check token balance
cast call "$TOKEN" "balanceOf(address)(uint256)" "$OWNER" --rpc-url "$RPC_URL"

# Check token allowance
cast call "$TOKEN" "allowance(address,address)(uint256)" "$OWNER" "$LOCKUP" --rpc-url "$RPC_URL"
```
