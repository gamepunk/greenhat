# 🧢 GreenHat

> The greenest meme coin on EVM. No promises, just vibes. 🌿

| 属性 | 值 |
|------|------|
| **名称** | GreenHat |
| **符号** | `GHAT` |
| **精度** | 18 |
| **总供应量** | 1,000,000,000 GHAT |
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

### 验证合约

```shell
$ forge script script/GreenHat.s.sol:GreenHatScript \
    --rpc-url $RPC_URL \
    --private-key $DEPLOYER_PRIVATE_KEY \
    --broadcast \
    --verify
```

## 代币功能

- ✅ 标准 ERC-20（Transfer, Approve, TransferFrom）
- ✅ 总供应量 10 亿枚，全量预挖给部署者
- ✅ 部署后可放弃所有权（`renounceOwnership()`）
- ✅ 无内置税收/反射机制（社区决定）
- ⚠️ 无铸币功能（供应量固定）

## License

MIT
