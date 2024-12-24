// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";
import {MyswapPair} from "../src/V2/MyswapPair.sol";

contract MyswapPairTest is Test {
    MyToken public token0;
    MyToken public token1;
    MyswapPair public pair;

    function setUp() public {
        token0 = new MyToken("My-Token-0", "MY0", 1000 ether);
        token1 = new MyToken("My-Token-1", "MY1", 1000 ether);

        pair = new MyswapPair(address(token0), address(token1));
    }

    function test_mint() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint();

        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
    }
}
