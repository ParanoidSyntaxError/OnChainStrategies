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

    mapping(uint256 => BasicStrategy) internal _basicStrategies;
    
    mapping(uint256 => IntervalStrategy) internal _intervalStrategies;
    mapping(uint256 => FlatStrategy) internal _flatStrategies;
    mapping(uint256 => PercentStrategy) internal _percentStrategies;

    mapping(uint256 => address) internal _approvers;

    uint256 internal _totalSupply;

    ISwapRouter public immutable SwapRouter;

    constructor(address uniswapSwapRouter) ERC721("OnChain Strategies", "OCS") {
        SwapRouter = ISwapRouter(uniswapSwapRouter);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function mint(uint256 strategyType, address recepient, bool approved, BasicStrategy memory basicStrategy, bytes memory data) external override returns (uint256 tokenId) {
        tokenId = _totalSupply;

        _strategiesTypes[tokenId] = strategyType;
        _basicStrategies[tokenId] = basicStrategy;

        if(strategyType == 0) {
            // Interval
            _intervalStrategies[tokenId] = abi.decode(data, (IntervalStrategy));
        } else if(strategyType == 1) {
            // Flat
            _flatStrategies[tokenId] = abi.decode(data, (FlatStrategy));
            require(_flatStrategies[tokenId].flat != 0);
        } else if(strategyType == 2) {
            // Percent
            _percentStrategies[tokenId] = abi.decode(data, (PercentStrategy));
            require(_percentStrategies[tokenId].percent != 0);
        }

        _safeMint(recepient, tokenId);
        _totalSupply++;

        if(recepient == msg.sender && approved) {
            _approvers[tokenId] = msg.sender;
        }
    }

    function burn(uint256 tokenId) external override {
        require(ownerOf(tokenId) == msg.sender);
        _burn(tokenId);
    }

    function setAllocation(uint256 tokenId, uint256 allocation) external override {
        require(ownerOf(tokenId) == msg.sender);
        _basicStrategies[tokenId].allocation = allocation;
    }

    function setApprover(uint256 tokenId, bool approved) external override {
        require(ownerOf(tokenId) == msg.sender);
        if(approved) {
            _approvers[tokenId] = msg.sender;
        } else {
            _approvers[tokenId] = address(0);
        }
    }

    function checkStrategies(uint256 startId, uint256 length) external view override returns (uint256[] memory) {
        // TODO: Maybe adjust length instead of reverting
        require(_totalSupply <= startId + length);

        uint256[] memory maxIds = new uint256[](length);

        uint256 renewCount;
        for(uint256 i; i < length; i++) {
            uint256 id = startId + i;
            address owner = ownerOf(id);
            IERC20 tokenIn = IERC20(_basicStrategies[id].tokenIn);

            if(_approvers[id] != owner || 
                _basicStrategies[id].amount > _basicStrategies[id].allocation || 
                _basicStrategies[id].amount > tokenIn.allowance(owner, address(this)) ||
                _basicStrategies[id].amount > tokenIn.balanceOf(owner)) {
                continue;
            }

            if(_strategiesTypes[id] == 0) {
                // Interval
                if(block.timestamp > _intervalStrategies[id].lastTimestamp + _intervalStrategies[id].interval) {
                    maxIds[renewCount] = id;
                    renewCount++;
                }
            } else if(_strategiesTypes[id] == 1) {
                // Flat
                (,int256 response,,,) = AggregatorV3Interface(_flatStrategies[id].aggregator).latestRoundData();
                int256 flatChange = _flatChange(response, _flatStrategies[id].lastResponse);
                if(_abs(flatChange) >= _abs(_flatStrategies[id].flat)) {
                    maxIds[renewCount] = id;
                    renewCount++;
                }
            } else if(_strategiesTypes[id] == 2) {
                // Percent
                (,int256 response,,,) = AggregatorV3Interface(_percentStrategies[id].aggregator).latestRoundData();
                int256 percentChange = _percentChange(response, _percentStrategies[id].lastResponse);
                if(_abs(percentChange) >= _abs(_percentStrategies[id].percent)) {
                    maxIds[renewCount] = id;
                    renewCount++;
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
            require(_basicStrategies[ids[i]].allocation >= _basicStrategies[ids[i]].amount);
            require(_approvers[ids[i]] == ownerOf(ids[i]));

            if(_strategiesTypes[ids[i]] == 0) {
                // Interval
                require(block.timestamp > _intervalStrategies[ids[i]].lastTimestamp + _intervalStrategies[ids[i]].interval);

                _intervalStrategies[ids[i]].lastTimestamp = block.timestamp;
            } else if(_strategiesTypes[ids[i]] == 1) {
                // Flat
                (,int256 response,,,) = AggregatorV3Interface(_flatStrategies[ids[i]].aggregator).latestRoundData();
                int256 flatChange = _flatChange(response, _flatStrategies[ids[i]].lastResponse);
                require(_abs(flatChange) >= _abs(_flatStrategies[ids[i]].flat));

                _flatStrategies[ids[i]].lastResponse = response;
            } else if(_strategiesTypes[ids[i]] == 2) {
                // Percent
                (,int256 response,,,) = AggregatorV3Interface(_percentStrategies[ids[i]].aggregator).latestRoundData();
                int256 percentChange = _percentChange(response, _percentStrategies[ids[i]].lastResponse);
                require(_abs(percentChange) >= _abs(_percentStrategies[ids[i]].percent));

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
                    "}"
                )
            )))
        ));
    }

    function _beforeTokenTransfer(address /* from */, address /* to */, uint256 tokenId) internal virtual override {
        _approvers[tokenId] = address(0);
    }

    function _abs(int256 value) internal pure returns (int256) {
        return value >= 0 ? value : -value;
    }

    function _percentChange(int256 a, int256 b) internal pure returns (int256) {
        // TODO: More complex signed math
        return ((a - b) * 10000) / b;
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
            value = string(abi.encodePacked(_intervalStrategies[tokenId].interval.toString(), "s"));
        } else if(_strategiesTypes[tokenId] == 1) {
            // Flat
            name = "Flat Strategy";
            value = uint256(_abs(_flatStrategies[tokenId].flat)).toString();
            if(_flatStrategies[tokenId].flat < 0) {
                value = string(abi.encodePacked("-", value));
            }
        } else if(_strategiesTypes[tokenId] == 2) {
            // Percent
            name = "Percentage Strategy";
            int256 prefix = _percentStrategies[tokenId].percent / 100;
            uint256 suffix = uint256(_abs(_percentStrategies[tokenId].percent % 100));

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