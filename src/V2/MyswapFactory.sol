// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "./MyswapPair.sol";
import "./IMyswapPair.sol";

contract MyswapFactory {
    // A mapping to store the addresses of pair contracts for token pairs.
    mapping(address => mapping(address => address)) public pairs;

    // An array to store all created pair addresses.
    address[] public allPairs;

    // Event emitted when a new pair is created.
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 allPairsLength);

    /**
     * @dev Creates a new pair contract for the given token pair.
     * @param _tokenA Address of the first token in the pair.
     * @param _tokenB Address of the second token in the pair.
     * @return pair Address of the newly created pair contract.
     */
    function createPair(address _tokenA, address _tokenB) external returns (address pair) {
        // Ensure the two tokens are not the same.
        require(_tokenA != _tokenB, "IDENTICAL_ADDRESSES");

        // Ensure token addresses are ordered to prevent duplicate pairs.
        (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);

        // Ensure the token address is not zero.
        require(_tokenA != address(0), "ZERO_ADDRESS");

        // Ensure the pair does not already exist.
        require(pairs[token0][token1] == address(0), "PAIR_EXISTS");

        // Retrieve the creation bytecode for the pair contract.
        bytes memory bytecode = type(MyswapPair).creationCode;

        // Generate a deterministic salt using the token pair addresses.
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));

        // Deploy the pair contract using CREATE2.
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // Initialize the pair contract with the token addresses.
        IMyswapPair(pair).initialize(token0, token1);

        // Store the pair address in the mapping for both token0 and token1.
        pairs[token0][token1] = pair;
        pairs[token1][token0] = pair;

        // Add the pair to the list of all pairs.
        allPairs.push(pair);

        // Emit the PairCreated event with the details of the new pair.
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}
