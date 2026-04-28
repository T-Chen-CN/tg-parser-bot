#!/bin/bash
# tg-parser-bot 交互式部署脚本
# 兼容任何 Linux 服务器（Ubuntu/Debian/CentOS等）

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== tg-parser-bot 部署脚本 ===${NC}"
echo ""

# ---- 检测 sudo ----
SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
    echo -e "${YELLOW} 注意：需要 sudo 权限，已自动添加${NC}"
fi

# ---- 步骤 1：安装系统依赖 ----
echo -e "${YELLOW}[1/6] 安装 ffmpeg ...${NC}"
if ! command -v ffmpeg &> /dev/null; then
    $SUDO apt update && $SUDO apt install -y ffmpeg
    echo " ffmpeg 安装完成"
else
    echo " OK ($(ffmpeg -version 2>&1 | head -n1))"
fi

# ---- 步骤 2：安装 python3-venv ----
echo -e "${YELLOW}[2/6] 安装 python3-venv ...${NC}"

# 用硬路径 /usr/bin/python3 避免被 PATH 劫持
PYTHON="/usr/bin/python3"
if [ ! -f "$PYTHON" ]; then
    echo -e "${RED} ERROR: 未找到 $PYTHON${NC}"
    exit 1
fi

PYTHON_VERSION=$($PYTHON --version 2>&1 | awk '{print $2}')
PYTHON_MAJOR_MINOR=$(echo $PYTHON_VERSION | cut -d. -f1,2)
PYTHON_PKG="python${PYTHON_MAJOR_MINOR}-venv"

# 测试 venv 是否真正可用（--without-pip 避免 ensurepip 依赖）
rm -rf /tmp/.test_venv
if ! $PYTHON -m venv --without-pip /tmp/.test_venv &> /dev/null; then
    echo " 正在安装 $PYTHON_PKG ..."
    $SUDO apt update && $SUDO apt install -y $PYTHON_PKG
    rm -rf /tmp/.test_venv
    if ! $PYTHON -m venv --without-pip /tmp/.test_venv &> /dev/null; then
        echo -e "${RED} ERROR: python3-venv 安装失败，请手动运行：${NC}"
        echo "    $SUDO apt install $PYTHON_PKG"
        exit 1
    fi
    echo " $PYTHON_PKG 安装完成"
fi
rm -rf /tmp/.test_venv
echo " OK"

# ---- 步骤 3：检查 Python ----
echo -e "${YELLOW}[3/6] 检查 Python ...${NC}"
echo " OK ($PYTHON_VERSION @ $PYTHON)"

# ---- 步骤 4：创建虚拟环境 ----
echo -e "${YELLOW}[4/6] 创建虚拟环境 ...${NC}"

# 强制删除旧 venv（可能由其他用户/PATH 创建，路径不兼容）
if [ -d ".venv" ]; then
    echo " 删除旧 .venv ..."
    rm -rf .venv
fi

$PYTHON -m venv --without-pip .venv

# 验证 shebang 路径是否指向当前用户可写的位置
VENV_PYTHON=".venv/bin/python3"
if [ ! -f "$VENV_PYTHON" ]; then
    echo -e "${RED} ERROR: 虚拟环境创建失败${NC}"
    exit 1
fi

# 检测 venv 是否真正可用（pip 能否正常 import）
if ! .venv/bin/python3 -c "import pip" 2>/dev/null; then
    echo " 检测到 venv 不可用（pip import 失败），修复中 ..."
    rm -rf .venv
    $PYTHON -m venv --without-pip .venv
fi

echo " OK"

# ---- 步骤 5：安装 Python 依赖 ----
echo -e "${YELLOW}[5/6] 安装 Python 依赖（请稍候）...${NC}"

# 用 curl bootstrap pip（避免 ensurepip 依赖）
curl -sS https://bootstrap.pypa.io/get-pip.py | .venv/bin/python3
# 强制使用官方 PyPI（腾讯等国内镜像可能缺包）
.venv/bin/pip install --upgrade pip -q -i https://pypi.org/simple/
.venv/bin/pip install -r requirements.txt -q -i https://pypi.org/simple/

echo " OK"

# ---- 步骤 6：配置 Token ----
echo -e "${YELLOW}[6/6] 配置 Telegram Bot Token${NC}"
echo ""
echo " 请打开 Telegram，搜索 @BotFather，发送 /newbot"
echo " 跟随指引创建 Bot，复制返回的 Token 粘贴到这里"
echo ""
read -p " 粘贴你的 Bot Token: " BOT_TOKEN
if [ -z "$BOT_TOKEN" ]; then
    echo -e "${RED} ERROR: Token 不能为空${NC}"
    exit 1
fi

cat > .env << EOF
DRIVER=~fastapi+~httpx
TELEGRAM_BOTS=[{"token": "$BOT_TOKEN"}]
EOF

echo " 配置已保存到 .env"
echo ""
echo -e "${GREEN}=== 安装完成 ===${NC}"
echo ""
echo " 启动 Bot（前台）："
echo "    source .venv/bin/activate && python bot.py"
echo ""
echo " 启动 Bot（后台）："
echo "    nohup .venv/bin/python bot.py > bot.log 2>&1 &"
echo ""
echo " 停止 Bot："
echo "    pkill -f 'python bot.py'"
echo ""
