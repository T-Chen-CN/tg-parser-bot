"""Reaction 加速补丁：
with_reaction 装饰器内调用的是 cls.message_reaction(...)，运行时查类属性。
这里把 message_reaction 包装一层：status=="resolving" 时 fire-and-forget，
fail/done 保持 await 原逻辑。
"""
import asyncio

from nonebot import logger
from nonebot_plugin_parser.helper import UniHelper

_original = UniHelper.message_reaction.__func__  # 拿到原 classmethod 底层函数


async def _patched(cls, event, status):
    if status == "resolving":
        asyncio.create_task(_original(cls, event, status))
        return
    await _original(cls, event, status)


UniHelper.message_reaction = classmethod(_patched)

logger.success("reaction 加速补丁已启用：resolving → fire-and-forget")
