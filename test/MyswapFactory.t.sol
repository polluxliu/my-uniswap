// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import "../src/V2/MyswapPair.sol";

contract MyswapFactoryTest is Test {
    function setUp() public {}

    function test_generateCodeHashOfPairContract() public pure {
        bytes32 initialCodeHash = keccak256(type(MyswapPair).creationCode);

        console.logBytes32(initialCodeHash);

        assertEq(
            initialCodeHash,
            hex"e13693dee59923f87f78fd6a4c08d510ecf83211e68861d28fb7c9c9727b554f",
            "Code hash of MyswapPair contract is incorrect"
        );
    }
}
