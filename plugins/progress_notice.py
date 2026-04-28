"""进度/错误提示补丁（基于 nonebot run hooks）：
1. 匹配到 parser 后 10s 仍未完成 → 发"⏳ 文件较大，仍在下载中…"
2. handler 抛异常 → 发"❌ 生成失败：{原因}"

仅对 nonebot_plugin_parser 的 matcher 生效。
"""
import asyncio

from nonebot import logger
from nonebot.matcher import Matcher
from nonebot.message import run_preprocessor, run_postprocessor
from nonebot_plugin_alconna import UniMessage

SLOW_DELAY = 10.0
SLOW_TEXT = "⏳ 文件较大，仍在下载中，请稍候…"
TARGET_PLUGIN = "nonebot_plugin_parser"

_tasks: dict[int, asyncio.Task] = {}


def _is_parser_matcher(matcher: Matcher) -> bool:
    plugin = getattr(matcher, "plugin", None)
    if plugin is None:
        return False
    name = getattr(plugin, "name", "") or getattr(plugin, "id_", "")
    return TARGET_PLUGIN in str(name)


async def _slow_notice():
    try:
        await asyncio.sleep(SLOW_DELAY)
        await UniMessage(SLOW_TEXT).send()
    except asyncio.CancelledError:
        raise
    except Exception:
        logger.opt(exception=True).warning("发送慢速提示失败")


@run_preprocessor
async def _pre(matcher: Matcher):
    if not _is_parser_matcher(matcher):
        return
    _tasks[id(matcher)] = asyncio.create_task(_slow_notice())


@run_postprocessor
async def _post(matcher: Matcher, exception: Exception | None = None):
    if not _is_parser_matcher(matcher):
        return
    task = _tasks.pop(id(matcher), None)
    if task and not task.done():
        task.cancel()
    if exception is not None:
        reason = str(exception) or exception.__class__.__name__
        if len(reason) > 300:
            reason = reason[:297] + "..."
        try:
            await UniMessage(f"❌ 生成失败：{reason}").send()
        except Exception:
            logger.opt(exception=True).warning("发送失败提示失败")


logger.success("进度/错误提示补丁已启用：10s 慢速提示 + 失败原因反馈")
