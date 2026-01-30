// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {GRAM} from "../src/GRAM.sol";
import {console2} from "forge-std/console2.sol";
import {MockXAUT} from "./MockXAUT.sol";

contract GRAMTest is Test {
    GRAM public gram;
    MockXAUT public xaut;

    address public constant TREASURY = 0x300Df392cE8910E0E4D42C6ecb9bA1a8b19bAdF0;

    event Mint(address indexed user, uint256 xautAmount, uint256 grossGram, uint256 fee);
    event Burn(address indexed user, uint256 gramAmount, uint256 xautAmount);

    address public user;
    address public user2;

    uint256 private constant CONVERSION_RATE = 31103476800000000000;
    uint256 private constant XAUT_DECIMALS = 8;
    uint256 private constant FEE_BASIS_POINTS = 50;
    uint256 private constant FEE_DENOMINATOR = 10000;

    function setUp() public {
        xaut = new MockXAUT();
        gram = new GRAM(address(xaut), TREASURY);

        user = makeAddr("user");
        user2 = makeAddr("user2");

        vm.deal(user, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function testDecimals() public {
        assertEq(gram.decimals(), 18);
    }

    function testNameAndSymbol() public {
        assertEq(gram.name(), "GRAM");
        assertEq(gram.symbol(), "GRAM");
    }

    function testMintConversion() public {
        uint256 xautAmount = 1e8;
        uint256 expectedGram = xautAmount * CONVERSION_RATE / 10**XAUT_DECIMALS;

        assertEq(expectedGram, 31103476800000000000);

        xaut.mint(user, xautAmount);
        vm.prank(user);
        xaut.approve(address(gram), xautAmount);

        vm.prank(user);
        gram.mint(xautAmount);

        uint256 fee = expectedGram * FEE_BASIS_POINTS / FEE_DENOMINATOR;
        uint256 netGram = expectedGram - fee;

        assertEq(gram.balanceOf(user), netGram);
        assertEq(gram.balanceOf(TREASURY), fee);
        assertEq(xaut.balanceOf(address(gram)), xautAmount);
    }

    function testBurnConversion() public {
        uint256 xautAmount = 1e8;
        uint256 gramAmount = xautAmount * CONVERSION_RATE / 10**XAUT_DECIMALS;

        xaut.mint(user, xautAmount);
        vm.prank(user);
        xaut.approve(address(gram), xautAmount);

        vm.prank(user);
        gram.mint(xautAmount);

        uint256 fee = gramAmount * FEE_BASIS_POINTS / FEE_DENOMINATOR;
        uint256 netGram = gramAmount - fee;

        vm.prank(user);
        gram.burn(netGram);

        assertEq(gram.balanceOf(user), 0);
        assertEq(xaut.balanceOf(user), 99500000);
    }

    function testMintFeeDistribution() public {
        uint256 xautAmount = 100000000;

        xaut.mint(user, xautAmount);
        vm.prank(user);
        xaut.approve(address(gram), xautAmount);

        vm.prank(user);
        gram.mint(xautAmount);

        assertEq(gram.balanceOf(TREASURY), 155517384000000000);
        assertEq(gram.balanceOf(user), 30947959416000000000);
    }

    function testMintMultipleUsers() public {
        uint256 xautAmount = 1e8;

        xaut.mint(user, xautAmount);
        xaut.mint(user2, xautAmount);

        vm.prank(user);
        xaut.approve(address(gram), xautAmount);
        vm.prank(user);
        gram.mint(xautAmount);

        vm.prank(user2);
        xaut.approve(address(gram), xautAmount);
        vm.prank(user2);
        gram.mint(xautAmount);

        assertGt(gram.balanceOf(user), 0);
        assertGt(gram.balanceOf(user2), 0);
        assertEq(gram.balanceOf(user), gram.balanceOf(user2));
    }

    function testRevertInsufficientAllowance() public {
        uint256 xautAmount = 1e8;
        xaut.mint(user, xautAmount);

        vm.expectRevert();
        vm.prank(user);
        gram.mint(xautAmount);
    }

    function testRevertInsufficientBalance() public {
        uint256 gramAmount = 1e18;
        vm.expectRevert();
        vm.prank(user);
        gram.burn(gramAmount);
    }

    function testRevertZeroMint() public {
        vm.expectRevert(GRAM.ZeroMint.selector);
        gram.mint(0);
    }

    function testRevertZeroBurn() public {
        vm.expectRevert(GRAM.ZeroBurn.selector);
        gram.burn(0);
    }

    function testMintEvent() public {
        uint256 xautAmount = 1e8;
        uint256 expectedGram = xautAmount * CONVERSION_RATE / 10**XAUT_DECIMALS;
        uint256 fee = expectedGram * FEE_BASIS_POINTS / FEE_DENOMINATOR;

        xaut.mint(user, xautAmount);
        vm.prank(user);
        xaut.approve(address(gram), xautAmount);

        vm.expectEmit();
        emit Mint(user, xautAmount, expectedGram, fee);

        vm.prank(user);
        gram.mint(xautAmount);
    }

    function testBurnEvent() public {
        uint256 xautAmount = 1e8;
        uint256 gramAmount = xautAmount * CONVERSION_RATE / 10**XAUT_DECIMALS;

        xaut.mint(user, xautAmount);
        vm.prank(user);
        xaut.approve(address(gram), xautAmount);

        vm.prank(user);
        gram.mint(xautAmount);

        uint256 fee = gramAmount * FEE_BASIS_POINTS / FEE_DENOMINATOR;
        uint256 netGram = gramAmount - fee;
        uint256 expectedXaut = (netGram * 10**XAUT_DECIMALS + CONVERSION_RATE - 1) / CONVERSION_RATE;

        vm.expectEmit();
        emit Burn(user, netGram, expectedXaut);

        vm.prank(user);
        gram.burn(netGram);
    }
}
