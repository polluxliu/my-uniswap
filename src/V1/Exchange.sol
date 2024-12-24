// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.24;

import "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import "./IFactory.sol";
import "./IExchange.sol";

/**
 * @title Exchange
 * @author @pollux_tw
 * @dev A simple decentralized exchange (DEX) contract to swap ETH and ERC20 tokens.
 */
contract Exchange is ERC20 {
    // Address of the ERC20 token this exchange supports
    address public token;

    // Address of the factory contract that deployed this Exchange contract
    address public factory;

    event AddLiquidity(address indexed provider, uint256 ethAmount, uint256 tokenAmount, uint256 lpTokens);
    event RemoveLiquidity(address indexed provider, uint256 lpTokens, uint256 ethAmount, uint256 tokenAmount);
    event SwapETHForTokens(address indexed user, uint256 ethAmount, uint256 tokenAmount);
    event SwapTokensForETH(address indexed user, uint256 tokenAmount, uint256 ethAmount);
    event SwapTokensForTokens(address indexed sender, address indexed targetToken, uint256 tokensIn, uint256 tokensOut);

    /**
     * @dev Constructor to initialize the Exchange contract with a token address.
     * @param _token The address of the ERC20 token to be traded in this exchange.
     */
    constructor(address _token) ERC20("MY-UNISWAP", "MU") {
        require(_token != address(0), "Invalid token address");

        // Set the ERC20 token address that this Exchange contract will trade
        token = _token;

        // Set the factory address to the caller of this constructor, which should be the Factory contract
        factory = msg.sender;
    }

    /**
     * @notice Add liquidity to the exchange by depositing tokens and ETH.
     * @dev Users transfer `_tokenAmount` of tokens and the ETH is sent along with the call.
     * @param _tokenAmount The amount of tokens the user wants to add as liquidity.
     */
    function addLiquidity(uint256 _tokenAmount) external payable returns (uint256 liquidity) {
        require(_tokenAmount > 0 && msg.value > 0, "Invalid input amounts");

        uint256 tokensToTransfer;

        uint256 tokenReserve = getTokenReserve();

        if (tokenReserve == 0) {
            // Initial liquidity: accept full token amount and mint liquidity tokens equal to ETH amount
            tokensToTransfer = _tokenAmount;

            // Use the amount of deposited ethers as liquidity
            liquidity = msg.value;
        } else {
            uint256 ethReserve = address(this).balance - msg.value;

            // Calculate token amount based on the current reserves ratio
            //   y         dy
            // -----  =  ------
            //   x         dx

            // Not depositing all tokens provided by user but only an amount calculated based on current reserves ratio.
            tokensToTransfer = (msg.value * tokenReserve) / ethReserve;

            require(_tokenAmount >= tokensToTransfer, "Insufficient token amount");

            // Mint liquidity tokens proportional to the ETH contribution
            //   dT         dx
            // ------- = -------
            //  Total       x
            //        dx
            // dT = ----- * Total
            //        x
            liquidity = (msg.value * totalSupply()) / ethReserve;
        }

        // Mint LP tokens for the user
        _mint(msg.sender, liquidity);

        // Transfer tokens from the user to the contract
        IERC20(token).transferFrom(msg.sender, address(this), tokensToTransfer);

        emit AddLiquidity(msg.sender, msg.value, tokensToTransfer, liquidity);
    }

    /**
     * @notice Remove liquidity from the pool and receive proportional ETH and tokens.
     * @dev Burns LP tokens from the user and transfers ETH and tokens proportional to their LP share.
     * @param _lpAmount The amount of LP tokens to burn (liquidity to remove).
     * @return ethAmount The amount of ETH returned to the user.
     * @return tokenAmount The amount of tokens returned to the user.
     */
    function removeLiquidity(uint256 _lpAmount) external returns (uint256 ethAmount, uint256 tokenAmount) {
        require(_lpAmount > 0, "Invalid LP token amount");

        // Calculate the proportional amounts of ETH and tokens

        //        dT
        // dx = --------- * x
        //        Total
        ethAmount = _lpAmount * address(this).balance / totalSupply();
        //         dx            dt
        // dy = ------- * y = --------- * y
        //         x            Total
        tokenAmount = _lpAmount * getTokenReserve() / totalSupply();

        // Burn the LP tokens from the sender
        _burn(msg.sender, _lpAmount);

        // Transfer ETH to the user
        payable(msg.sender).transfer(ethAmount);

        // Transfer tokens to the user
        IERC20(token).transfer(msg.sender, tokenAmount);

        emit RemoveLiquidity(msg.sender, _lpAmount, ethAmount, tokenAmount);
    }

    /**
     * @notice Swap ETH for tokens and send the tokens to the caller.
     * @dev This function acts as a wrapper for the internal `_swapEthForTokens` function.
     * @param _minTokens The minimum number of tokens the sender expects to receive to prevent front-running or slippage.
     */
    function swapEthForTokens(uint256 _minTokens) external payable {
        _swapEthForTokens(_minTokens, msg.sender);
    }

    /**
     * @notice Swap ETH for tokens and send the tokens to a specific recipient.
     * @dev This function allows specifying a recipient other than the caller.
     * @param _minTokens The minimum number of tokens expected to receive.
     * @param _recipient The address of the recipient who will receive the tokens.
     */
    function swapEthForTokens(uint256 _minTokens, address _recipient) external payable returns (uint256 tokensOut) {
        tokensOut = _swapEthForTokens(_minTokens, _recipient);
    }

    /**
     * @notice Internal function to handle the logic for swapping ETH to tokens.
     * @dev Calculates the amount of tokens to send based on the ETH sent and reserves.
     *      Ensures the output tokens are not less than `_minTokens`.
     * @param _minTokens The minimum number of tokens the sender expects to receive to prevent front-running or slippage.
     * @param _recipient The address of the recipient who will receive the tokens.
     */
    function _swapEthForTokens(uint256 _minTokens, address _recipient) private returns (uint256 tokensOut) {
        require(msg.value > 0, "ETH amount must be greater than zero");

        // Get the current token reserve
        uint256 tokenReserve = getTokenReserve();

        // NOTE: by the time the function is called the ethers sent have already been added to its balance
        //       we need to subtract msg.value from contract’s balance to get the previous ETH balance

        // Calculate the number of tokens to be bought based on ETH sent
        tokensOut = _calculateAmountOut(msg.value, address(this).balance - msg.value, tokenReserve);

        require(tokensOut >= _minTokens, "Insufficent output amount");

        // Transfer the calculated tokens to the sender
        IERC20(token).transfer(_recipient, tokensOut);

        emit SwapETHForTokens(_recipient, msg.value, tokensOut);
    }

    /**
     * @notice Swap tokens for ETH.
     * @dev Calculates the amount of ETH to send based on tokens sold and reserves.
     *      Ensures the output ETH is not less than `_minEth`.
     * @param _tokensIn The amount of tokens the sender wants to exchange for ETH.
     * @param _minEth The minimum amount of ETH the sender expects to receive.
     */
    function swapTokensForEth(uint256 _tokensIn, uint256 _minEth) external {
        require(_tokensIn > 0, "Token amount must be greater than zero");

        // Get the current token reserve
        uint256 tokenReserve = getTokenReserve();

        // Calculate the amount of ETH to send based on tokens in
        uint256 ethOut = _calculateAmountOut(_tokensIn, tokenReserve, address(this).balance);

        require(ethOut >= _minEth, "Insufficent output amount");

        // Transfer `_tokensIn` tokens from the user to this contract
        IERC20(token).transferFrom(msg.sender, address(this), _tokensIn);

        // Transfer the calculated ETH to the sender
        payable(msg.sender).transfer(ethOut);

        emit SwapTokensForETH(msg.sender, _tokensIn, ethOut);
    }

    /**
     * @notice Swap tokens for tokens by converting the input tokens to ETH and then swapping ETH for the target tokens.
     * @dev This function uses ETH as the intermediary asset to facilitate the token-to-token swap.
     * @param _tokensIn The number of input tokens provided by the user.
     * @param _minTokens The minimum number of target tokens the user expects to receive.
     * @param _targetToken The address of the target ERC20 token the user wants to receive.
     */
    function swapTokensForTokens(uint256 _tokensIn, uint256 _minTokens, address _targetToken) external {
        require(_tokensIn > 0, "Token input must be greater than zero");

        require(_targetToken != address(0) && _targetToken != token, "Invalid target token");

        // Get the target exchange address for the desired token
        address exchange = IFactory(factory).getExchange(_targetToken);

        require(exchange != address(this) && exchange != address(0), "Invalid exchange address");

        // Get the current token reserve
        uint256 tokenReserve = getTokenReserve();

        // Calculate the amount of ETH to send based on tokens in
        uint256 ethOut = _calculateAmountOut(_tokensIn, tokenReserve, address(this).balance);

        require(ethOut > 0, "ETH output must be greater than zero");

        // Transfer `_tokensIn` tokens from the user to this contract
        IERC20(token).transferFrom(msg.sender, address(this), _tokensIn);

        // Send the ETH to the target exchange and perform the swap to target tokens
        uint256 tokensOut = IExchange(exchange).swapEthForTokens{value: ethOut}(_minTokens, msg.sender);

        emit SwapTokensForTokens(msg.sender, _targetToken, _tokensIn, tokensOut);
    }

    /**
     * @notice Get the spot price ratio of input to output reserves.
     * @dev Calculates the price as inputReserve/outputReserve * 1e18 for scaling.
     * @param _inputReserve The reserve amount of the input asset.
     * @param _outputReserve The reserve amount of the output asset.
     * @return The price of the input asset in terms of the output asset.
     */
    function getSpotPrice(uint256 _inputReserve, uint256 _outputReserve) external pure returns (uint256) {
        require(_inputReserve > 0 && _outputReserve > 0, "Invalid reserves");
        return (_inputReserve * 1e18) / _outputReserve;
    }

    /**
     * @notice Get the current token reserve held by the contract.
     * @return The balance of tokens in the contract.
     */
    function getTokenReserve() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @notice Calculate the token amount obtainable for a given amount of ETH.
     * @dev Useful for displaying price estimates before executing a swap.
     * @param _ethIn The amount of ETH being sold.
     * @return The equivalent token amount based on the current reserves.
     */
    function getTokensOut(uint256 _ethIn) external view returns (uint256) {
        require(_ethIn > 0, "ETH input must be greater than 0");

        uint256 tokenReserve = getTokenReserve();

        return _calculateAmountOut(_ethIn, address(this).balance, tokenReserve);
    }

    /**
     * @notice Calculate the ETH amount obtainable for a given amount of tokens.
     * @dev Useful for displaying price estimates before executing a swap.
     * @param _tokensIn The amount of tokens being sold.
     * @return The equivalent ETH amount based on the current reserves.
     */
    function getEthOut(uint256 _tokensIn) external view returns (uint256) {
        require(_tokensIn > 0, "Token input must be greater than 0");

        uint256 tokenReserve = getTokenReserve();

        return _calculateAmountOut(_tokensIn, tokenReserve, address(this).balance);
    }

    /**
     * @notice Calculate the output amount for a given input amount using constant product formula.
     * @dev Formula: dy = (inputAmount * outputReserve) / (inputReserve + inputAmount)
     *      It ensures that the product of reserves remains constant.
     * @param _inputAmount The amount of input asset being traded.
     * @param _inputReserve The reserve amount of the input asset.
     * @param _outputReserve The reserve amount of the output asset.
     * @return The calculated output amount based on the reserves and input amount.
     */
    function _calculateAmountOut(uint256 _inputAmount, uint256 _inputReserve, uint256 _outputReserve)
        private
        pure
        returns (uint256)
    {
        require(_inputReserve > 0 && _outputReserve > 0, "Invalid reserves");

        // Without fees
        //        y * dx
        // dy = ----------
        //        x + dx
        // return (outputReserve * inputAmount) / (inputReserve + inputAmount);

        // With fees, takes 1% in fees from each swap
        //        y * (dx * 0.99)            y * (dx * 99)
        // dy = ------------------- = -------------------------
        //        x + (dx * 0.99)       (x * 100) + (dx * 99)
        return (_outputReserve * _inputAmount * 99) / (_inputReserve * 100 + _inputAmount * 99);
    }
}
