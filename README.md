# 🧢 GreenHat

> The greenest meme coin on EVM. No promises, just vibes. 🌿

| 属性 | 值 |
|------|------|
| **名称** | GreenHat |
| **符号** | `GREEN` |
| **精度** | 18 |
| **总供应量** | 1,000,000,000 GREEN |
| **标准** | ERC-20 (OpenZeppelin v5) |
| **网络** | EVM 兼容链 |

## 合约架构

```
src/
├── GreenHat.sol      # ERC-20 代币合约（OZ 基础）
test/
├── GreenHat.t.sol    # 单元测试 + fuzz 测试
script/
├── GreenHat.s.sol    # 部署脚本
```

## 功能特性

### 💰 税收机制
| 类型 | 默认值 | 说明 |
|------|--------|------|
| **买入税** | 5% | 每笔 DEX 买入征税 |
| **卖出税** | 7% | 每笔 DEX 卖出征税 |
| **最高税率** | 10% | 安全上限 |

税收按以下比例分配：
- 🎯 **60%** → 营销钱包
- 💧 **30%** → 流动性池
- 🔥 **10%** → 永久燃烧

### 🛡️ 反鲸鱼机制
| 限制 | 默认值 |
|------|--------|
| **最大持仓** | 总供应量的 2% |
| **最大交易** | 总供应量的 1% |

### 🔒 安全功能
- **黑名单** — 封禁恶意地址
- **交易暂停** — 紧急情况下停止交易
- **两步所有权转移** — 防止错误转账

### 👑 所有权
- 部署后可随时放弃所有权（两步转移）
- 无铸币功能（供应量固定）
- 税率、钱包地址等可配置

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

### Fuzz 测试

```shell
$ forge test --fuzz-seed 42
```

### 部署

1. 创建 `.env` 文件：

```shell
DEPLOYER_PRIVATE_KEY=your_private_key_here
RPC_URL=your_rpc_url_here
```

2. 部署：

```shell
$ source .env
$ forge script script/GreenHat.s.sol:GreenHatScript \
    --rpc-url $RPC_URL \
    --private-key $DEPLOYER_PRIVATE_KEY \
    --broadcast
```

3. 部署后配置：

```shell
# 设置 DEX 交易对（启用买卖税）
$ cast send <TOKEN_ADDRESS> "setDexPair(address)" <PAIR_ADDRESS> --rpc-url $RPC_URL --private-key $DEPLOYER_PRIVATE_KEY

# 设置营销钱包
$ cast send <TOKEN_ADDRESS> "setMarketingWallet(address)" <WALLET_ADDRESS> --rpc-url $RPC_URL --private-key $DEPLOYER_PRIVATE_KEY

# 调整税率（可选）
$ cast send <TOKEN_ADDRESS> "setTaxRates(uint256,uint256)" 300 500 --rpc-url $RPC_URL --private-key $DEPLOYER_PRIVATE_KEY
```

### 验证合约

```shell
$ forge script script/GreenHat.s.sol:GreenHatScript \
    --rpc-url $RPC_URL \
    --private-key $DEPLOYER_PRIVATE_KEY \
    --broadcast \
    --verify
```

## 合约接口

### 只读函数
- `name()` / `symbol()` / `decimals()` — 代币元数据
- `totalSupply()` / `balanceOf(address)` / `allowance(owner, spender)` — ERC-20 标准
- `owner()` / `pendingOwner()` — 所有权
- `buyTaxRate()` / `sellTaxRate()` — 税率
- `marketingShare()` / `liquidityShare()` / `burnShare()` — 税收分配
- `marketingWallet()` / `liquidityWallet()` — 钱包地址
- `maxWallet()` / `maxTx()` — 限制参数
- `dexPair()` — DEX 交易对
- `marketingReserve()` / `liquidityReserve()` — 累计税收
- `isExcludedFromTax(address)` / `isExcludedFromLimits(address)` — 排除列表
- `isBlacklisted(address)` — 黑名单
- `tradingPaused()` — 暂停状态

### 管理函数（仅 owner）
- `setDexPair(address)` — 设置 DEX 对
- `setMarketingWallet(address)` / `setLiquidityWallet(address)` — 设置钱包
- `setTaxRates(uint256, uint256)` — 设置税率
- `setTaxShares(uint256, uint256, uint256)` — 设置税收分配
- `setLimits(uint256, uint256)` — 设置持仓/交易限制
- `setBlacklist(address, bool)` — 黑名单管理
- `setTradingPaused(bool)` — 暂停/恢复交易
- `excludeFromTax(address, bool)` / `excludeFromLimits(address, bool)` — 排除管理
- `collectMarketing()` / `collectLiquidity()` — 提取累计税收
- `transferOwnership(address)` / `acceptOwnership()` — 所有权转移

## License

MIT
