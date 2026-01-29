// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "@forge-std/Test.sol";
import {GRAM} from "../src/GRAM.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GRAMTest is Test {
    GRAM public gram;
    IERC20 public xaut;

    address public constant XAUT = 0x68749665FF8D2d112Fa859AA293F07A622782F38;
    address public constant TREASURY = 0x300Df392cE8910E0E4D42C6ecb9bA1a8b19bAdF0;

    address public user;
    address public user2;

    uint256 private constant CONVERSION_RATE = 31103476800000000000;
    uint256 private constant XAUT_DECIMALS = 8;
    uint256 private constant FEE_BASIS_POINTS = 50;
    uint256 private constant FEE_DENOMINATOR = 10000;

    function setUp() public {
        gram = new GRAM();
        xaut = IERC20(XAUT);

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

        deal(XAUT, user, xautAmount);
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

        deal(XAUT, user, xautAmount);
        vm.prank(user);
        xaut.approve(address(gram), xautAmount);

        vm.prank(user);
        gram.mint(xautAmount);

        uint256 fee = gramAmount * FEE_BASIS_POINTS / FEE_DENOMINATOR;
        uint256 netGram = gramAmount - fee;

        vm.prank(user);
        gram.burn(netGram);

        assertEq(gram.balanceOf(user), 0);
        assertEq(xaut.balanceOf(user), xautAmount);
    }

    function testMintFeeDistribution() public {
        uint256 xautAmount = 100000000; // 1 XAUT
        uint256 grossGram = xautAmount * CONVERSION_RATE / 10**XAUT_DECIMALS;
        uint256 expectedFee = grossGram * FEE_BASIS_POINTS / FEE_DENOMINATOR;
        uint256 expectedNet = grossGram - expectedFee;

        assertEq(expectedFee, 15551738400000000000);
        assertEq(expectedNet, 31051738399999999985);

        deal(XAUT, user, xautAmount);
        vm.prank(user);
        xaut.approve(address(gram), xautAmount);

        vm.prank(user);
        gram.mint(xautAmount);

        assertEq(gram.balanceOf(user), expectedNet);
        assertEq(gram.balanceOf(TREASURY), expectedFee);
    }

    function testMintMultipleUsers() public {
        uint256 xautAmount = 1e8;

        deal(XAUT, user, xautAmount);
        deal(XAUT, user2, xautAmount);

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

    function testBurnWithPermit() public {
        uint256 xautAmount = 1e8;
        uint256 gramAmount = xautAmount * CONVERSION_RATE / 10**XAUT_DECIMALS;
        uint256 fee = gramAmount * FEE_BASIS_POINTS / FEE_DENOMINATOR;
        uint256 netGram = gramAmount - fee;

        deal(XAUT, user, xautAmount);
        vm.prank(user);
        xaut.approve(address(gram), xautAmount);
        vm.prank(user);
        gram.mint(xautAmount);

        uint256 nonce = gram.nonces(user);
        uint256 deadline = block.timestamp + 1 hours;

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                gram.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(gram.PERMIT_TYPEHASH(), user, address(this), nonce, deadline, true))
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user, digest);

        gram.permit(user, address(this), nonce, deadline, true, v, r, s);

        vm.prank(user);
        gram.burn(netGram);

        assertEq(gram.balanceOf(user), 0);
    }

    function testRevertInsufficientAllowance() public {
        uint256 xautAmount = 1e8;
        deal(XAUT, user, xautAmount);

        vm.prank(user);
        gram.mint(xautAmount);
    }

    function testRevertInsufficientBalance() public {
        uint256 gramAmount = 1e18;
        vm.prank(user);
        gram.burn(gramAmount);
    }
}
