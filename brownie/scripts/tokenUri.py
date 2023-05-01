from scripts.deploy import deploy
from eth_abi import encode, decode

def main():
    deployer = deploy.new_account()
    ocs = deploy.setup_onchainStrategies(deployer, "0x0000000000000000000000000000000000000000")

    intervalData = "0x" + encode(['uint256','uint256'], [777, 100]).hex()
    ocs.mint(0, deployer, True, ("0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", 1, 1, 1), intervalData, {"from": deployer})

    print(ocs.tokenURI(0))

    percentData = "0x" + encode(['address', 'int256', 'int256'], ["0x0000000000000000000000000000000000000000", -5110, 0]).hex()
    ocs.mint(2, deployer, True, ("0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", 1, 1, 1), percentData, {"from": deployer})

    print(ocs.tokenURI(1))