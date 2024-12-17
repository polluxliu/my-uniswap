// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.24;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @title A basic ERC20 token implementation
 * @author @pollux_tw
 * @notice This contract implements a custom ERC20 token with an initial supply
 */
contract MyToken is ERC20 {
    /**
     * @notice Constructor function to initialize the token
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param initialSupply The initial supply of tokens to mint
     */
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        // Mints `initialSupply` tokens to the contract deployer
        _mint(msg.sender, initialSupply);
    }
}
