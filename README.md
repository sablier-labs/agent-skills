# agent-skills

A collection of agent skills for AI coding assistants, compatible with the Vercel skills CLI.

## Skills

### Sablier

| Skill              | Description                                                                    |
| ------------------ | ------------------------------------------------------------------------------ |
| `sablier-design`   | Sablier dark-theme aesthetic and production-grade React interfaces             |
| `sablier-protocol` | Sablier protocol overview: token vesting, airdrops, and onchain payroll        |
| `sablier-writing`  | Content creation with Sablier brand voice: blog posts, case studies, X/Twitter |

### Development

| Skill                  | Description                                                       |
| ---------------------- | ----------------------------------------------------------------- |
| `effect-ts`            | Effect-TS functional programming patterns and Next.js integration |
| `spec-from-screenshot` | Analyze screenshots and generate implementation specs             |
| `tailwind-css`         | Tailwind CSS v4 rules and tailwind-variants                       |
| `vitest`               | Vitest v4 testing patterns for TypeScript React/Next.js           |
| `xstate-react`         | XState v5 + React integration patterns                            |
| `zustand`              | Zustand state management with TypeScript                          |

### Web3

| Skill                    | Description                                                                    |
| ------------------------ | ------------------------------------------------------------------------------ |
| `btt`                    | Bulloak tree specifications for smart contract integration tests               |
| `etherscan-api`          | Etherscan API V2 for blockchain queries                                        |
| `etherscan-verification` | Etherscan contract verification                                                |
| `evm-deployment`         | EVM smart contract deployment patterns                                         |
| `foundry`                | Foundry tests, fuzz tests, fork tests, invariant tests, and deployment scripts |
| `viem`                   | Viem TypeScript interface for Ethereum interactions                            |

## Installation

```bash
# Add all skills from this repository
npx skills add sablier-labs/agent-skills

# List available skills
npx skills list

# Find specific skills
npx skills find sablier
npx skills find testing
```

## Usage

Once installed, skills are automatically available to your AI assistant. Reference them by name in your prompts or let the assistant detect when a skill is relevant.

## License

MIT
