// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface IExchange {
    function swapEthForTokens(uint256 _minTokens, address _recipient) external payable returns (uint256 tokensOut);
}
