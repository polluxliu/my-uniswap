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
}
