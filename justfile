set allow-duplicate-variables
set allow-duplicate-recipes
set shell := ["bash", "-euo", "pipefail", "-c"]
set unstable

# Show available commands
default:
    @just --list

# Install dependencies
install-deps:
    just install-uv
    just install-mdformat
alias id := install-deps

# Install mdformat
install-mdformat:
    uv tool install mdformat --with mdformat-frontmatter --with mdformat-gfm
alias im := install-mdformat

# Install uv on macOS and Linux
install-uv:
    curl -LsSf https://astral.sh/uv/install.sh | sh
alias iu := install-uv

# Check mdformat formatting
@mdformat-check +paths=".":
    mdformat --check {{ paths }}
alias mc := mdformat-check

# Format using mdformat
@mdformat-write +paths=".":
    mdformat {{ paths }}
alias mw := mdformat-write
