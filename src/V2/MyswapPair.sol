// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "solmate/tokens/ERC20.sol";
import "./libraries/Math.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract MyswapPair is ERC20 {
    // Addresses of the two tokens in the pair
    address public token0;
    address public token1;

    // Reserve amounts for token0 and token1, stored in uint112 to save gas
    uint112 private reserve0;
    uint112 private reserve1;

    // Minimum liquidity that must always remain in the pool
    uint256 constant MINIMUM_LIQUIDITY = 1000;

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
        _update(balance0, balance1);
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

        _update(balance0, balance1);
    }

    /**
     * @dev Returns the current reserves of token0 and token1.
     * @return The reserves of token0 and token1.
     */
    function getReserves() public view returns (uint112, uint112) {
        return (reserve0, reserve1);
    }

    /**
     * @dev Updates the reserves to reflect the current balances in the contract.
     * @param _balance0 The new balance of token0.
     * @param _balance1 The new balance of token1.
     */
    function _update(uint256 _balance0, uint256 _balance1) private {
        reserve0 = uint112(_balance0);
        reserve1 = uint112(_balance1);
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
