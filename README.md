# tg-parser-bot

**Telegram 社交媒体解析 Bot** — 将任意社交媒体链接发送给 Bot，自动提取视频/图片/文案并以卡片形式回复。

基于 [NoneBot2](https://github.com/nonebot/nonebot2) + [nonebot-plugin-parser](https://github.com/fllesser/nonebot-plugin-parser) 构建，支持 9 大平台，一行命令完成部署。

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
| ffmpeg | 必须安装（脚本自动处理） |
| Telegram Bot Token | 部署时填入 |

---

## 一键部署

### Linux / macOS

```bash
# 克隆项目
git clone https://github.com/T-Chen-CN/tg-parser-bot.git
cd tg-parser-bot

# 运行部署脚本（自动安装依赖 + 引导填入 Token）
bash setup.sh
```

### Windows

```powershell
# 使用 PowerShell 或 WSL
git clone https://github.com/T-Chen-CN/tg-parser-bot.git
cd tg-parser-bot
.\setup.sh
```

部署脚本会自动完成：
1. 检查并安装 ffmpeg（如需要）
2. 创建 Python 虚拟环境
3. 安装全部 Python 依赖
4. 引导输入 Telegram Bot Token（**唯一需要手动输入的内容**）

---

## 获取 Telegram Bot Token

1. 打开 Telegram，搜索 **@BotFather**
2. 发送 `/newbot`
3. 按提示设置 Bot 名称和用户名
4. 复制 BotFather 返回的 Token，粘贴到部署脚本中

---

## 启动方式

### 直接运行（前台）

```bash
source .venv/bin/activate
python bot.py
```

### 后台运行

```bash
nohup python bot.py > bot.log 2>&1 &
```

### systemd 开机自启（推荐，一行命令搞定）

```bash
# 在项目目录下执行（需要 sudo 权限）
sudo bash setup-service.sh
```

执行后 Bot 会立即启动，并自动注册为开机自启服务。

**常用命令**

```bash
systemctl status tg-parser-bot   # 查看运行状态
journalctl -u tg-parser-bot -f   # 实时查看日志
sudo systemctl restart tg-parser-bot  # 重启
sudo systemctl stop tg-parser-bot     # 停止
sudo systemctl disable tg-parser-bot   # 取消开机自启
```

---

## 使用方式

1. 在 Telegram 中找到你的 Bot 并点击 **Start**
2. 直接粘贴社交媒体分享链接（支持完整分享文案，Bot 自动提取链接）
3. Bot 自动解析并回复媒体卡片

### 支持的链接类型

```
抖音：      https://v.douyin.com/xxx
TikTok：    https://www.tiktok.com/@user/video/xxx
哔哩哔哩：  https://b23.tv/xxxxx
小红书：    https://www.xiaohongshu.com/explore/xxxxx
微博：      https://weibo.com/xxx
快手：      https://v.kuaishou.com/xxx
YouTube：   https://youtube.com/shorts/xxx
Twitter/X： https://x.com/user/status/xxx
AcFun：     https://www.acfun.cn/v/acxxxxx
```

---

## 项目结构

```
tg-parser-bot/
├── bot.py                    # 入口文件，NoneBot 初始化
├── setup.sh                  # 交互式部署脚本（一键部署）
├── setup-service.sh          # 开机自启脚本（一键配置 systemd）
├── requirements.txt          # Python 依赖列表
├── .env                      # 运行时配置（setup.sh 自动生成）
├── .gitignore
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
- 确认 Bot 已经点击 Start
- 确认服务器网络可以访问 Telegram API（国内服务器需自备代理出口）
- 检查 `bot.log` 中的错误信息

### Q: 抖音视频下载失败（403 / 404）
- 这是抖音 CDN 风控，非代码问题
- 代码已包含 play → playwm fallback，大部分视频可自动兜底

### Q: 需要代理吗？
- 如果服务器网络无法直接访问 Telegram API，需自行配置代理
- 具体方式取决于你的代理工具，NoneBot2 会自动使用系统环境变量中的代理设置

### Q: 如何更新代码？

```bash
cd tg-parser-bot
git pull
source .venv/bin/activate
pip install -r requirements.txt -U
# 重启 bot
pkill -f 'python bot.py' && python bot.py
```

---

## 原项目 & 参考

- [NoneBot2](https://github.com/nonebot/nonebot2)
- [nonebot-plugin-parser](https://github.com/fllesser/nonebot-plugin-parser)
- [yt-dlp](https://github.com/yt-dlp/yt-dlp)

---

## License

MIT
