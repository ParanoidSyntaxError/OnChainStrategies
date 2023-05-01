from scripts.deploy import deploy
from scripts.env import env
from eth_abi import encode
import random


def test_checkUpkeep_interval():
    (deployer, ocs, keeper) = deploy.setup_env()

    length = random.randint(1, 5)

    for i in range(length):
        interval = random.randint(1, 60)
        lastTimestamp = env.chain[-1].timestamp
        intervalData = "0x" + encode(['uint256','uint256'], [interval, lastTimestamp]).hex()
        
        amount = random.randint(1, 10)
        poolFee = 3000
        allocation = random.randint(100, 1000)

        ocs.mint(0, deployer, True, (env.usdc, env.link, amount, poolFee, allocation), intervalData, {"from": deployer})

def test_checkUpkeep_flat():
    (deployer, ocs, keeper) = deploy.setup_env()

def test_checkUpkeep_percent():
    (deployer, ocs, keeper) = deploy.setup_env()
