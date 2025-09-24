// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { TaxHandler } from "../src/TaxHandler.sol";

contract Deploy is Script {
    address public router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public deployer = vm.envAddress("DEPLOYER_ADDRESS");
    uint256 public PK = vm.envUint("DEPLOYER_PK");

    address public taxHandlerProxy;

    function run() external {
        address[] memory children = new address[](0);
        vm.startBroadcast(PK);
        taxHandlerProxy = Upgrades.deployTransparentProxy(
          "TaxHandler.sol",
          deployer,
          abi.encodeCall(TaxHandler.initialize, (deployer, router, children))
        );
    }
}