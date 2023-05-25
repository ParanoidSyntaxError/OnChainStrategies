// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

import "./interfaces/IOnChainStrategies.sol";

contract OCSKeeper is AutomationCompatibleInterface {
    IOnChainStrategies public immutable OnChainStrategies;

    constructor(address onchainStrategies) {
        OnChainStrategies = IOnChainStrategies(onchainStrategies);
    }

    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        uint256 checkLength = abi.decode(checkData, (uint256));
        uint256 supply = OnChainStrategies.totalSupply();
        uint256 startId;
        
        if(checkLength > supply) {
            checkLength = supply;
        } else {
            startId = (block.timestamp % (supply / checkLength)) * checkLength;
        
            if(startId + checkLength > supply) {
                checkLength = supply - startId;
            }
        }

        uint256[] memory ids = OnChainStrategies.checkStrategies(startId, checkLength);

        upkeepNeeded = ids.length > 0;
        performData = abi.encode(ids);
    }

    function performUpkeep(bytes calldata performData) external override {
        uint256[] memory ids = abi.decode(performData, (uint256[]));
        OnChainStrategies.upkeepStrategies(ids);
    }
}