# **MY-UNISWAP**

**English | [中文文档](#中文文档)**

---

## English Documentation

**MY-UNISWAP** is a project that simulates the core functionality of **Uniswap**, aiming to gradually implement the decentralized exchange (DEX) logic starting with **Uniswap V1**. The project uses the **Foundry** framework for efficient smart contract development, testing, and deployment.

### **V1 Version**

**MY-UNISWAP V1** includes the following key features:

- **Factory Contract**: Deploys and manages multiple Exchange contracts, supporting trading pairs for different ERC20 tokens.
- **Exchange Contract** (**V1 Version**):
  - **Liquidity Provision and Removal**: Users can add or remove liquidity to the pool and receive LP token rewards.
  - **ETH ↔ Token Swap**: Users can swap ETH for a target ERC20 token.
  - **Token ↔ Token Swap**: Achieves swaps between different ERC20 tokens using ETH as an intermediary.
  - **Fee Mechanism**: A 1% fee is charged per swap, which is shared among liquidity providers.

### **Technology Stack**

- **Solidity**: The programming language for smart contract development.
- **Foundry**: A high-performance development framework for building, testing, deploying, and debugging smart contracts.
- **OpenZeppelin**: Provides secure and reliable ERC20 standard contracts.

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
├── script/                   # Deployment scripts
│   └── Deploy.s.sol          # Foundry script for contract deployment
│
├── test/                     # Test code
│   ├── Exchange.t.sol        # Unit tests for Exchange contract
│   └── Factory.t.sol         # Unit tests for Factory contract
│
├── README.md                 # Project documentation
└── foundry.toml              # Foundry configuration file

```

## 中文文档

**MY-UNISWAP** 是一个模拟 **Uniswap** 核心功能的项目，旨在从 **Uniswap V1** 开始逐步实现去中心化交易所（DEX）的核心逻辑。项目使用 **Foundry** 框架进行开发、测试和部署，方便高效地构建和验证智能合约。

### **V1 版本**

**MY-UNISWAP V1** 包括以下主要功能：

- **Factory 合约**：用于部署并管理多个 Exchange 合约，支持不同 ERC20 Token 的交易对。
- **Exchange 合约**（**V1 版本**）：
  - **流动性提供与移除**：用户可以向交易池添加或移除流动性，获得 LP Token 奖励。
  - **ETH ↔ Token 兑换**：用户可以使用 ETH 交换目标 ERC20 Token。
  - **Token ↔ Token 兑换**：通过中间的 ETH，实现不同 ERC20 Token 之间的交换。
  - **手续费机制**：每笔交易收取 1% 手续费，流动性提供者共享手续费收益。

### **技术栈**

- **Solidity**：智能合约开发语言。
- **Foundry**：用于构建、测试、部署和调试智能合约的高效开发框架。
- **OpenZeppelin**：使用安全的 ERC20 标准合约。

### **目录结构**

```plaintext
MY-UNISWAP/
│
├── src/                      # 源代码目录
│   └── V1/                   # V1 版本代码
│       ├── Exchange.sol      # 核心 Exchange 合约
│       ├── Factory.sol       # Factory 合约，用于部署 Exchange
│       └── IExchange.sol     # 接口文件
│       └── IFactory.sol      # 接口文件
│
├── script/                   # 部署脚本
│   └── Deploy.s.sol          # Foundry 脚本用于合约部署
│
├── test/                     # 测试代码
│   ├── Exchange.t.sol        # Exchange 合约单元测试
│   └── Factory.t.sol         # Factory 合约单元测试
│
├── README.md                 # 项目文档
└── foundry.toml              # Foundry 配置文件
```
