// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20Permit, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GRAM is ERC20Permit {
    address private immutable XAUT;
    address private immutable TREASURY;

    uint256 private constant CONVERSION_RATE = 31103476800000000000;
    uint256 private constant XAUT_DECIMALS = 8;
    uint256 private constant FEE_BASIS_POINTS = 50;
    uint256 private constant FEE_DENOMINATOR = 10000;

    constructor(address xaut, address treasury) ERC20Permit("GRAM") ERC20("GRAM", "GRAM") {
        XAUT = xaut;
        TREASURY = treasury;
    }

    function mint(uint256 xautAmount) external {
        uint256 grossGram = xautAmount * CONVERSION_RATE / 10**XAUT_DECIMALS;
        uint256 fee = grossGram * FEE_BASIS_POINTS / FEE_DENOMINATOR;
        uint256 netGram = grossGram - fee;

        IERC20(XAUT).transferFrom(msg.sender, address(this), xautAmount);
        _mint(msg.sender, netGram);
        _mint(TREASURY, fee);
    }

    function burn(uint256 gramAmount) external {
        uint256 xautAmount = gramAmount * 10**XAUT_DECIMALS / CONVERSION_RATE;

        _burn(msg.sender, gramAmount);
        IERC20(XAUT).transfer(msg.sender, xautAmount);
    }
}
