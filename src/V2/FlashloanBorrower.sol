// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "./IMyswapPair.sol";
import "./libraries/MyswapLibrary.sol";

contract FlashloanBorrower {
    address public factory;

    constructor(address _factory) {
        factory = _factory;
    }

    /**
     * @notice Initiates a flash loan from a specified MyswapPair
     * @param pair Address of the Myswap pair contract to borrow from
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param amountAOut Amount of tokenA to borrow
     * @param amountBOut Amount of tokenB to borrow
     * @dev This function requests flash loans in the correct order based on the pair's token0/token1
     */
    function loan(address pair, address tokenA, address tokenB, uint256 amountAOut, uint256 amountBOut) external {
        // Query the ordered tokens from the pair contract
        address token0 = IMyswapPair(pair).token0();
        address token1 = IMyswapPair(pair).token1();

        // Validate that the requested tokens match the pair's tokens (in either order)
        require(
            (tokenA == token0 && tokenB == token1) || (tokenA == token1 && tokenB == token0), "Tokens do not match pair"
        );

        // Convert the requested amounts to the pair's token0/token1 order
        (uint256 amount0Out, uint256 amount1Out) =
            token0 == tokenA ? (amountAOut, amountBOut) : (amountBOut, amountAOut);

        // When no data is required,
        // Creates a dynamic bytes array with a length of 1, initialized with a default value of 0x00 (all zeros).
        bytes memory data = new bytes(1);

        // Request the flash loan by calling swap on the pair
        IMyswapPair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    /**
     * @notice Callback function executed by the pair contract during flash loan
     * @param sender The address of this borrower contract itself
     * @param amount0Out Amount of token0 borrowed
     * @param amount1Out Amount of token1 borrowed
     * @param data Arbitrary data passed through from loan() function
     * @dev Must repay the loan plus fees before this function completes
     */
    function executeOperation(address sender, uint256 amount0Out, uint256 amount1Out, bytes calldata data) external {
        // Verify tokens were actually borrowed
        require(amount0Out > 0 || amount1Out > 0, "No tokens borrowed");

        // Identify the tokens being borrowed
        address token0 = IMyswapPair(msg.sender).token0();
        address token1 = IMyswapPair(msg.sender).token1();

        // Ensure that msg.sender is a swap pair
        assert(msg.sender == MyswapLibrary.pairFor(factory, token0, token1));

        // Calculate fees for each borrowed token
        // The + 1 is a safety margin to handle rounding issues in Solidity's integer arithmetic.
        uint256 fee0 = (amount0Out * 3) / 997 + 1;
        uint256 fee1 = (amount1Out * 3) / 997 + 1;

        // Calculate total amounts to be repaid including fees
        uint256 amount0ToRepay = amount0Out + fee0;
        uint256 amount1ToRepay = amount1Out + fee1;

        // Ignore the data argument as no data is required

        // Execute custom logic, e.g., arbitrage or liquidation

        // Repay the borrowed tokens
        if (amount0Out > 0) IERC20(token0).transfer(msg.sender, amount0ToRepay);
        if (amount1Out > 0) IERC20(token1).transfer(msg.sender, amount1ToRepay);
    }
}
