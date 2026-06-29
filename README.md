# GreenHat 🧢

> The greenest meme coin on EVM. 21M supply, 4 decimals, no owner.

[![CI](https://github.com/gamepunk/greenhat/actions/workflows/test.yml/badge.svg)](https://github.com/gamepunk/greenhat/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/gamepunk/greenhat/branch/main/graph/badge.svg)](https://codecov.io/gh/gamepunk/greenhat)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity ^0.8.24](https://img.shields.io/badge/Solidity-^0.8.24-blue)](https://soliditylang.org)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-000000.svg)](https://book.getfoundry.sh)

| 属性 | 值 |
|------|------|
| **名称** | GreenHat |
| **符号** | `GREEN` |
| **精度** | 4（最小单位 0.0001） |
| **总供应量** | 21,000,000 GREEN |
| **标准** | ERC-20 (OpenZeppelin v5) |
| **网络** | Polygon Amoy Testnet (chain 80002) |
| **所有权** | ✅ 已放弃（renounced） |

## 合约架构

```
src/
├── GreenHat.sol              # ERC-20 代币（反鲸鱼 + 黑名单 + 暂停）
├── GreenHatNFT.sol           # NFT 帽子合集（4 阶稀有度）
├── GreenHatMerkleAirdrop.sol # Merkle 树空投
├── GreenHatPool.sol          # GREEN/POL 流动性池（最小化 AMM）
test/
├── GreenHat.t.sol            # 代币单元测试 + fuzz
├── GreenHatNFT.t.sol         # NFT 测试
├── GreenHatMerkleAirdrop.t.sol # 空投测试
├── GreenHatInvariants.t.sol  # 不变量测试
script/
├── GreenHat.s.sol            # 代币部署脚本
├── GreenHatNFTDeploy.s.sol   # NFT 部署脚本
├── DeployPool.s.sol          # 池子部署脚本
web/
├── app/                      # Next.js 前端
├── scripts/                  # 链上监控工具
```

## 已部署合约

| 合约 | 地址（Polygon Amoy） |
|------|-------------------|
| **GREEN Token** | `0x8C5B79A3014009EFA8FB2de98b8474AfCefF082f` |
| **GREEN/POL Pool** | `0xF5368f0C6BFE1858b3d77B8b3bc5C6E6DA418b5B` |

## 功能特性

### 反鲸鱼机制
| 限制 | 默认值（21M 总量） |
|------|-----------------|
| **最大持仓** | 2%（420,000 GREEN） |
| **最大交易** | 1%（210,000 GREEN） |

### 安全功能
- **黑名单** — 封禁恶意地址
- **交易暂停** — 紧急情况下停止交易
- **DEX 对排除** — 交易对地址不受持仓/交易限制
- **所有权已放弃** — 无人能再修改合约

### NFT 稀有度

| 等级 | 所需 GREEN | 帽子 🧢 |
|------|-----------|---------|
| 🥉 Bronze | ≥ 1,000 | 青铜帽 |
| 🥈 Silver | ≥ 10,000 | 银帽 |
| 🥇 Gold | ≥ 100,000 | 金帽 |
| 💎 Diamond | ≥ 1,000,000 | 钻石帽 |

### 安全状态
| 项目 | 状态 |
|------|:----:|
| Slither 静态分析 | ✅ 0 个主要问题 |
| Forge Fuzz 测试 | ✅ 256 runs/case |
| 单元测试 | ✅ 66 测试全部通过 |
| 第三方审计 | ⏸️ 个人项目，暂无计划 |

## 快速开始

### 前置要求

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js 18+](https://nodejs.org)（前端开发）
- [Bun](https://bun.sh)（可选，前端开发）

### 安装依赖

```shell
forge install
```

### 编译

```shell
forge build
```

### 测试

```shell
# 全部测试
forge test -vvv

# 覆盖率
forge coverage --report summary

# 不变量测试（长时间运行）
forge test --mt invariant -vvv
```

### 前端

```shell
cd web
bun install
bun dev  # http://localhost:3000
```

### 环境配置

创建 `.env` 文件：

```shell
DEPLOYER_PRIVATE_KEY=your_private_key_here
GREENHAT_TOKEN=0x8C5B79A3014009EFA8FB2de98b8474AfCefF082f

# Polygon Amoy
AMOY_RPC_URL=https://rpc-amoy.polygon.technology
```

### 部署

```shell
source .env

# 部署代币
forge script script/GreenHat.s.sol:GreenHatScript \
    --rpc-url $AMOY_RPC_URL \
    --private-key $DEPLOYER_PRIVATE_KEY \
    --broadcast

# 部署流动性池
forge script script/DeployPool.s.sol:DeployPoolScript \
    --rpc-url $AMOY_RPC_URL \
    --private-key $DEPLOYER_PRIVATE_KEY \
    --broadcast
```

## 合约接口

### GREEN Token
- `name()` / `symbol()` / `decimals()` → 4
- `totalSupply()` → 21,000,000
- `maxWallet()` / `maxTx()` — 持仓/交易限制
- `setDexPair(address)` — 设置 DEX 对
- `setBlacklist(address, bool)` — 黑名单管理
- `setTradingPaused(bool)` — 暂停/恢复交易
- `burn(uint256)` / `burnFrom(address, uint256)` — 销毁
- `batchTransfer(address[], uint256[])` — 批量转账

### NFT
- `mint()` — 根据当前 GREEN 余额铸造帽子
- `upgrade()` — 余额达标后升级帽子等级
- `currentTier(address)` — 查看地址当前等级
- `setTierURI(Tier, string)` — 设置元数据 URI

### Pool
- `buyGreen(uint256 minOut)` — 用 POL 买入 GREEN
- `sellGreen(uint256 amount, uint256 minOut)` — 卖出 GREEN 换 POL
- `addLiquidity(uint256 greenAmount)` — 添加流动性（owner）
- `removeLiquidity()` — 移除流动性（owner）
- `price()` — 当前 GREEN/POL 价格

## Web 前端

监控面板，支持：
- 钱包连接（MetaMask）
- GREEN 余额展示
- 转账功能
- 实时交易事件流
- 合约状态仪表盘

## 链上监控

```shell
# 实时转账监听
cd web && bun run scripts/listener.ts

# 合约状态健康检查
cd web && bun run scripts/healthcheck.ts
```

## License

MIT
