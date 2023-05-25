// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./interfaces/IOnChainStrategies.sol";

contract OnChainStrategies is ERC721, IOnChainStrategies {
    using Strings for uint256;

    mapping(uint256 => uint256) internal _strategiesTypes;

    mapping(uint256 => BaseStrategy) internal _bases;
    
    mapping(uint256 => Interval) internal _intervals;
    mapping(uint256 => AggregatorChange) internal _aggregatorChanges;

    mapping(uint256 => bool) internal _upkeepApproved;

    uint256 internal _totalSupply;

    ISwapRouter public immutable SwapRouter;

    constructor(address uniswapSwapRouter) ERC721("OnChain Strategies", "OCS") {
        SwapRouter = ISwapRouter(uniswapSwapRouter);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function mint(uint256 strategyType, address recepient, bool approved, BaseStrategy memory baseStrategy, bytes memory data) external override returns (uint256 tokenId) {
        tokenId = _totalSupply;

        _strategiesTypes[tokenId] = strategyType;
        _bases[tokenId] = baseStrategy;

        if(strategyType == 0) {
            // Interval
            _intervals[tokenId] = abi.decode(data, (Interval));
        } else if(strategyType == 1) {
            // Flat
            _aggregatorChanges[tokenId] = abi.decode(data, (AggregatorChange));
            require(_aggregatorChanges[tokenId].change != 0);
            require(_aggregatorChanges[tokenId].frequency > 0);
        } else if(strategyType == 2) {
            // Percent
            _aggregatorChanges[tokenId] = abi.decode(data, (AggregatorChange));
            require(_aggregatorChanges[tokenId].change != 0);
            require(_aggregatorChanges[tokenId].frequency > 0);
        }

        _safeMint(recepient, tokenId);
        _totalSupply++;

        if(recepient == msg.sender && approved) {
            _upkeepApproved[tokenId] = true;
        }
    }

    function burn(uint256 tokenId) external override {
        require(ownerOf(tokenId) == msg.sender);
        _burn(tokenId);
    }

    function setAllocation(uint256 tokenId, uint256 allocation) external override {
        require(ownerOf(tokenId) == msg.sender);
        _bases[tokenId].allocation = allocation;
    }

    function setUpkeepApproval(uint256 tokenId, bool approved) external override {
        require(ownerOf(tokenId) == msg.sender);
        _upkeepApproved[tokenId] = approved;
    }

    function checkStrategies(uint256 startId, uint256 length) external view override returns (uint256[] memory) {
        // TODO: Maybe adjust length instead of reverting
        require(_totalSupply <= startId + length);

        uint256[] memory maxIds = new uint256[](length);

        uint256 renewCount;
        for(uint256 i; i < length; i++) {
            uint256 id = startId + i;
            address owner = ownerOf(id);
            IERC20 tokenIn = IERC20(_bases[id].tokenIn);

            if(_upkeepApproved[id] == false || 
                _bases[id].amount > _bases[id].allocation || 
                _bases[id].amount > tokenIn.allowance(owner, address(this)) ||
                _bases[id].amount > tokenIn.balanceOf(owner)) {
                continue;
            }

            if(_strategiesTypes[id] == 0) {
                // Interval
                if(block.timestamp > _intervals[id].lastTimestamp + _intervals[id].interval) {
                    maxIds[renewCount] = id;
                    renewCount++;
                }
            } else if(_strategiesTypes[id] == 1) {
                // Flat
                (uint80 latestRoundId, int256 latestResponse,,,) = AggregatorV3Interface(_aggregatorChanges[id].aggregator).latestRoundData();
                int256 change;
                if(latestRoundId > _aggregatorChanges[id].lastRoundId + _aggregatorChanges[id].frequency) {
                    (,int256 previousResponse,,,) = AggregatorV3Interface(_aggregatorChanges[id].aggregator).getRoundData(latestRoundId - _aggregatorChanges[id].frequency);
                    change = _flatChange(latestResponse, previousResponse);
                } else {
                    (,int256 previousResponse,,,) = AggregatorV3Interface(_aggregatorChanges[id].aggregator).getRoundData(_aggregatorChanges[id].lastRoundId);
                    change = _flatChange(latestResponse, previousResponse);
                }

                if(_aggregatorChanges[id].change > 0) {
                    if(change >= _aggregatorChanges[id].change) {
                        maxIds[renewCount] = id;
                        renewCount++;
                    }
                } else {
                    if(change <= _aggregatorChanges[id].change) {
                        maxIds[renewCount] = id;
                        renewCount++;
                    }
                }
            } else if(_strategiesTypes[id] == 2) {
                // Percent
                (uint80 latestRoundId, int256 latestResponse,,,) = AggregatorV3Interface(_aggregatorChanges[id].aggregator).latestRoundData();
                int256 change;
                if(latestRoundId > _aggregatorChanges[id].lastRoundId + _aggregatorChanges[id].frequency) {
                    (,int256 previousResponse,,,) = AggregatorV3Interface(_aggregatorChanges[id].aggregator).getRoundData(latestRoundId - _aggregatorChanges[id].frequency);
                    change = _percentChange(latestResponse, previousResponse);
                } else {
                    (,int256 previousResponse,,,) = AggregatorV3Interface(_aggregatorChanges[id].aggregator).getRoundData(_aggregatorChanges[id].lastRoundId);
                    change = _percentChange(latestResponse, previousResponse);
                }

                if(_aggregatorChanges[id].change > 0) {
                    if(change >= _aggregatorChanges[id].change) {
                        maxIds[renewCount] = id;
                        renewCount++;
                    }
                } else {
                    if(change <= _aggregatorChanges[id].change) {
                        maxIds[renewCount] = id;
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

    function upkeepStrategies(uint256[] memory ids) external override {
        for(uint256 i; i < ids.length; i++) {
            require(_bases[ids[i]].allocation >= _bases[ids[i]].amount);
            require(_upkeepApproved[ids[i]]);

            if(_strategiesTypes[ids[i]] == 0) {
                // Interval
                require(block.timestamp > _intervals[ids[i]].lastTimestamp + _intervals[ids[i]].interval);

                _intervals[ids[i]].lastTimestamp = block.timestamp;
            } else if(_strategiesTypes[ids[i]] == 1) {
                // Flat
                (uint80 latestRoundId, int256 latestResponse,,,) = AggregatorV3Interface(_aggregatorChanges[ids[i]].aggregator).latestRoundData();
                int256 change;
                if(latestRoundId > _aggregatorChanges[ids[i]].lastRoundId + _aggregatorChanges[ids[i]].frequency) {
                    (,int256 previousResponse,,,) = AggregatorV3Interface(_aggregatorChanges[ids[i]].aggregator).getRoundData(latestRoundId - _aggregatorChanges[ids[i]].frequency);
                    change = _flatChange(latestResponse, previousResponse);
                } else {
                    (,int256 previousResponse,,,) = AggregatorV3Interface(_aggregatorChanges[ids[i]].aggregator).getRoundData(_aggregatorChanges[ids[i]].lastRoundId);
                    change = _flatChange(latestResponse, previousResponse);
                }

                if(_aggregatorChanges[ids[i]].change > 0) {
                    require(change >= _aggregatorChanges[ids[i]].change);
                } else {
                    require(change <= _aggregatorChanges[ids[i]].change);
                }

                _aggregatorChanges[ids[i]].lastRoundId = latestRoundId;
            } else if(_strategiesTypes[ids[i]] == 2) {
                // Percent
                (uint80 latestRoundId, int256 latestResponse,,,) = AggregatorV3Interface(_aggregatorChanges[ids[i]].aggregator).latestRoundData();
                int256 change;
                if(latestRoundId > _aggregatorChanges[ids[i]].lastRoundId + _aggregatorChanges[ids[i]].frequency) {
                    (,int256 previousResponse,,,) = AggregatorV3Interface(_aggregatorChanges[ids[i]].aggregator).getRoundData(latestRoundId - _aggregatorChanges[ids[i]].frequency);
                    change = _percentChange(latestResponse, previousResponse);
                } else {
                    (,int256 previousResponse,,,) = AggregatorV3Interface(_aggregatorChanges[ids[i]].aggregator).getRoundData(_aggregatorChanges[ids[i]].lastRoundId);
                    change = _percentChange(latestResponse, previousResponse);
                }

                if(_aggregatorChanges[ids[i]].change > 0) {
                    require(change >= _aggregatorChanges[ids[i]].change);
                } else {
                    require(change <= _aggregatorChanges[ids[i]].change);
                }

                _aggregatorChanges[ids[i]].lastRoundId = latestRoundId;
            }

            _bases[ids[i]].allocation -= _bases[ids[i]].amount;

            IERC20 token = IERC20(_bases[ids[i]].tokenIn);
            token.transferFrom(ownerOf(ids[i]), address(this), _bases[ids[i]].amount);
            token.approve(address(SwapRouter), _bases[ids[i]].amount);
            
            ISwapRouter.ExactInputSingleParams memory swapParams = 
                ISwapRouter.ExactInputSingleParams({
                    tokenIn:  _bases[ids[i]].tokenIn,
                    tokenOut:  _bases[ids[i]].tokenOut,
                    fee: _bases[ids[i]].poolFee,
                    recipient: ownerOf(ids[i]),
                    deadline: block.timestamp,
                    amountIn: _bases[ids[i]].amount,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
            });

            SwapRouter.exactInputSingle(swapParams);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(string(
                abi.encodePacked(
                    '{"name": "OnChain Strategy #',
                    tokenId.toString(),
                    '", "description": "',
                    "Complex investment strategies without losing custody of your tokens.", 
                    '", "image": "data:image/svg+xml;base64,',
                    Base64.encode(bytes(_svgImage(tokenId))),
                    '", "attributes":',
                    //_hashMetadata(hash, id),
                    '""',
                    "}"
                )
            )))
        ));
    }

    function _beforeTokenTransfer(address /* from */, address /* to */, uint256 tokenId) internal virtual override {
        _upkeepApproved[tokenId] = false;
    }

    function _abs(int256 value) internal pure returns (int256) {
        return value >= 0 ? value : -value;
    }

    function _percentChange(int256 a, int256 b) internal pure returns (int256) {
        // TODO: More complex signed math
        // 10000 = 100%
        return (-(b - a) * 10000) / b;
    }

    function _flatChange(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    function _svgImage(uint256 tokenId) internal view returns (string memory) {
        string memory name;
        string memory value;

        if(_strategiesTypes[tokenId] == 0) {
            // Interval
            name = "Interval Strategy";
            value = string(abi.encodePacked(_intervals[tokenId].interval.toString(), "s"));
        } else if(_strategiesTypes[tokenId] == 1) {
            // Flat
            name = "Flat Strategy";
            value = uint256(_abs(_aggregatorChanges[tokenId].change)).toString();
            if(_aggregatorChanges[tokenId].change < 0) {
                value = string(abi.encodePacked("-", value));
            }
        } else if(_strategiesTypes[tokenId] == 2) {
            // Percent
            name = "Percentage Strategy";
            int256 prefix = _aggregatorChanges[tokenId].change / 100;
            uint256 suffix = uint256(_abs(_aggregatorChanges[tokenId].change % 100));

            string memory mid = ".";
            if(suffix < 10) {   
                mid = string(abi.encodePacked(mid, "0"));
            }

            value = string(abi.encodePacked(uint256(_abs(prefix)).toString(), mid, suffix.toString()));

            if(prefix < 0) {
                value = string(abi.encodePacked("-", value));
            }
            value = string(abi.encodePacked(value, "%"));
        }

        return string(abi.encodePacked(
            "<svg viewBox='0 0 160 240' preserveAspectRatio='xMinYMin meet' id='doc' xmlns='http://www.w3.org/2000/svg'><style>#doc { shape-rendering: crispedges; }.name { font: bold 12px monospace; fill: white; }.value { font: italic 16px monospace; fill: white; }.title { font: 12px monospace; fill: white; }</style><rect width='100%' height='100%' fill='black'/><text x='20' y='50' class='name'>",
            name,
            "</text><text x='20' y='80' class='value'>",
            value,
            "</text><text x='20' y='220' class='title'>OnChain Strategies</text></svg>"
        ));
    }
}