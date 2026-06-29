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
├── GreenHat.sol      # ERC-20 代币合约
test/
├── GreenHat.t.sol    # 单元测试 + fuzz 测试
script/
├── GreenHat.s.sol    # 部署脚本
```

## 功能特性

### 🛡️ 反鲸鱼机制
| 限制 | 默认值 |
|------|--------|
| **最大持仓** | 总供应量的 2% |
| **最大交易** | 总供应量的 1% |

### 🔒 安全功能
- **黑名单** — 封禁恶意地址
- **交易暂停** — 紧急情况下停止交易
- **DEX 对排除** — 交易对地址不受持仓/交易限制

### 👑 所有权
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
# 设置 DEX 交易对（排除持仓/交易限制）
$ cast send <TOKEN_ADDRESS> "setDexPair(address)" <PAIR_ADDRESS> --rpc-url $RPC_URL --private-key $DEPLOYER_PRIVATE_KEY

# 调整限制参数（可选）
$ cast send <TOKEN_ADDRESS> "setLimits(uint256,uint256)" <MAX_WALLET> <MAX_TX> --rpc-url $RPC_URL --private-key $DEPLOYER_PRIVATE_KEY
```

### 验证

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

## License

MIT
