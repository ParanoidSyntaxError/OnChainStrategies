from scripts.env import env
from brownie import OnChainStrategies, OCSKeeper, ERC20, WETH9, accounts

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
        link = ERC20.at(env.link)
        return (deployer, ocs, keeper, weth, link)
    
    def setup_local_env():
        deployer = deploy.new_account()
        ocs = OnChainStrategies.deploy(env.swapRouter, {"from": deployer})
        keeper = OCSKeeper.deploy(ocs, {"from": deployer})
        weth = WETH9.deploy({"from": deployer})
        link = ERC20.deploy("Chainlink", "LINK", {"from": deployer})
        return (deployer, ocs, keeper, weth, link)

    def setup_onchainStrategies(deployer):
        return (OnChainStrategies.deploy(env.swapRouter, {"from": deployer}))