-include .env

.PHONY: all test clean deploy-anvil

# Default network
network ?= anvil

help:
	@echo "Usage:"
	@echo "  make deploy-anvil  - Deploy contracts to local Anvil network"
	@echo "  make test         - Run forge tests"
	@echo "  make clean        - Remove build artifacts"

# Start local Anvil network
anvil:
	@echo "Starting Anvil..."
	@anvil --chain-id 1337

# Build contracts
build:
	@echo "Building contracts..."
	@forge build

# Run tests
test:
	@echo "Running tests..."
	@forge test -vv

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@forge clean

# Deploy to Anvil
deploy-anvil:
	@echo "Deploying to Anvil..."
	@forge script script/Deploy.s.sol:DeployScript --rpc-url $(ANVIL_RPC_URL) \
		--private-key $(DEPLOYER_PRIVATE_KEY) \
		--broadcast \
		-vvv
