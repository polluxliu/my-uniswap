# **MY-UNISWAP**

**English | [中文文档](#中文文档)**

---

## English Documentation

**MY-UNISWAP** is a project that simulates the core functionality of **Uniswap**, aiming to gradually implement the decentralized exchange (DEX) logic starting with **Uniswap V1**. The project uses the **Foundry** framework for efficient smart contract development, testing, and deployment.

### **V1 Version**

**MY-UNISWAP V1** includes the following key features:

- **Factory Contract**: Deploys and manages multiple Exchange contracts, supporting trading pairs for different ERC20 tokens.
- **Exchange Contract**:
  - **Liquidity Provision and Removal**: Users can add or remove liquidity to the pool and receive LP token rewards.
  - **ETH ↔ Token Swap**: Users can swap ETH for a target ERC20 token.
  - **Token ↔ Token Swap**: Achieves swaps between different ERC20 tokens using ETH as an intermediary.
  - **Fee Mechanism**: A 1% fee is charged per swap, which is shared among liquidity providers.

### V2 Version

**MY-UNISWAP V2** introduces enhanced features and functionalities compared to V1, including support for token pairs, advanced fee structures, and flashloan capabilities. Below are the key features of V2:

**Core Contracts:**

- **MyswapFactory**: Deploys and manages MyswapPair contracts, enabling liquidity pools for token pairs.
- **MyswapPair**: Implements automated market maker (AMM) logic for token pairs.
- **MyswapRouter**: Provides an interface for adding/removing liquidity and conducting token swaps.

**Advanced Functionalities:**

- **Flashloan Support**: The `FlashloanBorrower` contract enables users to borrow assets without collateral for arbitrage, liquidation, or other use cases, provided the borrowed amount is repaid within the same transaction.
- **Improved Fee Structure**: Transaction fees are adjustable and designed to incentivize liquidity providers.
- **Token-to-Token Direct Swaps**: Facilitates direct swaps between two tokens without ETH as an intermediary.

**Library Modules:**

- **Math.sol**: Provides arithmetic utilities.
- **UQ112x112.sol**: Implements fixed-point math for precise calculations.
- **MyswapLibrary.sol**: Contains helper functions for price calculations and pair creation.

### **Technology Stack**

- **Solidity**: The programming language for smart contract development.
- **Foundry**: A high-performance development framework for building, testing, deploying, and debugging smart contracts.
- **OpenZeppelin**: Provides secure and reliable ERC20 standard contracts.
- **Solmate**: An optimized library that extends ERC20 functionality, including support for transfers to the zero address.

### **Directory Structure**

```plaintext
MY-UNISWAP/
│
├── src/                      # Source code directory
│   └── V1/                   # V1 version code
│       ├── Exchange.sol      # Core Exchange contract
│       ├── Factory.sol       # Factory contract for deploying Exchange
│       └── IExchange.sol     # Interface file
│       └── IFactory.sol      # Interface file
│
│   └── V2/                   # V2 version code
│       ├── libraries/        # Utility libraries for V2
│       │   ├── Math.sol      # Arithmetic utilities
│       │   ├── UQ112x112.sol # Fixed-point math
│       │   └── MyswapLibrary.sol # Helper functions
│       ├── FlashloanBorrower.sol # Flashloan contract
│       ├── MyswapFactory.sol # Factory for liquidity pairs
│       ├── MyswapPair.sol    # Liquidity pair contract
│       ├── MyswapRouter.sol  # Router for interactions
│       ├── IMyswapFactory.sol # Factory interface
│       ├── IMyswapPair.sol   # Pair interface
│       └── IMyswapFlashloan.sol # Flashloan interface
│
├── script/                   # Deployment scripts
│
├── test/                     # Test code
│   ├── Exchange.t.sol        # Unit tests for V1 Exchange contract
│   ├── MyswapPair.t.sol      # Unit tests for V2 Pair contract
│   ├── MyswapFactory.t.sol   # Unit tests for V2 Factory contract
│   └── FlashloanBorrower.t.sol # Unit tests for Flashloan contract
│
├── README.md                 # Project documentation
└── foundry.toml              # Foundry configuration file

```

## 中文文档

**MY-UNISWAP** 是一个模拟 **Uniswap** 核心功能的项目，旨在从 **Uniswap V1** 开始逐步实现去中心化交易所（DEX）的核心逻辑。项目使用 **Foundry** 框架进行开发、测试和部署，方便高效地构建和验证智能合约。

### **V1 版本**

**MY-UNISWAP V1** 包括以下主要功能：

- **Factory 合约**：用于部署并管理多个 Exchange 合约，支持不同 ERC20 Token 的交易对。
- **Exchange 合约**：
  - **流动性提供与移除**：用户可以向交易池添加或移除流动性，获得 LP Token 奖励。
  - **ETH ↔ Token 兑换**：用户可以使用 ETH 交换目标 ERC20 Token。
  - **Token ↔ Token 兑换**：通过中间的 ETH，实现不同 ERC20 Token 之间的交换。
  - **手续费机制**：每笔交易收取 1% 手续费，流动性提供者共享手续费收益。

### V2 版本

**MY-UNISWAP V2** 相较于 V1 引入了增强的功能和特性，包括对代币对的支持、先进的费用结构以及闪电贷功能。以下是 V2 的主要特性：

**核心合约：**

- **MyswapFactory**：部署和管理 MyswapPair 合约，为代币对创建流动性池。
- **MyswapPair**：实现代币对的自动做市商（AMM）逻辑。
- **MyswapRouter**：提供添加/移除流动性及进行代币交换的接口。

**高级功能：**

- **闪电贷支持**：`FlashloanBorrower` 合约允许用户在无需抵押的情况下借入资产，用于套利、清算或其他用途，但必须在同一交易中偿还借入金额。
- **改进的费用结构**：交易费用可调，旨在激励流动性提供者。
- **代币对直接交换**：支持在两个代币之间进行直接交换，无需以 ETH 作为中介。

**库模块：**

- **Math.sol**：提供算术工具。
- **UQ112x112.sol**：实现精确计算的定点数学。
- **MyswapLibrary.sol**：包含价格计算和代币对创建的辅助函数。

### **技术栈**

- **Solidity**：智能合约开发语言。
- **Foundry**：用于构建、测试、部署和调试智能合约的高效开发框架。
- **OpenZeppelin**：使用安全的 ERC20 标准合约。
- **Solmate**：一个经过优化的库，扩展了 ERC20 的功能，包括支持向零地址进行转账。

### **目录结构**

```plaintext
MY-UNISWAP/
│
├── src/                      # 源代码目录
│   └── V1/                   # V1 版本代码
│       ├── Exchange.sol      # 核心 Exchange 合约
│       ├── Factory.sol       # 用于部署 Exchange 的工厂合约
│       └── IExchange.sol     # Exchange 合约接口文件
│       └── IFactory.sol      # Factory 合约接口文件
│
│   └── V2/                   # V2 版本代码
│       ├── libraries/        # V2 的工具库
│       │   ├── Math.sol      # 算术工具
│       │   ├── UQ112x112.sol # 定点数学运算
│       │   └── MyswapLibrary.sol # 辅助函数
│       ├── FlashloanBorrower.sol # 闪电贷合约
│       ├── MyswapFactory.sol # 用于管理流动性池的工厂合约
│       ├── MyswapPair.sol    # 流动性对合约
│       ├── MyswapRouter.sol  # 用于交互的路由合约
│       ├── IMyswapFactory.sol # Factory 合约接口
│       ├── IMyswapPair.sol   # Pair 合约接口
│       └── IMyswapFlashloan.sol # 闪电贷接口
│
├── script/                   # 部署脚本
│
├── test/                     # 测试代码
│   ├── Exchange.t.sol        # V1 Exchange 合约的单元测试
│   ├── MyswapPair.t.sol      # V2 Pair 合约的单元测试
│   ├── MyswapFactory.t.sol   # V2 Factory 合约的单元测试
│   └── FlashloanBorrower.t.sol # 闪电贷合约的单元测试
│
├── README.md                 # 项目文档
└── foundry.toml              # Foundry 配置文件

```
