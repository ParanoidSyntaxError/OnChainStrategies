from brownie.network.state import Chain

# Polygon Mumbai
# Uniswap V3 Swap Router: 0xE592427A0AEce92De3Edee1F18E0157C05861564

class env:
    chain = Chain()

    swapRouter = "0xE592427A0AEce92De3Edee1F18E0157C05861564"
    usdc = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
    link = "0xb0897686c545045aFc77CF20eC7A532E3120E0F1"
    linkUsdFeed = "0xd9FFdb71EbE7496cC440152d43986Aae0AB76665"