# Solana CLI Stream Execution

## Purpose

Use this reference when the user wants the agent to execute Solana transactions on their behalf from the terminal.

This reference is intentionally operational and minimal. For Solana CLI command behavior, consult [solana.com/llms.txt](https://solana.com/llms.txt).

## Required Inputs

Collect before running transactions:

- `cluster` (for example `mainnet-beta`, `devnet`, `testnet`) or explicit RPC URL
- destination program/account inputs for the intended operation
- signing keypair path (explicit) or `SOLANA_KEYPAIR` in env

## RPC Resolution

Use this hardcoded map first:

| Cluster | RPC URL |
| --- | --- |
| Mainnet Beta | `https://api.mainnet-beta.solana.com` |
| Devnet | `https://api.devnet.solana.com` |
| Testnet | `https://api.testnet.solana.com` |

If the requested cluster/network is not listed, stop and ask the user to provide an RPC URL.

## Keypair Rule (Mandatory)

For signing commands:

1. Prefer an explicitly provided keypair path (`--keypair` / `--from`).
2. Otherwise use `SOLANA_KEYPAIR`.
3. If neither is available, stop and ask the user to provide a keypair path.

Do not continue without a signer.

## Confirmation Rule (Mandatory)

Always preview/sign first, then ask confirmation, then broadcast:

1. Generate a sign-only preview (`--sign-only`) when supported.
2. Show the preview output.
3. Ask for explicit confirmation.
4. Broadcast only after confirmation.

Never broadcast before explicit user confirmation.

## Minimal Execution Flow

### 1) Resolve RPC and signer

```bash
RPC_URL="<resolved-or-user-provided-rpc>"
KEYPAIR_PATH="${SOLANA_KEYPAIR:-}"

if [[ -z "$KEYPAIR_PATH" ]]; then
  echo "Missing keypair path. Provide one explicitly or set SOLANA_KEYPAIR."
  exit 1
fi
```

### 2) Configure CLI context (optional)

```bash
solana config set --url "$RPC_URL"
solana config set --keypair "$KEYPAIR_PATH"
```

### 3) Preview with sign-only (example)

```bash
solana transfer "$RECIPIENT" "$AMOUNT_SOL" \
  --from "$KEYPAIR_PATH" \
  --url "$RPC_URL" \
  --sign-only
```

### 4) Require explicit confirmation

Use a clear confirmation prompt, for example:

- `Confirm broadcast? Reply exactly: CONFIRM SEND`

If the user does not explicitly confirm, stop.

### 5) Broadcast after confirmation (example)

```bash
solana transfer "$RECIPIENT" "$AMOUNT_SOL" \
  --from "$KEYPAIR_PATH" \
  --url "$RPC_URL"
```

### 6) Verify result

```bash
solana confirm "$SIGNATURE" --url "$RPC_URL"
```

## Useful Read-Only Checks

```bash
solana address --keypair "$KEYPAIR_PATH"
solana balance --url "$RPC_URL"
solana block-height --url "$RPC_URL"
```

## Notes

- Prefer `--sign-only` previews whenever the command supports it.
- If a required command does not support sign-only mode, ask for explicit confirmation immediately before running the broadcast command.
