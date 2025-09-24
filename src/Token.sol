// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.22;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ReentrancyGuardTransient } from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

interface IPancakeRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function WETH() external pure returns (address);
}

interface ITaxHandler {
    enum Flag {
        None,
        Buy,
        Sell
    }
    function getTax(address from, address to, uint256 amount) external view returns (uint256 tax, Flag flag);
}

contract Token is ERC20, ERC20Burnable, ReentrancyGuardTransient {
    uint256 public constant ACCUMULATE_TO_DONATE = 200 ether;
    address public constant DONATE_TO = 0xC7f501D25Ea088aeFCa8B4b3ebD936aAe12bF4A4;

    uint256 public totalBNBDonatedAmount;
    
    IPancakeRouter public immutable router;
    ITaxHandler public immutable taxHandler;

    constructor(address _taxHandler) ERC20("TESTYLENOL", "TESTYLENOL") {
        _mint(msg.sender, 1_000_000 ether);
        router = IPancakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _approve(address(this), address(router), type(uint256).max);
        taxHandler = ITaxHandler(_taxHandler);
    }

    receive() external payable {}

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from == address(0) || to == address(0)) {
            super._update(from, to, amount);
            return;
        }
        
        (uint256 taxAmount, ITaxHandler.Flag flag) = taxHandler.getTax(from, to, amount);
        
        if (taxAmount > 0) {

            if (flag == ITaxHandler.Flag.Sell) {
                if (_hasAccumulatedEnoughToDonate()) {
                    _donate();
                }
            }

            uint256 toDonate = taxAmount / 2;
            uint256 toBurn = taxAmount - toDonate;

            super._burn(from, toBurn);
            
            super._update(from, address(this), toDonate);
            
            super._update(from, to, amount - taxAmount);
        } else {
            // Regular transfer without tax
            super._update(from, to, amount);
        }
    }

    function _hasAccumulatedEnoughToDonate() internal view returns (bool) {
        return balanceOf(address(this)) >= ACCUMULATE_TO_DONATE;
    }

    function _donate() internal nonReentrant {
        uint256 amountIn = balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, 0, path, address(this), block.timestamp + 300);

        uint256 bnbBalance = address(this).balance;
        totalBNBDonatedAmount += bnbBalance;
        (bool success, ) = DONATE_TO.call{value: bnbBalance}("");
        require(success, "Failed to donate BNB");
    }
}