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
            hex"f0d94172d9e66b0358f30053c4818f80355007e3176f3c99071a8ec5cd892d6b",
            "Code hash of MyswapPair contract is incorrect"
        );
    }

    function test_emptyBytes() public pure {
        // 以下所有方式都会得到相同的结果 - 空字节数组
        bytes memory emptyBytes1 = "";
        bytes memory emptyBytes2 = new bytes(0);
        bytes memory emptyBytes3 = hex"";
        bytes memory emptyBytes4 = bytes("");

        // 可以用 length 属性验证
        assert(emptyBytes1.length == 0);
        assert(emptyBytes2.length == 0);
        assert(emptyBytes3.length == 0);
        assert(emptyBytes4.length == 0);
    }
}
