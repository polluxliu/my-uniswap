// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "./libraries/MyswapLibrary.sol";
import "./IMyswapFactory.sol";
import "./IMyswapPair.sol";

contract MyswapRouter {
    IMyswapFactory factory;

    /**
     * @dev Constructor to initialize the router with the factory address.
     * @param _factory The address of the factory contract.
     */
    constructor(address _factory) {
        factory = IMyswapFactory(_factory);
    }

    /**
     * @dev Adds liquidity to the pool for a given token pair.
     *      If the pair does not exist, it creates the pair in the factory.
     * @param tokenA The address of token A.
     * @param tokenB The address of token B.
     * @param amountADesired The desired amount of token A to provide.
     * @param amountBDesired The desired amount of token B to provide.
     * @param amountAMin The minimum amount of token A to provide.
     * @param amoutBMin The minimum amount of token B to provide.
     * @param to The address to receive liquidity tokens.
     * @return amountA The final amount of token A added as liquidity.
     * @return amountB The final amount of token B added as liquidity.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amoutBMin,
        address to
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        // If the pair doesn't exist, create it in the factory.
        if (factory.pairs(tokenA, tokenB) == address(0)) {
            factory.createPair(tokenA, tokenB);
        }

        // Calculate the optimal amounts of token A and token B to add.
        (amountA, amountB) = _calculateLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amoutBMin);

        // Get the pair address for the token pair.
        address pair = MyswapLibrary.pairFor(address(factory), tokenA, tokenB);

        // Transfer tokens from the sender to the pair contract.
        _safeTransferFrom(tokenA, msg.sender, pair, amountA);
        _safeTransferFrom(tokenB, msg.sender, pair, amountB);

        // Mint liquidity tokens and assign them to the recipient.
        liquidity = IMyswapPair(pair).mint(to);
    }

    /**
     * @dev Removes liquidity for a given token pair and transfers the underlying tokens to the specified address.
     * @param tokenA The address of token A.
     * @param tokenB The address of token B.
     * @param liquidity The amount of liquidity tokens to remove.
     * @param amountAMin The minimum amount of `tokenA` that must be received.
     * @param amountBMin The minimum amount of `tokenB` that must be received.
     * @param to The address to which the underlying tokens will be sent.
     * @return amountA The amount of `tokenA` returned to the specified address.
     * @return amountB The amount of `tokenB` returned to the specified address.
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) external returns (uint256 amountA, uint256 amountB) {
        // Get the pair address for the token pair.
        address pair = MyswapLibrary.pairFor(address(factory), tokenA, tokenB);

        // Transfer liquidity tokens from the sender to the pair contract.
        IMyswapPair(pair).transferFrom(msg.sender, pair, liquidity);

        // Burn liquidity tokens and get the amounts of token A and token B to return.
        (uint256 amount0, uint256 amount1) = IMyswapPair(pair).burn(to);
        (address token0,) = MyswapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);

        require(amountA >= amountAMin, "INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "INSUFFICIENT_B_AMOUNT");
    }

    /**
     * @dev Calculates the optimal amounts of token A and token B to add as liquidity.
     * @param tokenA The address of token A.
     * @param tokenB The address of token B.
     * @param amountADesired The desired amount of token A to provide.
     * @param amountBDesired The desired amount of token B to provide.
     * @param amountAMin The minimum amount of token A to provide.
     * @param amountBMin The minimum amount of token B to provide.
     * @return amountA The final amount of token A to add.
     * @return amountB The final amount of token B to add.
     */
    function _calculateLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) private returns (uint256 amountA, uint256 amountB) {
        // Fetch the reserves of token A and token B from the pair contract.
        (uint256 reserveA, uint256 reserveB) = MyswapLibrary.getReserves(address(factory), tokenA, tokenB);

        // If no reserves exist, use the desired amounts directly.
        if (reserveA == 0 && reserveB == 0) {
            return (amountADesired, amountBDesired);
        }

        // Calculate the optimal amount of token B based on the reserve ratio.
        uint256 amountBOptimal = MyswapLibrary.quote(amountADesired, reserveA, reserveB);
        if (amountBOptimal <= amountBDesired) {
            require(amountBOptimal >= amountBMin, "INSUFFICIENT_B_AMOUNT");
            return (amountADesired, amountBOptimal);
        }

        // Calculate the optimal amount of token A based on the reserve ratio.
        uint256 amountAOptimal = MyswapLibrary.quote(amountBDesired, reserveB, reserveA);
        // NOTE: As here is the last possibility, we use assert instead of if statement. If this condition fails, the transaction will revert.
        assert(amountAOptimal <= amountADesired);
        require(amountAOptimal >= amountAMin, "INSUFFICIENT_A_AMOUNT");
        return (amountAOptimal, amountBDesired);
    }

    /**
     * @dev Safely transfers tokens from one address to another using the ERC20 `transferFrom` method.
     * @param token The address of the token contract.
     * @param from The address of the sender.
     * @param to The address of the recipient.
     * @param amount The amount of tokens to transfer.
     */
    function _safeTransferFrom(address token, address from, address to, uint256 amount) private {
        require(token != address(0), "INVALID_TOKEN_ADDRESS");
        require(from != address(0), "INVALID_FROM_ADDRESS");
        require(to != address(0), "INVALID_TO_ADDRESS");

        (bool success, bytes memory data) =
            token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    /**
     * @notice Swaps an exact amount of input tokens for output tokens, requiring minimum output amount
     * @dev Performs chained swaps through multiple pairs based on the path
     * @param amountIn The amount of input tokens to send
     * @param amountOutMin The minimum amount of output tokens that must be received
     * @param path An array of token addresses representing the swap path
     * @param to The address that will receive the output tokens
     * @return amounts An array where amounts[0] is the input amount and
     *                 amounts[1...n] are the output amounts for each swap step
     */
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to)
        external
        returns (uint256[] memory amounts)
    {
        // The input amount and subsequent output amounts for the entire swap path
        amounts = MyswapLibrary.getAmountsOut(address(factory), amountIn, path);

        // Verify the final amount meets the minimum requirement
        require(amounts[amounts.length - 1] >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

        // Transfer the input tokens from sender to the first pair
        _safeTransferFrom(path[0], msg.sender, MyswapLibrary.pairFor(address(factory), path[0], path[1]), amounts[0]);

        // Execute the swap chain
        _swap(amounts, path, to);
    }

    /**
     * @notice Internal function to execute a series of swaps through multiple pairs
     * @dev For each step in the path, it calculates the input/output amounts and performs the swap
     * @param amounts Array of amounts for each swap in the path
     * @param path Array of token addresses defining the swap route
     * @param to Final recipient of the swapped tokens
     */
    function _swap(uint256[] memory amounts, address[] memory path, address to) private {
        for (uint256 i = 1; i < path.length; i++) {
            // Get the input and output token addresses for this step
            (address input, address output) = (path[i - 1], path[i]);

            // Get the output amount for this step
            uint256 amountOut = amounts[i];

            // Determine which token is token0 in the pair
            (address token0,) = MyswapLibrary.sortTokens(input, output);

            // Calculate amount0Out and amount1Out based on which token is token0
            (uint256 amount0Out, uint256 amount1Out) =
                input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));

            // If this is not the final swap, the recipient is the next pair
            // Otherwise, it's the final recipient specified in the parameters
            address _to = i < path.length - 1 ? MyswapLibrary.pairFor(address(factory), output, path[i + 1]) : to;

            // Execute the swap through the pair contract
            IMyswapPair(MyswapLibrary.pairFor(address(factory), input, output)).swap(amount0Out, amount1Out, _to);
        }
    }
}
