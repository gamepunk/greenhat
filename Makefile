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
-include .env
export

# ─── Build & Test ────────────────────────────────────────────────

build:
	FOUNDRY_PROFILE=ci forge build --sizes

build-production:
	FOUNDRY_PROFILE=production forge build --sizes

test:
	FOUNDRY_PROFILE=ci forge test -vvv

test-gas:
	FOUNDRY_PROFILE=ci forge test --gas-report

gas-snapshot:
	FOUNDRY_PROFILE=ci forge snapshot

gas-check:
	FOUNDRY_PROFILE=ci forge snapshot --check

coverage:
	FOUNDRY_PROFILE=ci forge coverage --report summary
	FOUNDRY_PROFILE=ci forge coverage --report lcov

# ─── Code Quality ────────────────────────────────────────────────

lint:
	bunx solhint -c .solhint.json "src/**/*.sol"

slither:
	slither . --config slither.config.json

fmt:
	forge fmt

fmt-check:
	forge fmt --check

# ─── Docs ─────────────────────────────────────────────────────────

docs:
	forge doc -b

docs-serve:
	forge doc -b -s

# ─── Clean ───────────────────────────────────────────────────────

clean:
	forge clean
	rm -rf coverage/ lcov.info docs/book/ docs/src/

# ─── Deploy: Testnets ────────────────────────────────────────────

deploy-sepolia: build-production
	FOUNDRY_PROFILE=production forge script script/GreenHat.s.sol:GreenHatScript \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--private-key $(DEPLOYER_PRIVATE_KEY) \
		--broadcast --verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		--delay 10 \
		--retries 3

deploy-base-sepolia: build-production
	FOUNDRY_PROFILE=production forge script script/GreenHat.s.sol:GreenHatScript \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) \
		--private-key $(DEPLOYER_PRIVATE_KEY) \
		--broadcast --verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		--delay 10 \
		--retries 3

# ─── Deploy: Mainnets ────────────────────────────────────────────

deploy-mainnet: build-production
	FOUNDRY_PROFILE=production forge script script/GreenHat.s.sol:GreenHatScript \
		--rpc-url $(MAINNET_RPC_URL) \
		--private-key $(DEPLOYER_PRIVATE_KEY) \
		--broadcast --verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		--delay 10 \
		--retries 3

deploy-base: build-production
	FOUNDRY_PROFILE=production forge script script/GreenHat.s.sol:GreenHatScript \
		--rpc-url $(BASE_RPC_URL) \
		--private-key $(DEPLOYER_PRIVATE_KEY) \
		--broadcast --verify \
		--etherscan-api-key $(BASE_SCAN_API_KEY) \
		--delay 10 \
		--retries 3

deploy-bnb: build-production
	FOUNDRY_PROFILE=production forge script script/GreenHat.s.sol:GreenHatScript \
		--rpc-url $(BNB_RPC_URL) \
		--private-key $(DEPLOYER_PRIVATE_KEY) \
		--broadcast --verify \
		--etherscan-api-key $(BSC_SCAN_API_KEY) \
		--delay 10 \
		--retries 3
