# Sablier Agents Skills

A collection of agent skills for AI coding assistants developed by Sablier Labs.

## Installation

```bash
# Add all skills from this repository
npx skills add sablier-labs/agent-skills

# Add a specific skill (e.g., effect-ts)
npx skills add sablier-labs/agent-skills -s effect-ts

# Add globally for all projects
npx skills add sablier-labs/agent-skills -s effect-ts -g

# Target a specific agent (claude-code, cursor, cline, codex, etc.)
npx skills add sablier-labs/agent-skills -s effect-ts -a claude-code

# List available skills before installing
npx skills add sablier-labs/agent-skills -l
```

## Skills

### Sablier

| Skill              | Description                                                                    |
| ------------------ | ------------------------------------------------------------------------------ |
| `sablier-design`   | Sablier dark-theme aesthetic and production-grade React interfaces             |
| `sablier-protocol` | Sablier protocol overview: token vesting, airdrops, and onchain payroll        |
| `sablier-icon`     | Recolor the Sablier icon SVG to any brand or hex color, with PNG/JPG export    |
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
| `etherscan-api`          | Etherscan API V2 for blockchain queries                                        |
| `etherscan-verification` | Etherscan contract verification                                                |
| `evm-deployment`         | EVM smart contract deployment patterns                                         |
| `web3-btt`               | Bulloak tree specifications for smart contract integration tests               |
| `web3-forge`             | Foundry tests, fuzz tests, fork tests, invariant tests, and deployment scripts |
| `web3-viem`              | Viem TypeScript interface for Ethereum interactions                            |

## Usage

Once installed, skills are automatically available to your AI assistant. Reference them by name in your prompts or let the assistant detect when a skill is relevant.

## License

MIT
