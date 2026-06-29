# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-06-29

### Added
- GreenHat ERC-20 token contract (OZ ERC20 + Ownable)
- Anti-whale limits: max wallet (2%) and max transaction (1%)
- Blacklist and trading pause for emergency control
- DEX pair exclusion from limits
- Full test suite: 26 tests (unit + fuzz)
- Foundry multi-profile config (default / ci / production)
- OpenZeppelin Contracts v5 dependency
- Slither + Solhint static analysis integration
- CI/CD with GitHub Actions (lint → build → test → coverage)
- Coverage reporting with Codecov integration
- Multi-chain deployment support (Makefile + .env.example)
- NatSpec documentation on all public interfaces
- Community files: CONTRIBUTING.md, SECURITY.md, PR/issue templates
- EditorConfig, solhint, slither config files
