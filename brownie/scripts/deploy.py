from scripts.env import env
from brownie import OnChainStrategies, OCSKeeper, WETH9, accounts, interface

class deploy:
    accountNonce = 0

    def new_account():
        deploy.accountNonce += 1
        return accounts[deploy.accountNonce]        

    def setup_env():
        deployer = deploy.new_account()
        ocs = OnChainStrategies.deploy(env.swapRouter, {"from": deployer})
        keeper = OCSKeeper.deploy(ocs, {"from": deployer})
        weth = WETH9.at(env.weth)
        link = interface.IERC20(env.link)
        return (deployer, ocs, keeper, weth, link)      

    def setup_onchainStrategies(deployer):
        return (OnChainStrategies.deploy(env.swapRouter, {"from": deployer}))