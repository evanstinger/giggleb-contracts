// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "lib/forge-std/src/Script.sol";

import { Token } from "../src/Token.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("BAGZ_PK"));
        Token token = new Token(0xFa883D345dCd463c16c4ebA40da34b569Cf18f83);
        console.log("Token contract deployed at:");
        console.logAddress(address(token));
        vm.stopBroadcast();
    }
}