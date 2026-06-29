# GreenHat 🧢 Makefile
# Usage:
#   make test        — Run tests
#   make coverage    — Coverage report
#   make lint        — Solhint check
#   make slither     — Static analysis
#   make deploy-sepolia   — Deploy to Sepolia
#   make deploy-base-sepolia — Deploy to Base Sepolia
#   make deploy-mainnet   — Deploy to Ethereum mainnet
#   make deploy-base      — Deploy to Base mainnet
#   make deploy-bnb       — Deploy to BNB Chain
#   make verify           — Verify deployed contract

.PHONY: test coverage lint slither clean

# ─── Default ────────────────────────────────────────────────────
.DEFAULT_GOAL := test

# ─── Env ─────────────────────────────────────────────────────────
include .env
export

# ─── Build & Test ────────────────────────────────────────────────

build:
	forge build --sizes

test: build
	forge test -vvv

test-gas:
	forge test --gas-report

coverage:
	forge coverage --report summary
	forge coverage --report lcov

# ─── Code Quality ────────────────────────────────────────────────

lint:
	bunx solhint -c .solhint.json "src/**/*.sol"

slither:
	slither . --config slither.config.json

fmt:
	forge fmt

fmt-check:
	forge fmt --check

# ─── Clean ───────────────────────────────────────────────────────

clean:
	forge clean
	rm -rf coverage/ lcov.info

# ─── Deploy: Testnets ────────────────────────────────────────────

deploy-sepolia: build
	forge script script/GreenHat.s.sol:GreenHatScript \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--private-key $(DEPLOYER_PRIVATE_KEY) \
		--broadcast --verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		--delay 10 \
		--retries 3

deploy-base-sepolia: build
	forge script script/GreenHat.s.sol:GreenHatScript \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) \
		--private-key $(DEPLOYER_PRIVATE_KEY) \
		--broadcast --verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		--delay 10 \
		--retries 3

# ─── Deploy: Mainnets ────────────────────────────────────────────

deploy-mainnet: build
	forge script script/GreenHat.s.sol:GreenHatScript \
		--rpc-url $(MAINNET_RPC_URL) \
		--private-key $(DEPLOYER_PRIVATE_KEY) \
		--broadcast --verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		--delay 10 \
		--retries 3

deploy-base: build
	forge script script/GreenHat.s.sol:GreenHatScript \
		--rpc-url $(BASE_RPC_URL) \
		--private-key $(DEPLOYER_PRIVATE_KEY) \
		--broadcast --verify \
		--etherscan-api-key $(BASE_SCAN_API_KEY) \
		--delay 10 \
		--retries 3

deploy-bnb: build
	forge script script/GreenHat.s.sol:GreenHatScript \
		--rpc-url $(BNB_RPC_URL) \
		--private-key $(DEPLOYER_PRIVATE_KEY) \
		--broadcast --verify \
		--etherscan-api-key $(BSC_SCAN_API_KEY) \
		--delay 10 \
		--retries 3
