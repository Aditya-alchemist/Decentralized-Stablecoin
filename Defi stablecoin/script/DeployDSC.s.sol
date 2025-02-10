// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script} from "lib/forge-std/src/Script.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";

contract DeployDSC is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() external returns (DSCEngine, DecentralizedStableCoin) {
       
        tokenAddresses = [0xdd13E55209Fd76AfE204dBda4007C227904f0a81,0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063 ];
        priceFeedAddresses = [0x694AA1769357215DE4FAC081bf1f309aDC325306,0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43 ];
        vm.startBroadcast();
        DecentralizedStableCoin dsc = new DecentralizedStableCoin();
        DSCEngine dscEngine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
        dsc.transferOwnership(address(dscEngine));
        return (dscEngine, dsc);
        vm.stopBroadcast();
    }
}
