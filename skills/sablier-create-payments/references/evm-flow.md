# EVM Payment Stream Creation

## Contract

All Flow streams are created through a single contract: **`ISablierFlow`** (deployed as `SablierFlow`).

Look up the deployed address for your target chain at the [Flow Deployments page](https://docs.sablier.com/guides/flow/deployments). Do not hardcode addresses.

## Prerequisites

Before calling any create function:

1. **Approve the token transfer** (only for `createAndDeposit`). The Flow contract pulls tokens from the caller. Call `token.approve(flowAddress, amount)` on the ERC-20 token contract first.
2. **Include the creation fee.** Send approximately $1 USD worth of the native token as `msg.value` with the create transaction. See the main SKILL.md for details.

## Function Signatures

### `create`

Creates a stream with zero balance. Anyone can deposit tokens into the stream later for the recipient to withdraw.

```solidity
function create(
    address sender,
    address recipient,
    UD21x18 ratePerSecond,
    uint40 startTime,
    IERC20 token,
    bool transferable
) external payable returns (uint256 streamId);
```

### `createAndDeposit`

Creates a stream and immediately deposits tokens into it.

```solidity
function createAndDeposit(
    address sender,
    address recipient,
    UD21x18 ratePerSecond,
    uint40 startTime,
    IERC20 token,
    bool transferable,
    uint128 amount
) external payable returns (uint256 streamId);
```

## Validation Rules

- `sender` must not be the zero address
- `token` must be an ERC-20 token (not the chain's native token)
- `token` decimals must be ≤ 18
- If `startTime == 0`: treated as `block.timestamp` (stream starts immediately)
- If `startTime` is in the future: `ratePerSecond` must be > 0 (contract-enforced)
- For `createAndDeposit`: `amount` must be > 0

## Rate Per Second (UD21x18)

The `UD21x18` type is an unsigned fixed-point number with 18 decimals, wrapping a `uint128`. Use the `ud21x18()` helper from PRBMath to construct values. See the main SKILL.md for the conversion formula.

**Example rates:**

| Desired Rate       | Calculation                 | `ratePerSecond` Value     |
| ------------------ | --------------------------- | ------------------------- |
| 1 token/second     | `1 * 1e18`                  | `1000000000000000000`     |
| 1,000 tokens/month | `1000 * 1e18 / 2_592_000`   | `≈ 385_802_469_135_802`   |
| 10,000 tokens/year | `10000 * 1e18 / 31_536_000` | `≈ 317_097_919_837_645`   |
| 100 tokens/day     | `100 * 1e18 / 86_400`       | `≈ 1_157_407_407_407_407` |

## What Happens on Create

1. Stream struct is written with the provided parameters
2. An ERC-721 NFT is minted to `recipient`
3. `streamId` is returned (auto-incrementing, starts at 1)
4. If `createAndDeposit`: tokens are transferred from `msg.sender` to the Flow contract
5. The stream starts accruing debt from `startTime` (or `block.timestamp` if `startTime` is 0 or in the past)

**Stream statuses after creation:**

- `startTime` in the future → `PENDING` (no debt accrues yet)
- `startTime` now or in the past → `STREAMING_SOLVENT` (if deposited) or `STREAMING_INSOLVENT` (if no deposit)

## Batch Creation

`SablierFlow` inherits `Batch`, which exposes a `payable` `batch()` function via `delegatecall`:

```solidity
function batch(bytes[] calldata calls) external payable returns (bytes[] memory results);
```

### Approach

1. Approve tokens to the Flow contract (total of all deposits across streams).
2. Encode each create call as calldata using `abi.encodeCall`.
3. Pass the array of encoded calls to `flow.batch{ value: totalFee }(calls)`.

### Example

```solidity
bytes[] memory calls = new bytes[](2);
calls[0] = abi.encodeCall(flow.create, (sender, recipient1, rate1, startTime, token, true));
calls[1] = abi.encodeCall(flow.createAndDeposit, (sender, recipient2, rate2, startTime, token, true, amount));

flow.batch{ value: totalFee }(calls);
```

You can mix `create` and `createAndDeposit` calls in the same batch. Include the total creation fee as `msg.value` (see the main SKILL.md for the per-stream fee amount). The contract handles per-stream fee accounting internally.
