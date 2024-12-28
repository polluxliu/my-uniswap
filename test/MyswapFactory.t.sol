// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import "../src/V2/MyswapPair.sol";

contract MyswapFactoryTest is Test {
    function setUp() public {}

    // function test_generateCodeHashOfPairContract() public pure {
    //     bytes32 initialCodeHash = keccak256(type(MyswapPair).creationCode);

    //     console.logBytes32(initialCodeHash);

    //     assertEq(
    //         initialCodeHash,
    //         hex"cf21606cda01b554f7e32ebe21a86cd486e8242de482d779d842dfa97bae8c8b",
    //         "Code hash of MyswapPair contract is incorrect"
    //     );
    // }

    function test_112multiply() public pure {
        uint112 a = 2 ** 111;
        // uint112 b = 2 ** 111;

        uint256 c = 2 ** 100;

        a - c;

        // unchecked {
        // console.log(a*b);
        // }
        // uint256 c = uint256(a) * uint256(b);

        // uint256 c = uint256(a) * uint256(b);

        // assertEq(c, 20000, "112 multiplication is incorrect");
    }
}
