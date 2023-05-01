from brownie import OnChainStrategies, accounts

class deploy:
    accountNonce = 0

    def new_account():
        deploy.accountNonce += 1
        return accounts[deploy.accountNonce]        
    
    def setup_onchainStrategies(deployer, swapRouter):
        return (OnChainStrategies.deploy(swapRouter, {"from": deployer}))