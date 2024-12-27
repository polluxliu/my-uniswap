// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface IMyswapFactory {
    function pairs(address tokenA, address tokenB) external pure returns (address);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}
