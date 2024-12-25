// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";
import {MyswapPair} from "../src/V2/MyswapPair.sol";

contract MyswapPairTest is Test {
    MyToken public token0;
    MyToken public token1;
    MyswapPair public pair;

    address userA;

    // Setup function to initialize the token contracts and the liquidity pair
    function setUp() public {
        // Create two tokens with an initial supply of 1000 ether each
        token0 = new MyToken("My-Token-0", "MY0", 1000 ether);
        token1 = new MyToken("My-Token-1", "MY1", 1000 ether);

        userA = makeAddr("UserA");

        token0.mintTo(userA, 10 ether);
        token1.mintTo(userA, 10 ether);

        // Create a new liquidity pair contract using the two tokens
        pair = new MyswapPair(address(token0), address(token1));
    }

    // Test case: Minting liquidity for the first time to initialize the pool
    function test_mint_initialization() public {
        // Transfer 1 ether of each token to the pair contract
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        // Mint liquidity tokens to initialize the pool
        pair.mint();

        // Assert that the user's balance reflects minted LP tokens minus the minimum liquidity lock
        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);

        // Assert the total supply of LP tokens is 1 ether
        assertEq(pair.totalSupply(), 1 ether);

        // Assert the reserves match the token balances in the contract
        _assertPairReserves(1 ether, 1 ether);
    }

    // Test case: Adding balanced liquidity after pool initialization
    function test_mint_addition_balanced() public {
        // Initialize the pool with 1 ether of each token
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint();

        // Transfer additional balanced liquidity (3 ether of each token)
        token0.transfer(address(pair), 3 ether);
        token1.transfer(address(pair), 3 ether);
        pair.mint();

        // Assert the user's LP token balance reflects the total liquidity they added minus the minimum liquidity
        assertEq(pair.balanceOf(address(this)), 4 ether - 1000);

        // Assert the total LP token supply is now 4 ether
        assertEq(pair.totalSupply(), 4 ether);

        // Assert the reserves reflect the updated balances
        _assertPairReserves(4 ether, 4 ether);
    }

    // Test case: Adding unbalanced liquidity after pool initialization
    function test_mint_addition_unbalanced() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint();

        // Transfer additional unbalanced liquidity (4 ether of token0, 2 ether of token1)
        token0.transfer(address(pair), 4 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint();

        // Assert the user's LP token balance reflects the liquidity they added (limited by the smaller proportion)
        assertEq(pair.balanceOf(address(this)), 3 ether - 1000);

        // Assert the total LP token supply is now 3 ether
        assertEq(pair.totalSupply(), 3 ether);

        // Assert the reserves reflect the updated balances
        _assertPairReserves(5 ether, 3 ether);
    }

    // Test case: Burning balanced liquidity from the pool
    function test_burn_balanced() public {
        // Initialize the pool with 1 ether of each token
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint();

        // Get the user's LP token balance and transfer it to the pair contract for burning
        uint256 liquidity = pair.balanceOf(address(this));
        pair.transfer(address(pair), liquidity);

        // Burn the liquidity tokens and withdraw the underlying assets
        pair.burn();

        // Assert the user has no LP tokens remaining
        assertEq(pair.balanceOf(address(this)), 0);

        // Assert the total LP token supply reflects the minimum liquidity lock
        assertEq(pair.totalSupply(), 1000);

        // Assert the user's token balances reflect their withdrawn assets
        assertEq(token0.balanceOf(address(this)), 1000 ether - 1000);
        assertEq(token1.balanceOf(address(this)), 1000 ether - 1000);

        // Assert the reserves reflect the remaining minimum liquidity
        _assertPairReserves(1000, 1000);
    }

    // Test case: Burning unbalanced liquidity from the pool
    function test_burn_unbalanced() public {
        // Initialize the pool with 1 ether of each token
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint();

        // Add unbalanced liquidity (2 ether of token0, 1 ether of token1)
        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint();

        // Get the user's LP token balance and transfer it to the pair contract for burning
        uint256 liquidity = pair.balanceOf(address(this));
        pair.transfer(address(pair), liquidity);

        // Burn the liquidity tokens and withdraw the underlying assets
        pair.burn();

        // Assert the user has no LP tokens remaining
        assertEq(pair.balanceOf(address(this)), 0);

        // Assert the total LP token supply reflects the minimum liquidity lock
        assertEq(pair.totalSupply(), 1000);

        // Assert the user's token balances reflect their withdrawn assets (unbalanced)
        assertEq(token0.balanceOf(address(this)), 1000 ether - 1500);
        assertEq(token1.balanceOf(address(this)), 1000 ether - 1000);

        // Assert the reserves reflect the remaining minimum liquidity
        _assertPairReserves(1500, 1000);
    }

    // Test cases: Tests the behavior of burning unbalanced liquidity from a pool with multiple users
    function test_burn_unbalanced_users() public {
        // UserA adds liquidity to the pool
        vm.startPrank(userA);
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint();
        vm.stopPrank();

        // Assert initial LP token balances and total supply
        assertEq(pair.balanceOf(address(this)), 0);
        assertEq(pair.balanceOf(address(userA)), 1 ether - 1000);
        assertEq(pair.totalSupply(), 1 ether);

        // This contract adds unbalanced liquidity (more token0 than token1)
        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint();

        // This contract burns its LP tokens
        uint256 balance = pair.balanceOf(address(this));
        pair.transfer(address(pair), balance);
        pair.burn();

        // Assert balances and reserves after burning
        assertEq(pair.balanceOf(address(this)), 0);
        assertEq(pair.totalSupply(), 1 ether);
        assertEq(token0.balanceOf(address(this)), 1000 ether - 0.5 ether);
        assertEq(token1.balanceOf(address(this)), 1000 ether);
        _assertPairReserves(1.5 ether, 1 ether);

        // UserA burns its LP tokens
        vm.startPrank(userA);
        uint256 balanceOfUserA = pair.balanceOf(userA);
        pair.transfer(address(pair), balanceOfUserA);
        pair.burn();
        vm.stopPrank();

        // Assert UserA's token balances after burning LP tokens
        assertEq(token0.balanceOf(userA), 10.5 ether - 1500);
        assertEq(token1.balanceOf(userA), 10 ether - 1000);
        _assertPairReserves(1500, 1000);

        /**
         * The test contract incurred a loss of 0.5 ETH due to providing unbalanced liquidity,
         * and this loss was ultimately gained by UserA.
         */
    }

    // Helper function to assert that the reserves match the expected values
    function _assertPairReserves(uint112 expected0, uint112 expected1) private view {
        (uint112 reserve0, uint112 reserve1) = pair.getReserves();
        assertEq(reserve0, expected0, "unexpected reserve0");
        assertEq(reserve1, expected1, "unexpected reserve1");
    }
}
