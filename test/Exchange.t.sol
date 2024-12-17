// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";
import {Exchange} from "../src/V1/Exchange.sol";

contract ExchangeTest is Test {
    MyToken public token;
    Exchange public exchange;
    address public userA;
    address public userB;

    /**
     * @notice 测试前置函数，会在 每个测试函数运行之前 自动执行，用于初始化测试环境。
     */
    function setUp() public {
        // 创建一个用户账户
        userA = makeAddr("UserA");

        // 创建一个用户账户
        userB = makeAddr("UserB");

        // console.log("userA: ", userA);

        // 模拟用户
        vm.startPrank(userA);

        // 部署 ERC20 代币，此时给 userA 100 ether 的 MY
        token = new MyToken("My-Token", "MY", 1000 ether);

        // 给 userA 一些 ETH
        vm.deal(userA, 1000 ether);

        // 给 userB 一些 ETH
        vm.deal(userB, 1000 ether);

        // 部署 Exchange 合约
        exchange = new Exchange(address(token));

        // 批准当前合约可以从 UserA 账户中转移代币
        token.approve(address(exchange), 1000 ether); // 因为代币的最小单位和以太坊的 wei 单位一样是 10^18，所以我们可以直接使用 ether 的单位表示法来简化代码。

        vm.stopPrank();
    }

    /**
     * @notice 测试函数（测试用例）
     */
    function test_addLiquidity() public {
        uint256 initialReserve = exchange.getTokenReserve();

        vm.prank(userA);

        // 添加流动性
        exchange.addLiquidity{value: 1 ether}(100 ether);

        // 验证合约的代币储备量
        uint256 finalReserve = exchange.getTokenReserve();
        assertEq(finalReserve, initialReserve + 100 ether, "Reserve did not increase correctly");

        // 验证用户的代币余额
        uint256 userBalance = token.balanceOf(userA);
        assertEq(userBalance, 900 ether, "User's balance did not decrease correctly");

        // 验证合约的 ETH 余额
        assertEq(address(exchange).balance, 1 ether);

        // 验证用户的 ETH 余额是否减少
        assertEq(userA.balance, 999 ether);
    }

    /**
     * @notice 测试函数（测试用例）
     */
    function test_getSpotPrice() public {
        vm.prank(userA);

        // 添加流动性
        exchange.addLiquidity{value: 1 ether}(100 ether);

        uint256 etherReserve = address(exchange).balance;

        uint256 tokenReserve = exchange.getTokenReserve();

        // ETH per token
        assertEq(
            exchange.getSpotPrice(etherReserve, tokenReserve), 0.01 ether, "ETH per token price calculation incorrect"
        );

        // token per ETH
        assertEq(
            exchange.getSpotPrice(tokenReserve, etherReserve), 100 ether, "TOken per eth price calculation incorrect"
        );
    }

    /**
     * @notice 测试函数（测试用例）
     */
    function test_getAmountOut() public {
        vm.prank(userA);

        // 添加流动性
        exchange.addLiquidity{value: 1 ether}(100 ether);

        uint256 ethOut = exchange.getEthOut(100 ether);

        console.log(ethOut);

        // assertEq(ethOut, 0.5 ether, "Incorrect ETH amount calculation");

        uint256 tokenOut = exchange.getTokensOut(1 ether);

        console.log(tokenOut);

        // assertEq(tokenOut, 50 ether, "Incorrect token amount calculation");
    }

    /**
     * @notice 测试函数（测试用例）
     */
    function test_LPTokens() public {
        // userA 添加流动性
        vm.prank(userA);
        uint256 liquidity = exchange.addLiquidity{value: 100 ether}(200 ether); // liquidity provider deposits 100 ethers and 200 tokens.

        // userA's liquidity is 100 * 1e18
        console.log("userA liquidity got:", liquidity);

        uint256 userBalanceBefore = token.balanceOf(userB);

        // userB swaps 10 ethers and expects to get at least 18 tokens.
        vm.prank(userB);
        exchange.swapEthForTokens{value: 10 ether}(18 ether);

        uint256 userBalanceAfter = token.balanceOf(userB);

        //      10 * 0.99
        // ------------------- * 200 = 18.0163785
        //   100 + 10 * 0.99
        console.log("userB swap %s eth for %s tokens ", 10 ether, userBalanceAfter - userBalanceBefore);

        // userA then removes its liquidity
        vm.prank(userA);
        (uint256 ethAmount, uint256 tokenAmount) = exchange.removeLiquidity(100 ether);
        console.log("userA got %s eth back and %s tokens back", ethAmount, tokenAmount);
    }
}
