from nonebot import on_command, get_driver
from nonebot.adapters.telegram import Bot, Event
from nonebot.adapters.telegram.message import Message

COMMANDS = [
    {"command": "help", "description": "显示使用说明"},
]

HELP_TEXT = """🤖 社媒解析机器人使用说明

直接把社媒分享链接发到聊天里，我会自动提取视频/图文/文案并回复。

📱 支持平台
• 抖音 / TikTok
• 哔哩哔哩
• 小红书
• 微博
• X (Twitter)
• 快手
• YouTube
• AcFun
• NGA

📝 用法
1. 复制 App 里的「分享」文本或链接
2. 粘贴发给我（私聊或群里 @我都行）
3. 等待解析结果

⚙️ 命令
/help - 显示本帮助

⚠️ 注意
• 视频大于 50MB 可能下载慢或失败
• 部分平台需登录的内容无法解析
• 解析失败请换个链接再试
"""

help_cmd = on_command("help", priority=1, block=True)


@help_cmd.handle()
async def _(bot: Bot, event: Event):
    await bot.send(event, Message(HELP_TEXT))


driver = get_driver()


@driver.on_bot_connect
async def _register_commands(bot: Bot):
    try:
        await bot.call_api("setMyCommands", commands=COMMANDS)
    except Exception as e:
        from nonebot.log import logger
        logger.warning(f"注册 Telegram 命令菜单失败: {e}")
