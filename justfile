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

# Commit, sync skills to ~/.agents, commit again
[group("sync")]
[script("zsh")]
[doc("Commit here, install skills in ~/.agents, commit there")]
sync:
    source ~/.zshrc 2>/dev/null

    # Commit in agent-skills repo
    ccc

    # Switch to ~/.agents
    cd ~/.agents
    echo "📂 Changed directory to ~/.agents"

    # Commit uncommitted changes if any
    if [[ -n "$(git status --porcelain)" ]]; then
        ccc
    fi

    # Install skills from agent-skills repo
    just install-all sablier-labs/agent-skills

    # Commit the installed skills
    ccc
alias s := sync

# Check mdformat formatting
@mdformat-check +paths=".":
    mdformat --check {{ paths }}
alias mc := mdformat-check

# Format using mdformat
@mdformat-write +paths=".":
    mdformat {{ paths }}
alias mw := mdformat-write
