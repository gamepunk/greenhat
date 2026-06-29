# 🧢 GreenHat

> The greenest meme coin on EVM. No promises, just vibes. 🌿

[![CI](https://github.com/gamepunk/greenhat/actions/workflows/test.yml/badge.svg)](https://github.com/gamepunk/greenhat/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/gamepunk/greenhat/branch/main/graph/badge.svg)](https://codecov.io/gh/gamepunk/greenhat)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity ^0.8.20](https://img.shields.io/badge/Solidity-^0.8.20-blue)](https://soliditylang.org)

| 属性 | 值 |
|------|------|
| **名称** | GreenHat |
| **符号** | `GREEN` |
| **精度** | 18 |
| **总供应量** | 1,000,000,000 GREEN |
| **标准** | ERC-20 (OpenZeppelin v5) |
| **网络** | Ethereum, Base, BNB Chain, Polygon 等 EVM 链 |

## 合约架构

```
src/
├── GreenHat.sol      # ERC-20 代币合约
test/
├── GreenHat.t.sol    # 单元测试 + fuzz 测试
script/
├── GreenHat.s.sol    # 部署脚本
```

## 功能特性

### 反鲸鱼机制
| 限制 | 默认值 |
|------|--------|
| **最大持仓** | 总供应量的 2% |
| **最大交易** | 总供应量的 1% |

### 安全功能
- **黑名单** — 封禁恶意地址
- **交易暂停** — 紧急情况下停止交易
- **DEX 对排除** — 交易对地址不受持仓/交易限制

### 安全状态
| 项目 | 状态 |
|------|:----:|
| Slither 静态分析 | ✅ 0 个问题 |
| Solhint 代码风格 | ✅ 0 个警告 |
| Forge Fuzz 测试 | ✅ 256 runs/ case |
| 第三方审计 | ⏸️ 个人项目，暂无计划 |

### 所有权
- 标准 `Ownable`（单步转移）
- 无铸币功能（供应量固定）
- **无税收** — 纯粹的转账体验

## 快速开始

### 前置要求

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### 安装依赖

```shell
$ forge install
```

### 编译

```shell
$ forge build
```

### 测试

```shell
$ forge test -vvv
```

### 环境配置

创建 `.env` 文件：

```shell
DEPLOYER_PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key

# 主网
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/your_key
BASE_RPC_URL=https://mainnet.base.org
BNB_RPC_URL=https://bsc-dataseed.binance.org

# 测试网
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your_key
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
```

### 部署

通过 `Makefile` 一键部署：

```shell
# 测试网
make deploy-sepolia
make deploy-base-sepolia

# 主网（请先测试！）
make deploy-mainnet
make deploy-base
make deploy-bnb
```

或手动执行：

```shell
$ source .env
$ forge script script/GreenHat.s.sol:GreenHatScript \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $DEPLOYER_PRIVATE_KEY \
    --broadcast --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY
```

### 部署后配置

```shell
# 设置 DEX 交易对（排除持仓/交易限制）
$ cast send <TOKEN_ADDRESS> "setDexPair(address)" <PAIR_ADDRESS> \
    --rpc-url $RPC_URL --private-key $DEPLOYER_PRIVATE_KEY

# 调整限制参数（可选）
$ cast send <TOKEN_ADDRESS> "setLimits(uint256,uint256)" <MAX_WALLET> <MAX_TX> \
    --rpc-url $RPC_URL --private-key $DEPLOYER_PRIVATE_KEY
```

## 合约接口

### 只读函数
- `name()` / `symbol()` / `decimals()` — 代币元数据
- `totalSupply()` / `balanceOf(address)` / `allowance(owner, spender)` — ERC-20
- `owner()` — 所有权
- `maxWallet()` / `maxTx()` — 限制参数
- `dexPair()` — DEX 交易对
- `isExcludedFromLimits(address)` — 排除列表
- `isBlacklisted(address)` — 黑名单
- `tradingPaused()` — 暂停状态

### 管理函数（仅 owner）
- `setDexPair(address)` — 设置 DEX 对
- `setLimits(uint256, uint256)` — 设置持仓/交易限制
- `setBlacklist(address, bool)` — 黑名单管理
- `setTradingPaused(bool)` — 暂停/恢复交易
- `excludeFromLimits(address, bool)` — 排除管理
- `transferOwnership(address)` — 所有权转移

## 文档站点

NatSpec 注释会自动生成文档站点：

```shell
# 生成静态文档
make docs

# 本地预览（浏览器打开 http://localhost:3000）
make docs-serve
```

## License

MIT
