// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract OnchainStrategies is ERC721 {
    struct BasicStrategy {
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint24 poolFee;
        uint256 allocation;
    }

    struct IntervalStrategy {
        uint256 interval;
        uint256 lastTimestamp;
    }

    struct FlatStrategy {
        address aggregator;
        int256 flat;
        int256 lastResponse;
    }

    struct PercentStrategy {
        address aggregator;
        int256 percent;
        int256 lastResponse;
    }

    mapping(uint256 => uint256) internal _strategiesTypes;

    mapping(uint256 => BasicStrategy) internal _basicStrategies;
    
    mapping(uint256 => IntervalStrategy) internal _intervalStrategies;
    mapping(uint256 => FlatStrategy) internal _flatStrategies;
    mapping(uint256 => PercentStrategy) internal _percentStrategies;

    mapping(uint256 => address) internal _approvers;

    uint256 internal _totalSupply;

    ISwapRouter public immutable SwapRouter;

    constructor(address uniswapSwapRouter) ERC721("Onchain Strategies", "OCS") {
        SwapRouter = ISwapRouter(uniswapSwapRouter);
    }

    function mint(uint256 strategyType, address recepient, bool approved, bytes memory data) external returns (uint256 tokenId) {
        tokenId = _totalSupply;

        _strategiesTypes[tokenId] = strategyType;

        if(strategyType == 0) {
            // Interval
            (_basicStrategies[tokenId], _intervalStrategies[tokenId]) = abi.decode(data, (BasicStrategy, IntervalStrategy));
        } else if(strategyType == 1) {
            // Flat
            // TODO
        } else if(strategyType == 2) {
            // Percent
            (_basicStrategies[tokenId], _percentStrategies[tokenId]) = abi.decode(data, (BasicStrategy, PercentStrategy));
            require(_percentStrategies[tokenId].percent != 0);
        }

        _safeMint(recepient, tokenId);
        _totalSupply++;

        if(recepient == msg.sender && approved) {
            _approvers[tokenId] = msg.sender;
        }
    }

    function checkStrategies(uint256 startId, uint256 length) external view returns (uint256[] memory) {
        uint256[] memory maxIds = new uint256[](length);         
        
        uint256 renewCount;
        for(uint256 i; i < length; i++) {
            if(_strategiesTypes[startId + i] == 0) {
                // Interval
                if(block.timestamp > _intervalStrategies[startId + i].lastTimestamp + _intervalStrategies[startId + i].interval) {
                    if(_approvers[startId + i] == ownerOf(startId + i) && 
                    _basicStrategies[startId + i].amount <= _basicStrategies[startId + i].allocation && 
                    _basicStrategies[startId + i].amount <= IERC20(_basicStrategies[startId + i].tokenIn).allowance(ownerOf(startId + i), address(this))) {
                        maxIds[renewCount] = startId + i;
                        renewCount++;
                    }
                }
            } else if(_strategiesTypes[startId + i] == 1) {
                // Flat
                // TODO
            } else if(_strategiesTypes[startId + i] == 2) {
                // Percent
                // TODO: More complex signed math
                (,int256 response,,,) = AggregatorV3Interface(_percentStrategies[startId + i].aggregator).latestRoundData();
                int256 change = (((response - _percentStrategies[startId + i].lastResponse) * 100000) / _percentStrategies[startId + i].lastResponse);
                if(_percentStrategies[startId + i].percent < 0) {
                    // Response decreases
                    if(change <= _percentStrategies[startId + i].percent) {
                        maxIds[renewCount] = startId + i;
                        renewCount++;
                    }
                } else {
                    // Response increases
                    if(change >= _percentStrategies[startId + i].percent) {
                        maxIds[renewCount] = startId + i;
                        renewCount++;
                    }
                }
            }
        }

        if(renewCount == length) {
            return maxIds;
        }

        uint256[] memory adjustedIds = new uint256[](renewCount);
        for(uint256 i; i < renewCount; i++) {
            adjustedIds[i] = maxIds[i];
        }

        return adjustedIds;
    }

    function upkeepStrategies(uint256[] memory ids) external {
        for(uint256 i; i < ids.length; i++) {
            require(_basicStrategies[ids[i]].allocation >= _basicStrategies[ids[i]].amount);
            require(_approvers[ids[i]] == ownerOf(ids[i]));

            if(_strategiesTypes[ids[i]] == 0) {
                // Interval
                require(block.timestamp > _intervalStrategies[ids[i]].lastTimestamp + _intervalStrategies[ids[i]].interval);

                _intervalStrategies[ids[i]].lastTimestamp = block.timestamp;
            } else if(_strategiesTypes[ids[i]] == 1) {
                // Flat
                // TODO
            } else if(_strategiesTypes[ids[i]] == 2) {
                // Percent
                (,int256 response,,,) = AggregatorV3Interface(_percentStrategies[ids[i]].aggregator).latestRoundData();
                int256 change = (((response - _percentStrategies[ids[i]].lastResponse) * 100000) / _percentStrategies[ids[i]].lastResponse);
                if(_percentStrategies[ids[i]].percent < 0) {
                    // Response decreases
                    require(change <= _percentStrategies[ids[i]].percent);
                } else {
                    // Response increases
                    require(change >= _percentStrategies[ids[i]].percent);
                }

                _percentStrategies[ids[i]].lastResponse = response;
            }

            _basicStrategies[ids[i]].allocation -= _basicStrategies[ids[i]].amount;

            IERC20 token = IERC20(_basicStrategies[ids[i]].tokenIn);
            token.transferFrom(ownerOf(ids[i]), address(this), _basicStrategies[ids[i]].amount);
            token.approve(address(SwapRouter), _basicStrategies[ids[i]].amount);
            
            ISwapRouter.ExactInputSingleParams memory swapParams = 
                ISwapRouter.ExactInputSingleParams({
                    tokenIn:  _basicStrategies[ids[i]].tokenIn,
                    tokenOut:  _basicStrategies[ids[i]].tokenOut,
                    fee: _basicStrategies[ids[i]].poolFee,
                    recipient: ownerOf(ids[i]),
                    deadline: block.timestamp,
                    amountIn: _basicStrategies[ids[i]].amount,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
            });

            SwapRouter.exactInputSingle(swapParams);
        }
    }

    function _beforeTokenTransfer(address /* from */, address /* to */, uint256 tokenId) internal virtual override {
        _approvers[tokenId] = address(0);
    }
}