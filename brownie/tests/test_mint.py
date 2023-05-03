from scripts.deploy import deploy
from scripts.env import env
from eth_abi import encode
import random

def test_mint_interval_maxes():
    (deployer, ocs, keeper, weth, link) = deploy.setup_env()

    interval = 2**256 - 1
    lastTimestamp = 2**256 - 1
    intervalData = "0x" + encode(['uint256','uint256'], [interval, lastTimestamp]).hex()
    
    amount = 2**256 - 1
    poolFee = 2**24 - 1
    allocation = 2**256 - 1

    ocs.mint(0, deployer, True, (weth, link, amount, poolFee, allocation), intervalData, {"from": deployer})

def test_mint_flat_maxes():
    (deployer, ocs, keeper, weth, link) = deploy.setup_env()

    aggregator = env.linkEthFeed
    flat = 2**128 - 1
    lastResponse = 2**128 - 1
    flatData = "0x" + encode(['address', 'int256','int256'], [aggregator, flat, lastResponse]).hex()
    
    amount = 2**256 - 1
    poolFee = 2**24 - 1
    allocation = 2**256 - 1

    ocs.mint(1, deployer, True, (weth, link, amount, poolFee, allocation), flatData, {"from": deployer})

def test_mint_percent_maxes():
    (deployer, ocs, keeper, weth, link) = deploy.setup_env()

    aggregator = env.linkEthFeed
    percent = 2**128 - 1
    lastResponse = 2**128 - 1
    percentData = "0x" + encode(['address', 'int256','int256'], [aggregator, percent, lastResponse]).hex()
    
    amount = 2**256 - 1
    poolFee = 2**24 - 1
    allocation = 2**256 - 1

    ocs.mint(2, deployer, True, (weth, link, amount, poolFee, allocation), percentData, {"from": deployer})

def test_mint_interval_fuzz():
    (deployer, ocs, keeper, weth, link) = deploy.setup_env()

    for i in range(10):
        interval = random.randint(1, 2**256)
        lastTimestamp = random.randint(1, 2**256)
        intervalData = "0x" + encode(['uint256','uint256'], [interval, lastTimestamp]).hex()
        
        amount = random.randint(1, 2**256)
        poolFee = random.randint(1, 2**24)
        allocation = random.randint(1, 2**256)

        ocs.mint(0, deployer, True, (weth, link, amount, poolFee, allocation), intervalData, {"from": deployer})

def test_mint_flat_fuzz():
    (deployer, ocs, keeper, weth, link) = deploy.setup_env()

    for i in range(10):
        aggregator = env.linkEthFeed
        flat = random.randint(-2**128, 2**128)
        lastResponse = random.randint(-2**128, 2**128)
        flatData = "0x" + encode(['address', 'int256','int256'], [aggregator, flat, lastResponse]).hex()
        
        amount = random.randint(1, 2**256)
        poolFee = random.randint(1, 2**24)
        allocation = random.randint(1, 2**256)

        ocs.mint(1, deployer, True, (weth, link, amount, poolFee, allocation), flatData, {"from": deployer})

def test_mint_percent_fuzz():
    (deployer, ocs, keeper, weth, link) = deploy.setup_env()

    for i in range(10):
        aggregator = env.linkEthFeed
        percent = random.randint(-2**128, 2**128)
        lastResponse = random.randint(-2**128, 2**128)
        percentData = "0x" + encode(['address', 'int256','int256'], [aggregator, percent, lastResponse]).hex()
        
        amount = random.randint(1, 2**256)
        poolFee = random.randint(1, 2**24)
        allocation = random.randint(1, 2**256)

        ocs.mint(2, deployer, True, (weth, link, amount, poolFee, allocation), percentData, {"from": deployer})

def test_total_supply():
    (deployer, ocs, keeper, weth, link) = deploy.setup_env()

    length = random.randint(1, 10)

    for i in range(length):
        interval = random.randint(1, 2**256)
        lastTimestamp = random.randint(1, 2**256)
        intervalData = "0x" + encode(['uint256','uint256'], [interval, lastTimestamp]).hex()
        
        amount = random.randint(1, 2**256)
        poolFee = random.randint(1, 2**24)
        allocation = random.randint(1, 2**256)

        ocs.mint(0, deployer, True, (weth, link, amount, poolFee, allocation), intervalData, {"from": deployer})

    assert ocs.totalSupply() == length