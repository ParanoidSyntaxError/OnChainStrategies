from scripts.deploy import deploy
from scripts.env import env
from eth_abi import encode, decode
import random

def test_upkeep_interval():
    (deployer, ocs, keeper, weth, link) = deploy.setup_env()

    weth.deposit({"from": deployer, "value": 10**18})
    weth.approve(ocs, 10**18, {"from": deployer})

    length = random.randint(1, 5)
    totalAmount = 0

    for i in range(length):
        interval = random.randint(120, 240)
        lastTimestamp = env.chain[-1].timestamp
        intervalData = "0x" + encode(['uint256','uint256'], [interval, lastTimestamp]).hex()
        
        amount = random.randint(1, 10)
        poolFee = 3000
        allocation = random.randint(100, 1000)

        totalAmount += amount

        ocs.mint(0, deployer, True, (weth, env.link, amount, poolFee, allocation), intervalData, {"from": deployer})

    checkParams = "0x" + encode(['uint256'], [length]).hex()
    checkReturn = keeper.checkUpkeep(checkParams)
    assert checkReturn[0] == False

    assert link.balanceOf(deployer) == 0

    env.chain.sleep(360)
    env.chain.mine()

    checkReturn = keeper.checkUpkeep(checkParams)
    upkeepIds = decode(['uint256[]'], checkReturn[1])[0]
    assert checkReturn[0] == True
    assert len(upkeepIds) == length

    performParams = "0x" + encode(['uint256[]'], [upkeepIds]).hex()
    keeper.performUpkeep(performParams, {"from": deployer})

    assert weth.balanceOf(deployer) == 10**18 - totalAmount
    assert link.balanceOf(deployer) > 0

def test_checkUpkeep_flat():
    (deployer, ocs, keeper, weth, link) = deploy.setup_env()

    weth.deposit({"from": deployer, "value": 10**18})
    weth.approve(ocs, 10**18, {"from": deployer})

    length = random.randint(1, 5)
    totalAmount = 0

    for i in range(length):
        aggregator = env.linkEthFeed
        flat = -10
        lastResponse = 10**18
        flatData = "0x" + encode(['address', 'int256','int256'], [aggregator, flat, lastResponse]).hex()
        
        amount = random.randint(1, 10)
        poolFee = 3000
        allocation = random.randint(100, 1000)

        totalAmount += amount

        ocs.mint(1, deployer, True, (weth, env.link, amount, poolFee, allocation), flatData, {"from": deployer})

    assert link.balanceOf(deployer) == 0

    checkParams = "0x" + encode(['uint256'], [length]).hex()
    checkReturn = keeper.checkUpkeep(checkParams)
    upkeepIds = decode(['uint256[]'], checkReturn[1])[0]
    assert checkReturn[0] == True
    assert len(upkeepIds) == length

    performParams = "0x" + encode(['uint256[]'], [upkeepIds]).hex()
    keeper.performUpkeep(performParams, {"from": deployer})

    assert weth.balanceOf(deployer) == 10**18 - totalAmount
    assert link.balanceOf(deployer) > 0

def test_checkUpkeep_percent():
    (deployer, ocs, keeper, weth, link) = deploy.setup_env()

    weth.deposit({"from": deployer, "value": 10**18})
    weth.approve(ocs, 10**18, {"from": deployer})

    length = random.randint(1, 5)
    totalAmount = 0

    for i in range(length):
        aggregator = env.linkEthFeed
        percent = -10
        lastResponse = 10**18
        percentData = "0x" + encode(['address', 'int256','int256'], [aggregator, percent, lastResponse]).hex()
        
        amount = random.randint(1, 10)
        poolFee = 3000
        allocation = random.randint(100, 1000)

        totalAmount += amount

        ocs.mint(2, deployer, True, (weth, env.link, amount, poolFee, allocation), percentData, {"from": deployer})

        assert link.balanceOf(deployer) == 0

    checkParams = "0x" + encode(['uint256'], [length]).hex()
    checkReturn = keeper.checkUpkeep(checkParams)
    upkeepIds = decode(['uint256[]'], checkReturn[1])[0]
    assert checkReturn[0] == True
    assert len(upkeepIds) == length

    performParams = "0x" + encode(['uint256[]'], [upkeepIds]).hex()
    keeper.performUpkeep(performParams, {"from": deployer})

    assert weth.balanceOf(deployer) == 10**18 - totalAmount
    assert link.balanceOf(deployer) > 0