// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.28;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TaxHandler is Initializable, OwnableUpgradeable {
    uint256 public constant BPS = 10_000;

    address public router;

    uint256 public buyTax;
    uint256 public sellTax;

    bool public enableTrading;

    IERC20 public token;

    mapping(address => bool) public pools;
    mapping(address => bool) public taxExempt;

    enum Flag {
        None,
        Buy,
        Sell
    }

    event SetToken(address _token);
    event SetTax(uint256 _buyTax, uint256 _sellTax);
    event PoolAdded(address pool);

    error InvalidParam();
    error InvalidTaxRange();
    error TradingDisabled();

    function initialize(address admin, address _router, address[] memory _children) initializer public {
        __Ownable_init(admin);

        buyTax = 500;
        sellTax = 500;

        taxExempt[admin] = true;
        taxExempt[_router] = true;

        for (uint256 i = 0; i < _children.length; i++) {
            taxExempt[_children[i]] = true;
        }
    }

    function getTax(address from, address to, uint256 amount) external view returns (uint256 _tax, Flag flag) {
        flag = Flag.None;

        if (pools[from] || pools[to]) {
            if (taxExempt[from] || taxExempt[to]) {
                return (0, Flag.None);
            }
            if (!enableTrading) {
                revert TradingDisabled();
            }
            if (pools[to]) {
                flag = Flag.Sell;
                _tax = amount * sellTax / BPS;
            } else {
                flag = Flag.Buy;
                _tax = amount * buyTax / BPS;
            }
            return (_tax, flag);
        }
        return (0, flag);
    }

    function setToken(address _token) external onlyOwner {
        token = IERC20(_token);
        emit SetToken(_token);
    }

    function setTax(uint256 _buyTax, uint256 _sellTax) external onlyOwner {
        if (_buyTax > 3000 || _sellTax > 3000) {
            revert InvalidTaxRange();
        }
        buyTax = _buyTax;
        sellTax = _sellTax;
        emit SetTax(_buyTax, _sellTax);
    }

    function setEnableTrading(bool _enableTrading) external onlyOwner {
        enableTrading = _enableTrading;
    }

    function setTaxExempt(address[] memory account, bool[] memory exempt) external onlyOwner {
        if (account.length != exempt.length) {
            revert InvalidParam();
        }
        for (uint256 i = 0; i < account.length; i++) {
            taxExempt[account[i]] = exempt[i];
        }
    }

    function addToPool(address pool) external onlyOwner {
        pools[pool] = true;
        emit PoolAdded(pool);
    }

    function rescueTokens(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(token) || tokenAddress == address(0)) {
            revert InvalidParam();
        }
        IERC20(tokenAddress).transfer(msg.sender, amount);
    }

}