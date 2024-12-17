// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "./Exchange.sol";

/**
 * @title Exchange factory
 * @author @pollux_tw
 * @notice Factory contract for creating and managing Exchange contracts
 */
contract Factory {
    // Mapping from ERC20 token address to the deployed Exchange contract address
    mapping(address => address) public tokenToExchange;

    // Event emitted when a new Exchange contract is created
    event ExchangeCreated(address indexed token, address exchange);

    /**
     * @notice Deploy a new Exchange contract for the given ERC20 token
     * @dev Prevents duplicate deployments for the same token
     * @param _token The address of the ERC20 token
     * @return exchangeAddress The address of the newly created Exchange contract
     */
    function createExchange(address _token) external returns (address exchangeAddress) {
        require(_token != address(0), "Invalid token address");

        require(tokenToExchange[_token] == address(0), "Exchange already exists");

        // Deploy a new Exchange contract
        Exchange exchange = new Exchange(_token);

        exchangeAddress = address(exchange);

        // Map the token to its Exchange
        tokenToExchange[_token] = exchangeAddress;

        // Emit event for tracking
        emit ExchangeCreated(_token, exchangeAddress);
    }

    /**
     * @notice Retrieve the Exchange contract for a given ERC20 token
     * @param _token The address of the ERC20 token
     * @return The address of the associated Exchange contract
     */
    function getExchange(address _token) external view returns (address) {
        return tokenToExchange[_token];
    }
}
