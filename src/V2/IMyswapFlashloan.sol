// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface IMyswapFlashloan {
    function executeOperation(address sender, uint256 amount0Out, uint256 amount1Out, bytes calldata data) external;
}
