from scripts.env import env
from brownie import OnChainStrategies, OCSKeeper, accounts

class deploy:
    accountNonce = 0

    def new_account():
        deploy.accountNonce += 1
        return accounts[deploy.accountNonce]        

    def setup_env():
        deployer = deploy.new_account()
        ocs = OnChainStrategies.deploy(env.swapRouter, {"from": deployer})
        keeper = OCSKeeper.deploy(ocs, {"from": deployer})
        return (deployer, ocs, keeper)       

    def setup_onchainStrategies(deployer):
        return (OnChainStrategies.deploy(env.swapRouter, {"from": deployer}))