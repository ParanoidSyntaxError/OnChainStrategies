// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOnChainStrategies {
    struct BaseStrategy {
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint24 poolFee;
        uint256 allocation;
    }

    struct Interval {
        uint256 interval;
        uint256 lastTimestamp;
    }

    struct AggregatorChange {
        address aggregator;
        int256 change;
        uint80 lastRoundId;
        uint80 frequency;
    }

    function totalSupply() external view returns (uint256);

    function mint(uint256 strategyType, address recepient, bool approved, BaseStrategy memory baseStrategy, bytes memory data) external returns (uint256 tokenId);
    function burn(uint256 tokenId) external;

    function setAllocation(uint256 tokenId, uint256 allocation) external;
    function setUpkeepApproval(uint256 tokenId, bool approved) external;

    function checkStrategies(uint256 startId, uint256 length) external view returns (uint256[] memory);
    function upkeepStrategies(uint256[] memory ids) external;
}