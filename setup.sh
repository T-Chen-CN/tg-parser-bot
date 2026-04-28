#!/bin/bash
# tg-parser-bot 交互式部署脚本
# 运行此脚本完成全部安装和配置，无需手动编辑任何文件

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== tg-parser-bot 部署脚本 ===${NC}"
echo ""

# 检测是否需要 sudo
SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
    echo -e "${YELLOW}  注意：需要 sudo 权限，已自动添加${NC}"
fi

# ---- 步骤 1：安装系统依赖 ----
echo -e "${YELLOW}[1/6] 安装 ffmpeg ...${NC}"
if ! command -v ffmpeg &> /dev/null; then
    $SUDO apt update && $SUDO apt install -y ffmpeg
    echo "  ffmpeg 安装完成"
else
    echo "  OK ($(ffmpeg -version 2>&1 | head -n1))"
fi

# ---- 步骤 2：安装 python3-venv ----
echo -e "${YELLOW}[2/6] 安装 python3-venv ...${NC}"
PYTHON_CMD=$(command -v python3)
PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | awk '{print $2}')
PYTHON_PKG="python${PYTHON_VERSION%%.*}-venv"
if ! $PYTHON_CMD -m venv --help &> /dev/null; then
    $SUDO apt update && $SUDO apt install -y $PYTHON_PKG
    echo "  $PYTHON_PKG 安装完成"
else
    echo "  OK"
fi

# ---- 步骤 3：检查 Python ----
echo -e "${YELLOW}[3/6] 检查 Python ...${NC}"
if [ -z "$PYTHON_CMD" ]; then
    echo -e "${RED}  ERROR: 未找到 python3，请先安装 Python 3.10+${NC}"
    exit 1
fi
echo "  OK ($PYTHON_VERSION)"

# ---- 步骤 4：创建虚拟环境 ----
echo -e "${YELLOW}[4/6] 创建虚拟环境 ...${NC}"
if [ ! -d ".venv" ]; then
    $PYTHON_CMD -m venv .venv
    echo "  OK"
else
    echo "  已存在，跳过"
fi

# 激活虚拟环境
source .venv/bin/activate

# ---- 步骤 5：安装 Python 依赖 ----
echo -e "${YELLOW}[5/6] 安装 Python 依赖（请稍候）...${NC}"
pip install --upgrade pip -q
pip install -r requirements.txt -q
echo "  OK"

# ---- 步骤 6：配置 Token ----
echo -e "${YELLOW}[6/6] 配置 Telegram Bot Token${NC}"
echo ""
echo "  请打开 Telegram，搜索 @BotFather，发送 /newbot"
echo "  跟随指引创建 Bot，复制返回的 Token 粘贴到这里"
echo ""
read -p "  粘贴你的 Bot Token: " BOT_TOKEN

if [ -z "$BOT_TOKEN" ]; then
    echo -e "${RED}  ERROR: Token 不能为空${NC}"
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
echo "  source .venv/bin/activate && python bot.py"
echo ""
echo "后台运行："
echo "  nohup python bot.py > bot.log 2>&1 &"
echo ""
echo "停止 Bot："
echo "  pkill -f 'python bot.py'"
echo ""
