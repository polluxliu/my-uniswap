// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface IMyswapPair {
    function initialize(address _token0, address _token1) external;

    function mint(address to) external returns (uint256 liquidity);

    function getReserves() external returns (uint112, uint112);
}
