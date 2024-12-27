// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "../IMyswapPair.sol";
import "../MyswapPair.sol";

library MyswapLibrary {
    /**
     * @dev Fetches the reserves for a pair of tokens from the pair contract.
     * @param factory The address of the factory contract.
     * @param tokenA The address of token A.
     * @param tokenB The address of token B.
     * @return reserveA The reserve of token A.
     * @return reserveB The reserve of token B.
     */
    function getReserves(address factory, address tokenA, address tokenB)
        internal
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint112 reserve0, uint112 reserve1) = IMyswapPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /**
     * @dev Calculates the pair address for two tokens using CREATE2.
     * @param factory The address of the factory contract.
     * @param tokenA The address of token A.
     * @param tokenB The address of token B.
     * @return The address of the pair contract.
     */
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);

        // Generate a unique salt based on the sorted token addresses
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));

        // Compute the init code hash for the pair contract
        bytes32 initialCodeHash = keccak256(type(MyswapPair).creationCode);

        return address(uint160(uint256(keccak256(abi.encodePacked(hex"ff", factory, salt, initialCodeHash)))));
    }

    /**
     * @dev Alternative implementation of `pairFor` with a hardcoded init code hash.
     * @param factory The address of the factory contract.
     * @param tokenA The address of token A.
     * @param tokenB The address of token B.
     * @return The address of the pair contract.
     */
    function pairFor2(address factory, address tokenA, address tokenB) internal pure returns (address) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);

        // Generate a unique salt based on the sorted token addresses
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));

        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            salt,
                            hex"073e1d5fa5b2ee84c33d687729cc43d2600ef9ca0d2f1d1befa9083e9ae91dbf"
                        )
                    )
                )
            )
        );
    }

    /**
     * @dev Sorts two token addresses in ascending order.
     * @param tokenA The address of token A.
     * @param tokenB The address of token B.
     * @return token0 The address of the token with the smaller address.
     * @return token1 The address of the token with the larger address.
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    /**
     * @dev Given an input amount of tokenIn and pair reserves, returns the output amount of tokenOut.
     * @param amountIn The input amount of tokenIn.
     * @param reserveIn The reserve of the tokenIn.
     * @param reserveOut The reserve of the tokenOut.
     * @return amountOut The output amount of tokenOut
     */
    function quote(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "INSUFFICIENT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");

        //  dy     y
        // --- =  ---
        //  dx     x
        amountOut = amountIn * reserveOut / reserveIn;
    }
}
