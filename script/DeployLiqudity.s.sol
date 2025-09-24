// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import {IPancakeFactory} from "../src/interfaces/IPancakeFactory.sol";
import {IPancakeRouter02} from "../src/interfaces/IPancakeRouter02.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITaxHandler {
    function addToPool(address pool) external;
    function setTaxExempt(address[] memory account, bool[] memory exempt) external;
}

contract DeployLiquidity is Script {
    ITaxHandler public taxHandler = ITaxHandler(0x552b6169c8086BFD90F1B05D872Ebc4987e6F82F);
    IPancakeFactory public factory = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    IPancakeRouter02 public router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IERC20 public token = IERC20(0x30EffEE860E407B60de454bDc754b3b271824444);
    
    function run() public {
        vm.startBroadcast();
        _createPair();
        _deployLiquidity();
        _exemptToken();
        vm.stopBroadcast();
    }    

    function _deployLiquidity() internal {
      token.approve(address(router), type(uint256).max);
      router.addLiquidityETH{value: 1880000000000000000}(
          address(token),
          1_000_000 ether,
          1_000_000 ether,
          1880000000000000000,
          msg.sender,
          block.timestamp + 600 // 10 minutes buffer
      );
    }

    function _createPair() internal {
      address WBNB = router.WETH();
      address pair = factory.createPair(address(token), WBNB);
      taxHandler.addToPool(pair);
      
    }

    function _exemptToken() internal {
        address[] memory accounts = new address[](1);
        bool[] memory exempt = new bool[](1);
        accounts[0] = address(token);
        exempt[0] = true;
        taxHandler.setTaxExempt(accounts, exempt);
    }
}