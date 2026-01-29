// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "@forge-std/Script.sol";
import {GRAM} from "../GRAM.sol";

contract DeployGRAM is Script {
    address constant XAUT = 0x68749665FF8D2d112Fa859AA293F07A622782F38;
    address constant TREASURY = 0x300Df392cE8910E0E4D42C6ecb9bA1a8b19bAdF0;

    function run() external {
        vm.startBroadcast();
        GRAM gram = new GRAM(XAUT, TREASURY);
        vm.stopBroadcast();
    }
}
