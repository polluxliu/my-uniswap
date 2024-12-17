// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface IFactory {
    function getExchange(address _token) external returns (address);
}
