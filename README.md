# tg-parser-bot

**Telegram 社交媒体解析 Bot** — 将任意社交媒体链接发送给 Bot，自动提取视频/图片/文案并以卡片形式回复。

基于 [NoneBot2](https://github.com/nonebot/nonebot2) + [nonebot-plugin-parser](https://github.com/fllesser/nonebot-plugin-parser) 构建，支持 9 大平台，开箱即用。

---

## 功能特性

- **多平台支持**：抖音 / TikTok / 哔哩哔哩 / 小红书 / 微博 / 快手 / YouTube / AcFun / Twitter (X)
- **无水印视频**：优先返回无水印版本的视频直链
- **自动合并发送**：视频 + 图片 + 文字合并为单条 Telegram 消息
- **大文件提示**：下载超过 10 秒自动发送"正在下载"提示
- **失败原因反馈**：解析失败时向用户返回具体原因
- **TLS 指纹绕过**：自动注入 Chrome 指纹，适配抖音 CDN 校验

---

## 系统要求

| 项目 | 要求 |
|------|------|
| Python | ≥ 3.10 |
| ffmpeg | 必须安装（yt-dlp 依赖） |
| Telegram Bot Token | 从 [@BotFather](https://t.me/BotFather) 获取 |
| 网络 | 能够访问目标社交媒体域名 |

---

## 安装步骤

### 第一步：安装系统依赖

```bash
# Ubuntu / Debian
apt update && apt install -y ffmpeg
```

### 第二步：克隆项目

```bash
git clone https://github.com/T-Chen-CN/tg-parser-bot.git
cd tg-parser-bot
```

### 第三步：创建虚拟环境

```bash
python3 -m venv .venv
source .venv/bin/activate    # Windows: .venv\Scripts\activate
```

### 第四步：安装 Python 依赖

```bash
pip install -r requirements.txt
```

### 第五步：配置

```bash
# 复制配置文件
cp .env.example .env   # 如果没有 .env.example，直接创建 .env 文件

# 编辑 .env，填入你的 Telegram Bot Token
nano .env
```

`.env` 内容：

```env
DRIVER=~fastapi+~httpx
TELEGRAM_BOTS=[{"token": "你的Telegram_Bot_Token"}]
```

> **注意**：没有代理时直接删除 `TELEGRAM_PROXY=` 这一行。

### 第六步：启动

```bash
python bot.py
```

看到以下输出即启动成功：

```
04-28 17:00:00 [SUCCESS] nonebot | Running NoneBot...
04-28 17:00:00 [SUCCESS] nonebot | Loaded adapters: Telegram
04-28 17:00:00 [INFO] uvicorn | Uvicorn running on http://127.0.0.1:8080
04-28 17:00:01 [INFO] nonebot | Telegram | Start poll
```

---

## 使用方式

1. 在 Telegram 中找到你的 Bot（搜索你申请的 Bot 名字）
2. 点击 **Start** 或发送 `/start`
3. 直接粘贴社交媒体分享链接（支持完整分享文案，Bot 自动提取链接）
4. Bot 自动解析并回复媒体卡片

### 示例

发送以下任意内容，Bot 都会自动处理：

```
https://v.douyin.com/LxjCiel45u8/
https://www.xiaohongshu.com/explore/xxxxx
https://b23.tv/xxxxx
https://x.com/user/status/xxxxx
https://youtube.com/shorts/xxxxx
```

---

## 项目结构

```
tg-parser-bot/
├── bot.py                    # 入口文件，NoneBot 初始化
├── .env                      # 配置文件（Token 等）
├── requirements.txt          # Python 依赖列表
├── plugins/                  # 本地插件目录
│   ├── douyin_url_pick.py   # 抖音专项补丁：URL优选 + iOS headers + 无水印fallback + 视频尺寸注入
│   ├── merged_render.py      # 媒体+文字合并为单条消息
│   ├── progress_notice.py    # 大文件慢速提示 + 失败原因反馈
│   ├── fast_reaction.py      # reaction 加速补丁
│   ├── curl_impersonate.py  # TLS 指纹注入（Chrome）
│   └── help.py              # /help 命令 + Telegram 命令菜单注册
└── README.md
```

---

## 依赖说明

| 依赖 | 版本 | 作用 |
|------|------|------|
| nonebot2 | 2.5.0 | Bot 框架核心 |
| nonebot-adapter-telegram | 0.1.0b20 | Telegram 适配器 |
| nonebot-plugin-parser | 2.6.3 | 社交媒体解析核心插件 |
| curl_cffi | 0.13.0 | TLS 指纹模拟，绕过抖音 CDN 校验 |
| httpx | 0.28.1 | HTTP 客户端 |
| yt-dlp | latest | 视频下载（YouTube / TikTok 等） |
| ffmpeg | 系统安装 | 视频合并与转码（必须） |

---

## 常见问题

### Q: Bot 没有响应
- 检查 `.env` 中的 `BOT_TOKEN` 是否正确
- 检查网络是否能访问 Telegram API（国内服务器需要代理）
- 确认 Bot 已经点击 Start

### Q: 抖音视频下载失败（403 / 404）
- 这是抖音的 CDN 风控，非代码问题
- 代码已包含 play → playwm fallback，大部分视频可自动兜底
- 尝试发送其他抖音链接

### Q: 视频尺寸未识别
- 部分视频 metadata 不完整，Bot 会跳过尺寸注入，不影响发送

### Q: 如何后台运行？

**方式一：nohup**
```bash
nohup python bot.py > bot.log 2>&1 &
```

**方式二：systemd（推荐，开机自启）**

创建 `/etc/systemd/system/tg-parser-bot.service`：
```ini
[Unit]
Description=Telegram Parser Bot
After=network.target

[Service]
Type=simple
User=你的用户名
WorkingDirectory=/path/to/tg-parser-bot
ExecStart=/path/to/tg-parser-bot/.venv/bin/python bot.py
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable tg-parser-bot
sudo systemctl start tg-parser-bot
```

---

## 原项目 & 参考

- [NoneBot2](https://github.com/nonebot/nonebot2)
- [nonebot-plugin-parser](https://github.com/fllesser/nonebot-plugin-parser)
- [bilibili-api](https://github.com/MoyuScript/bilibili-api)
- [yt-dlp](https://github.com/yt-dlp/yt-dlp)

---

## License

MIT
