#!/bin/bash
# tg-parser-bot 开机自启脚本
# 运行此脚本，一键完成 systemd 服务注册和开机自启

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SERVICE_NAME="tg-parser-bot"
BOT_DIR=$(cd "$(dirname "$0")" && pwd)
USER=$(whoami)

echo -e "${GREEN}=== 设置开机自启 ===${NC}"
echo ""

# 检查是否为 root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}  请使用 sudo 运行：${NC}"
    echo "  sudo bash setup-service.sh"
    exit 1
fi

# 创建 systemd 服务文件
cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=Telegram Parser Bot
After=network.target

[Service]
Type=simple
User=${USER}
WorkingDirectory=${BOT_DIR}
ExecStart=${BOT_DIR}/.venv/bin/python bot.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 重载 systemd 并启用服务
systemctl daemon-reload
systemctl enable ${SERVICE_NAME}
systemctl restart ${SERVICE_NAME}

echo ""
echo -e "${GREEN}=== 设置完成 ===${NC}"
echo ""
echo "Bot 已注册为系统服务，开机自动启动"
echo ""
echo "常用命令："
echo "  查看状态：  systemctl status ${SERVICE_NAME}"
echo "  查看日志：  journalctl -u ${SERVICE_NAME} -f"
echo "  停止：      sudo systemctl stop ${SERVICE_NAME}"
echo "  重启：      sudo systemctl restart ${SERVICE_NAME}"
echo "  取消自启：  sudo systemctl disable ${SERVICE_NAME}"
echo ""
