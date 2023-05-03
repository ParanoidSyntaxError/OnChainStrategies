from brownie.network.state import Chain

# ETH Mainnet
# Uniswap V3 Swap Router: 0xE592427A0AEce92De3Edee1F18E0157C05861564

class env:
    chain = Chain()

    swapRouter = "0xE592427A0AEce92De3Edee1F18E0157C05861564"
    weth = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    link = "0x514910771AF9Ca656af840dff83E8264EcF986CA"
    linkEthFeed = "0xdc530d9457755926550b59e8eccdae7624181557"