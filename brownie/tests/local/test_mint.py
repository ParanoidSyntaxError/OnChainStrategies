from scripts.deploy import deploy
from scripts.env import env
from eth_abi import encode
import random

def test_mint_interval_edges():
    (deployer, ocs, keeper, weth, link) = deploy.setup_local_env()

    intervalMin = 1
    intervalMax = 2**256 - 1

    lastTimestampMin = 0
    lastTimestampMax = 2**256 - 1

    intervalDataMin = "0x" + encode(['uint256','uint256'], [intervalMin, lastTimestampMin]).hex()
    intervalDataMax = "0x" + encode(['uint256','uint256'], [intervalMax, lastTimestampMax]).hex()
    
    amountMin = 0
    amountMax = 2**256 - 1

    poolFeeMin = 0
    poolFeeMax = 2**24 - 1

    allocationMin = 0
    allocationMax = 2**256 - 1

    ocs.mint(0, deployer, True, (weth, link, amountMin, poolFeeMin, allocationMin), intervalDataMin, {"from": deployer})
    ocs.mint(0, deployer, True, (weth, link, amountMax, poolFeeMax, allocationMax), intervalDataMax, {"from": deployer})

def test_mint_flat_edges():
    (deployer, ocs, keeper, weth, link) = deploy.setup_local_env()

    aggregator = env.linkEthFeed
    
    changeMin = -(2**128) + 1
    changeMax = 2**128 - 1
        
    lastRoundIdMin = 0
    lastRoundIdMax = 2**80 - 1
    
    frequencyMin = 1
    frequencyMax = 2**80 - 1

    flatDataMin = "0x" + encode(['address', 'int256','uint80','uint80'], [aggregator, changeMin, lastRoundIdMin, frequencyMin]).hex()
    flatDataMax = "0x" + encode(['address', 'int256','uint80','uint80'], [aggregator, changeMax, lastRoundIdMax, frequencyMax]).hex()

    amountMin = 0
    amountMax = 2**256 - 1

    poolFeeMin = 0
    poolFeeMax = 2**24 - 1

    allocationMin = 0
    allocationMax = 2**256 - 1

    ocs.mint(1, deployer, True, (weth, link, amountMin, poolFeeMin, allocationMin), flatDataMin, {"from": deployer})
    ocs.mint(1, deployer, True, (weth, link, amountMax, poolFeeMax, allocationMax), flatDataMax, {"from": deployer})

def test_mint_percent_edges():
    (deployer, ocs, keeper, weth, link) = deploy.setup_local_env()

    aggregator = env.linkEthFeed
    
    changeMin = -(2**128) + 1
    changeMax = 2**128 - 1
        
    lastRoundIdMin = 0
    lastRoundIdMax = 2**80 - 1
    
    frequencyMin = 1
    frequencyMax = 2**80 - 1

    percentDataMin = "0x" + encode(['address', 'int256','uint80','uint80'], [aggregator, changeMin, lastRoundIdMin, frequencyMin]).hex()
    percentDataMax = "0x" + encode(['address', 'int256','uint80','uint80'], [aggregator, changeMax, lastRoundIdMax, frequencyMax]).hex()

    amountMin = 0
    amountMax = 2**256 - 1

    poolFeeMin = 0
    poolFeeMax = 2**24 - 1

    allocationMin = 0
    allocationMax = 2**256 - 1

    ocs.mint(2, deployer, True, (weth, link, amountMin, poolFeeMin, allocationMin), percentDataMin, {"from": deployer})
    ocs.mint(2, deployer, True, (weth, link, amountMax, poolFeeMax, allocationMax), percentDataMax, {"from": deployer})

def test_mint_interval_fuzz():
    (deployer, ocs, keeper, weth, link) = deploy.setup_local_env()

    for i in range(100):
        interval = random.randint(1, 2**256)
        lastTimestamp = random.randint(0, 2**256)

        intervalData = "0x" + encode(['uint256','uint256'], [interval, lastTimestamp]).hex()
        
        amount = random.randint(0, 2**256)
        poolFee = random.randint(0, 2**24)
        allocation = random.randint(0, 2**256)

        ocs.mint(0, deployer, True, (weth, link, amount, poolFee, allocation), intervalData, {"from": deployer})

def test_mint_flat_fuzz():
    (deployer, ocs, keeper, weth, link) = deploy.setup_local_env()

    for i in range(100):
        aggregator = env.linkEthFeed
        change = random.randint(-(2**128) + 1, 2**128)
        lastRoundId = random.randint(0, 2**80)
        frequency = random.randint(1, 2**80)
        flatData = "0x" + encode(['address', 'int256','uint80','uint80'], [aggregator, change, lastRoundId, frequency]).hex()
        
        amount = random.randint(1, 2**256)
        poolFee = random.randint(1, 2**24)
        allocation = random.randint(1, 2**256)

        ocs.mint(1, deployer, True, (weth, link, amount, poolFee, allocation), flatData, {"from": deployer})

def test_mint_percent_fuzz():
    (deployer, ocs, keeper, weth, link) = deploy.setup_local_env()

    for i in range(100):
        aggregator = env.linkEthFeed
        change = random.randint(-(2**128) + 1, 2**128)
        lastRoundId = random.randint(0, 2**80)
        frequency = random.randint(1, 2**80)
        percentData = "0x" + encode(['address', 'int256','uint80','uint80'], [aggregator, change, lastRoundId, frequency]).hex()
        
        amount = random.randint(1, 2**256)
        poolFee = random.randint(1, 2**24)
        allocation = random.randint(1, 2**256)

        ocs.mint(2, deployer, True, (weth, link, amount, poolFee, allocation), percentData, {"from": deployer})

def test_total_supply():
    (deployer, ocs, keeper, weth, link) = deploy.setup_local_env()

    length = random.randint(1, 100)

    for i in range(length):
        interval = random.randint(1, 2**256)
        lastTimestamp = random.randint(1, 2**256)
        intervalData = "0x" + encode(['uint256','uint256'], [interval, lastTimestamp]).hex()
        
        amount = random.randint(1, 2**256)
        poolFee = random.randint(1, 2**24)
        allocation = random.randint(1, 2**256)

        ocs.mint(0, deployer, True, (weth, link, amount, poolFee, allocation), intervalData, {"from": deployer})

    assert ocs.totalSupply() == length