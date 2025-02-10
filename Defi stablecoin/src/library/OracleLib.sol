// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
import {AggregatorV3Interface} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


library OracleLib{
     error PRICE_IS_STALE();
    uint256 constant private TIMEOUT= 3 hours;
    function stalePricecheck(AggregatorV3Interface pricefeed) public view returns (uint80,int256,uint256,uint256,uint80){
        (uint80 roundID,int256 price,uint256 startedAt,uint256 timeStamp,uint80 answeredInRound) = pricefeed.latestRoundData();
        uint256 secondsSinceLastUpdate = block.timestamp - timeStamp;
        if (secondsSinceLastUpdate > TIMEOUT) {
           revert PRICE_IS_STALE();
           return (roundID,price,startedAt,timeStamp,answeredInRound);
        }
  
    }
}
