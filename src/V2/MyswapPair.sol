// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "solmate/tokens/ERC20.sol";
import "./libraries/Math.sol";
import "./libraries/UQ112x112.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract MyswapPair is ERC20 {
    using UQ112x112 for uint224;

    /**
     * NOTE: The layout of following state variables is critical
     */

    // Minimum liquidity that must always remain in the pool
    uint256 constant MINIMUM_LIQUIDITY = 1000;

    // Addresses of the two tokens in the pair
    address public token0;
    address public token1;

    // Reserve amounts for token0 and token1, stored in uint112 to save gas
    uint112 private reserve0;
    uint112 private reserve1;

    // This keeps track of the timestamp of the last update, ensuring that time-based calculations are accurate
    uint32 private blockTimestampLast;

    // These variables store the cumulative prices of token0 and token1, respectively
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    /**
     * @dev Constructor for the pair contract.
     * @param _token0 Address of the first token in the pair.
     * @param _token1 Address of the second token in the pair.
     */
    constructor(address _token0, address _token1) ERC20("MY-UNISWAP", "MU", 18) {
        token0 = _token0;
        token1 = _token1;
    }

    /**
     * @dev Mints liquidity tokens to the sender based on the provided token amounts.
     */
    function mint() public {
        (uint112 _reserve0, uint112 _reserve1) = getReserves();

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        // Calculate how many tokens were added to the pool
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        uint256 liquidity;

        if (totalSupply == 0) {
            // Calculate initial liquidity using geometric mean
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;

            // Lock a small portion of liquidity tokens
            // NOTE: To prevent the pool from being completely drained in future operations.
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            // Calculate liquidity based on existing reserves and total supply
            liquidity = Math.min(amount0 * totalSupply / reserve0, amount1 * totalSupply / reserve1);
        }

        // Ensure liquidity is greater than zero
        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY_MINTED");

        // Mint liquidity tokens to the sender
        _mint(msg.sender, liquidity);

        // Update the reserves to reflect the new state
        _updateReserves(balance0, balance1, _reserve0, _reserve1);
    }

    /**
     * @dev Burns liquidity tokens and returns the underlying tokens to the sender.
     */
    function burn() public {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        // Get the liquidity tokens held by the pair contract
        uint256 liquidity = balanceOf[address(this)];

        // Calculate how much of each token corresponds to the liquidity being burned
        uint256 amount0 = (liquidity * balance0) / totalSupply;
        uint256 amount1 = (liquidity * balance1) / totalSupply;

        // Ensure there is sufficient liquidity to burn
        require(amount0 > 0 && amount1 > 0, "INSUFFICIENT_LIQUIDITY_BURNED");

        // Burn the liquidity tokens from the contract
        _burn(address(this), liquidity);

        // Transfer the corresponding tokens to the sender
        _safeTransfer(token0, msg.sender, amount0);
        _safeTransfer(token1, msg.sender, amount1);

        // Update the reserves after the burn
        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        _updateReserves(balance0, balance1, _reserve0, _reserve1);
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to) public {
        // Step 1: Checks

        // Ensure that at least one of the output amounts is greater than zero
        require(amount0Out > 0 || amount1Out > 0, "INSUFFICIENT_OUTPUT_AMOUNT");

        // Get the current reserves of token0 and token1
        (uint112 _reserve0, uint112 _reserve1) = getReserves();

        // Ensure there is enough liquidity in the pool for the requested output
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "INSUFFICIENT_LIQUIDITY");

        // Calculate the new balances after the swap
        uint256 balance0 = IERC20(token0).balanceOf(address(this)) - amount0Out;
        uint256 balance1 = IERC20(token1).balanceOf(address(this)) - amount1Out;

        // Ensure the product of reserves (k) is maintained or increased (to prevent invalid swaps)
        require(balance0 * balance1 >= _reserve0 * _reserve1, "K_INVARIANT_VIOLATION");

        // Step 2: Effects

        // Update reserves after the transfer to reflect the new state
        _updateReserves(balance0, balance1, _reserve0, _reserve1);

        // Step 3: Interactions

        // Perform the token transfers to the recipient
        _safeTransfer(token0, to, amount0Out);
        _safeTransfer(token1, to, amount1Out);
    }

    /**
     * @dev Returns the current reserves of token0 and token1.
     * @return The reserves of token0 and token1.
     */
    function getReserves() public view returns (uint112, uint112) {
        return (reserve0, reserve1);
    }

    /**
     * @notice The function is typically called in the following scenarios: Liquidity changes, Swap operations
     * @dev Updates the reserves to reflect the current balances in the contract.
     * @dev Updates cumulative prices in line with changes in the reserves over time.
     * @param _balance0 The new balance of token0.
     * @param _balance1 The new balance of token1.
     * @param _lastReserve0 The last recorded reserve of token0.
     * @param _lastReserve1 The last recorded reserve of token1.
     */
    function _updateReserves(uint256 _balance0, uint256 _balance1, uint112 _lastReserve0, uint112 _lastReserve1)
        private
    {
        // Ensure that the balances do not overflow the uint112 type
        require(_balance0 <= type(uint112).max && _balance1 <= type(uint112).max, "BALANCE_OVERFLOW");

        uint32 blockTimestamp;

        unchecked {
            // Get the current block timestamp as uint32
            blockTimestamp = uint32(block.timestamp);

            // Calculate the time elapsed since the last update (in seconds)
            // NOTE: This will cause an overflow, but such an overflow is expected.
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;

            // Update the TWAP
            if (timeElapsed > 0 && _lastReserve0 > 0 && _lastReserve1 > 0) {
                // NOTE: * operation never overflows
                // NOTE: + operation will cause an overflow (almost impossible though) which is expected

                // Update the cumulative price for token0 using the previous reserve values and time elapsed
                price0CumulativeLast += UQ112x112.encode(_lastReserve1).uqdiv(_lastReserve0) * timeElapsed;

                // Update the cumulative price for token1 using the previous reserve values and time elapsed
                price1CumulativeLast += UQ112x112.encode(_lastReserve0).uqdiv(_lastReserve1) * timeElapsed;
            }
        }

        // Update the current reserves (cast the balances to uint112 to fit the reserve variables)
        reserve0 = uint112(_balance0);
        reserve1 = uint112(_balance1);

        // Update the block timestamp for the last recorded time
        blockTimestampLast = blockTimestamp;
    }

    /**
     * @dev Safely transfers tokens to the recipient.
     * @param token The address of the token to transfer.
     * @param to The recipient address.
     * @param value The amount of tokens to transfer.
     */
    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }
}
