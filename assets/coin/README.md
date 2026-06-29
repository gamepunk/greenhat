# 🪙 GreenHat Token Logo

这个目录放 GREEN 代币的头像（logo）。

## 用途

| 平台 | 说明 | 尺寸要求 |
|------|------|:--------:|
| **Etherscan / DEX** | 代币合约的 Logo | 256×256 ~ 512×512 px |
| **Uniswap Info** | 代币图标 | 200×200 px |
| **钱包 (MetaMask)** | 代币显示图标 | 256×256 px |
| **GitHub README** | 项目头像 | 任意 |

## 文件要求

- 格式：PNG 或 SVG
- 建议命名：`greenhat-logo.png` 或 `greenhat-logo.svg`
- 透明背景最佳

## 设计参考

主题色：`#00FF00` (亮绿)、`#1a1a2e` (深色背景)
风格：帽子 🧢 + 代币 💰 结合

## 生成方法

### 方案 A：你自己设计 SVG

直接编辑 `greenhat-logo.svg` 文件

### 方案 B：用 AI 生成

```
提示词示例：
"A green bucket hat token/coin logo, simple flat design, 
dark background, crypto meme style, minimal, 512x512"
```

工具推荐：DALL·E, Midjourney, Leonardo.ai

### 方案 C：用 Python 脚本生成占位图

```bash
python3 scripts/generate_logo.py
```
