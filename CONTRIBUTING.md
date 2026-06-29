# Contributing to GreenHat

Thanks for your interest in contributing! This document outlines the guidelines.

## Quick Start

```bash
# Clone & install
git clone https://github.com/GreenHat-Token/greenhat.git
cd greenhat
forge install

# Build & test
forge build
forge test -vvv

# Coverage
forge coverage --report summary
```

## Development Workflow

### 1. Branch Naming

| Prefix | Example | Purpose |
|--------|---------|---------|
| `feat/` | `feat/anti-bot` | New feature |
| `fix/` | `fix/wallet-limit` | Bug fix |
| `refactor/` | `refactor/ownable` | Code refactor |
| `docs/` | `docs/natspec` | Documentation |
| `test/` | `test/coverage` | Test improvements |
| `ci/` | `ci/slither` | CI/CD changes |

### 2. Before Committing

Always run the full check suite:

```bash
# 1. Format
forge fmt --check

# 2. Build
forge build --sizes

# 3. Test
forge test -vvv

# 4. Coverage
forge coverage --report summary

# 5. Static analysis (if installed)
slither . --config slither.config.json
```

### 3. Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <short description>

<optional body>
```

Examples:
- `feat: add max wallet limit`
- `fix: correct tax calculation on sell`
- `docs: add NatSpec to constructor`
- `test: add fuzz test for transferFrom`
- `ci: add slither workflow`

### 4. Pull Requests

- Create PRs against the `main` branch
- Link related issues
- Ensure CI passes (lint → build → test → coverage)
- Update documentation if needed

## Testing Guidelines

- **Unit tests**: Cover all public/external functions
- **Fuzz tests**: Cover edge cases with random inputs
- **Revert tests**: Test all error paths
- **Coverage target**: ≥95% lines for `src/`

## Security

- Report vulnerabilities to the security email (see `SECURITY.md`)
- Do not open public issues for security bugs
- All smart contract changes require Slither scan

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
