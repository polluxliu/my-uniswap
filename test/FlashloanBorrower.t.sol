// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";
import {FlashloanBorrower} from "../src/V2/FlashloanBorrower.sol";
import {MyswapFactory} from "../src/V2/MyswapFactory.sol";
import {MyswapPair} from "../src/V2/MyswapPair.sol";
import {MyswapRouter} from "../src/V2/MyswapRouter.sol";

contract FlashloanBorrowerTest is Test {
    FlashloanBorrower public flashloanBorrower;
    MyswapFactory public factory;
    MyswapRouter public router;
    MyToken public tokenA;
    MyToken public tokenB;

    function setUp() public {
        // Deploy factory
        factory = new MyswapFactory();

        // Deploy router
        router = new MyswapRouter(address(factory));

        // Deploy tokens
        tokenA = new MyToken("My-Token-0", "MY0", 2000 ether);
        tokenB = new MyToken("My-Token-1", "MY1", 2000 ether);

        // Approve the Router to spend tokenA
        tokenA.approve(address(router), 2000 ether);

        // Approve the Router to spend tokenB
        tokenB.approve(address(router), 2000 ether);

        // Create a new liquidity pair contract using the two tokens
        router.addLiquidity(address(tokenA), address(tokenB), 1_000 ether, 1_000 ether, 1 ether, 1 ether, address(this));

        // Deploy the FlashloanBorrower contract
        flashloanBorrower = new FlashloanBorrower(address(factory));

        // Mint tokens to the borrower
        tokenA.mintTo(address(flashloanBorrower), 10 ether);
        tokenB.mintTo(address(flashloanBorrower), 10 ether);
    }

    function test_Flashloan() public {
        uint256 amountAOut = 10 ether;
        uint256 amountBOut = 0 ether;

        // Ensure borrower contract has no tokens initially
        assertEq(tokenA.balanceOf(address(flashloanBorrower)), 10 ether);
        assertEq(tokenB.balanceOf(address(flashloanBorrower)), 10 ether);

        // Get the pair address
        address pair = factory.pairs(address(tokenA), address(tokenB));

        // Initiate the flashloan
        flashloanBorrower.loan(pair, address(tokenA), address(tokenB), amountAOut, amountBOut);

        // Simulate repayment in executeOperation
        uint256 feeA = amountAOut != 0 ? (amountAOut * 3) / 997 + 1 : 0;
        uint256 feeB = amountBOut != 0 ? (amountBOut * 3) / 997 + 1 : 0;

        // Validate that the tokens were borrowed
        assertEq(tokenA.balanceOf(address(flashloanBorrower)), 10 ether - feeA);
        assertEq(tokenB.balanceOf(address(flashloanBorrower)), 10 ether - feeB);

        uint256 expectedRepayA = amountAOut + feeA;
        uint256 expectedRepayB = amountBOut + feeB;

        // Ensure the borrower repays the correct amount
        assertEq(tokenA.balanceOf(address(pair)), 1_000 ether - amountAOut + expectedRepayA);
        assertEq(tokenB.balanceOf(address(pair)), 1_000 ether - amountBOut + expectedRepayB);
    }
}
