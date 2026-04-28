#!/bin/bash
# tg-parser-bot 交互式部署脚本
# 运行此脚本完成全部安装和配置，无需手动编辑任何文件

set -e

BOT_NAME="tg-parser-bot"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== tg-parser-bot 部署脚本 ===${NC}"
echo ""

# 1. 检查系统依赖
echo -e "${YELLOW}[1/5] 检查 ffmpeg ...${NC}"
if ! command -v ffmpeg &> /dev/null; then
    echo "  未找到 ffmpeg，正在安装 ..."
    apt update && apt install -y ffmpeg
else
    echo "  OK ($(ffmpeg -version 2>&1 | head -n1))"
fi

# 2. 检查 Python
echo -e "${YELLOW}[2/5] 检查 Python ...${NC}"
PYTHON_CMD=$(command -v python3)
if [ -z "$PYTHON_CMD" ]; then
    echo "  ERROR: 未找到 python3，请先安装 Python 3.10+"
    exit 1
fi
PYTHON_VERSION=$($PYTHON_CMD --version 2>&1)
echo "  OK ($PYTHON_VERSION)"

# 3. 创建虚拟环境
echo -e "${YELLOW}[3/5] 创建虚拟环境 ...${NC}"
if [ ! -d ".venv" ]; then
    $PYTHON_CMD -m venv .venv
    echo "  OK"
else
    echo "  已存在，跳过"
fi

# 激活虚拟环境
source .venv/bin/activate

# 4. 安装依赖
echo -e "${YELLOW}[4/5] 安装 Python 依赖（请稍候）...${NC}"
pip install --upgrade pip -q
pip install -r requirements.txt -q
echo "  OK"

# 5. 配置 Token
echo -e "${YELLOW}[5/5] 配置 Telegram Bot Token${NC}"
echo ""
echo "  请打开 Telegram，找到 @BotFather，发送 /newbot"
echo "  跟随指引创建 Bot，获取 Token（格式如：123456789:ABCdefGHIjklMNOpqrSTUvwxYZ）"
echo ""
read -p "  粘贴你的 Bot Token: " BOT_TOKEN

if [ -z "$BOT_TOKEN" ]; then
    echo "  ERROR: Token 不能为空"
    exit 1
fi

# 写入 .env
cat > .env << EOF
DRIVER=~fastapi+~httpx
TELEGRAM_BOTS=[{"token": "$BOT_TOKEN"}]
EOF

echo "  配置已保存到 .env"
echo ""
echo -e "${GREEN}=== 安装完成 ===${NC}"
echo ""
echo "启动 Bot："
echo "  source .venv/bin/activate"
echo "  python bot.py"
echo ""
echo "后台运行："
echo "  nohup python bot.py > bot.log 2>&1 &"
echo ""
echo "停止 Bot："
echo "  pkill -f 'python bot.py'"
echo ""
