install:
	forge install
build:
	forge build
lint:
	solhint ./contracts/**.sol
test:
	forge test -vvvv
gas-report:
	forge test -v --gas-report
gas:
	./marginGas
doc:
	rm -rf docs
	yarn docgen
	python docs.py
depoly:
	goerli:
		npx hardhat --network goerli deploy
	goerli:
		npx hardhat --network eth deploy