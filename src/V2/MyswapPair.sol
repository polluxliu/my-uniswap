// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./libraries/Math.sol";

// interface IERC20 {
//     function balanceOf(address account) external view returns (uint256);
// }

error InsufficientLiquidityMinted();

contract MyswapPair is ERC20 {
    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;

    uint256 constant MINIMUM_LIQUIDITY = 1000;

    constructor(address _token0, address _token1) ERC20("MY-UNISWAP", "MU") {
        token0 = _token0;
        token1 = _token1;
    }

    function mint() public {
        (uint112 _reserve0, uint112 _reserve1) = getReserves();

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        uint256 liquidity;

        if (totalSupply() == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(amount0 * totalSupply() / reserve0, amount1 * totalSupply() / reserve1);
        }

        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY_MINTED");

        _mint(msg.sender, liquidity);

        _update(balance0, balance1);
    }

    function _update(uint256 _balance0, uint256 _balance1) private {
        reserve0 = uint112(_balance0);
        reserve1 = uint112(_balance1);
    }

    function getReserves() public view returns (uint112, uint112) {
        return (reserve0, reserve1);
    }
}
