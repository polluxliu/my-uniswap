// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface IMyswapPair {
    function initialize(address _token0, address _token1) external;

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to) external;

    function getReserves() external returns (uint112, uint112);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
