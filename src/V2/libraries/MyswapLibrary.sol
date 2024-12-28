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
     * @notice Used when adding liquidity to determine the proportional amount of the second token to add.
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

    /**
     * @dev Calculates the output amount of one token for a given input amount of another token in a pair.
     * @notice Used when performing a token swap to calculate how much of the output token
     *   will be received for a given input amount of the other token, considering trading fees.
     * @param amountIn The amount of input token provided for the swap.
     * @param reserveIn The reserve of the input token in the pool.
     * @param reserveOut The reserve of the output token in the pool.
     * @return amountOut The calculated amount of the output token after deducting fees.
     */
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "INSUFFICIENT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");

        //            dx*(1-f) * 1000
        //  dy =  ----------------------- * y
        //         [x + dx*(1-f)] * 1000

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;

        amountOut = numerator / denominator;
    }

    /**
     * @dev Calculates the output amounts of tokens for a given input amount and a specified swap path.
     * @notice This function traverses through a path of token pairs, calculating the output amount at each step
     *   based on the reserves of the token pairs and the provided input amount.
     * @param factory The address of the factory contract used to get token pair address.
     * @param amountIn The amount of the input token to swap.
     * @param path An array of token addresses representing the swap path (e.g., [tokenA, tokenB, tokenC]).
     * @return amounts An array of output amounts at each step in the path, where the last element is the final output amount.
     */
    function getAmountsOut(address factory, uint256 amountIn, address[] memory path)
        internal
        returns (uint256[] memory amounts)
    {
        require(path.length >= 2, "INVALID_PATH");

        amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        // Iterate through the path and calculate output amounts for each pair.
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    /**
     * @notice Calculates the required input amount for a desired output amount using the constant product formula
     * @dev Includes a 0.3% fee (997/1000)
     * @param amountOut The desired output amount
     * @param reserveIn The input token reserve
     * @param reserveOut The output token reserve
     * @return amountIn The required input amount (including 0.3% fee)
     */
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountIn)
    {
        require(amountOut > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");

        //            dx*(1-f) * 1000
        //  dy =  ----------------------- * y
        //         [x + dx*(1-f)] * 1000
        //
        //  =>
        //
        //            x * dy * 1000
        //  dx =  -------------------------
        //         (y - dy) * (1-f) * 1000

        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;

        // Add 1 to ensure sufficient input amount
        amountIn = (numerator / denominator) + 1;
    }

    /**
     * @notice Calculates the required input amounts for each swap in a multi-hop trade
     * @dev Works backwards from the desired output amount to calculate all required inputs
     * @param factory The factory contract address used to find pairs
     * @param amountOut The desired final output amount
     * @param path Array of token addresses defining the swap route
     * @return amounts Array where amounts[0] is the initial input amount needed and
     *                 amounts[1...n] are the subsequent output amounts,
     *                 with amounts[n] being the final amountOut
     */
    function getAmountsIn(address factory, uint256 amountOut, address[] memory path)
        internal
        returns (uint256[] memory amounts)
    {
        require(path.length >= 2, "INVALID_PATH");

        // Initialize array to store all amounts in the path
        amounts = new uint256[](path.length);

        // Set the final output amount
        amounts[amounts.length - 1] = amountOut;

        // Loop backwards through the path to calculate required input amounts
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);

            // Calculate required input amount for current step
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}
