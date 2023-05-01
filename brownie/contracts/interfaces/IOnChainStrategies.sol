// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOnChainStrategies {
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

    function totalSupply() external view returns (uint256);

    function mint(uint256 strategyType, address recepient, bool approved, BasicStrategy memory basicStrategy, bytes memory data) external returns (uint256 tokenId);
    function burn(uint256 tokenId) external;

    function setAllocation(uint256 tokenId, uint256 allocation) external;
    function setApprover(uint256 tokenId, bool approved) external;

    function checkStrategies(uint256 startId, uint256 length) external view returns (uint256[] memory);
    function upkeepStrategies(uint256[] memory ids) external;
}