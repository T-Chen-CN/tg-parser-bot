"""合并渲染器：卡片图 + 媒体 + 文字，全部合并为单条消息。
文字作为 caption 附在相册第一项上（Telegram sendMediaGroup 规范）。
caption 超过 1024 字符会被截断。
"""
from nonebot import logger

from nonebot_plugin_parser import renders as _renders_mod
from nonebot_plugin_parser.renders.common import CommonRenderer
from nonebot_plugin_parser.helper import UniMessage

CAPTION_LIMIT = 1024


class MergedRenderer(CommonRenderer):

    def _build_caption(self) -> str:
        parts: list[str] = []
        if self.result.author and getattr(self.result.author, "name", None):
            parts.append(f"👤 {self.result.author.name}")
        if self.result.title:
            parts.append(f"📌 {self.result.title}")
        if self.result.text:
            parts.append(self.result.text)
        if self.result.extra_info:
            parts.append(self.result.extra_info)
        if self.append_url:
            for url in (self.result.display_url, self.result.repost_display_url):
                if url:
                    parts.append(url)
        text = "\n\n".join(parts)
        if len(text) > CAPTION_LIMIT:
            text = text[: CAPTION_LIMIT - 1] + "…"
        return text

    async def render_messages(self):
        segs = []
        try:
            segs.append(await self.cache_or_render_image())
        except Exception as e:
            logger.warning(f"卡片图渲染失败，跳过: {e}")

        try:
            async for message in self.render_contents():
                for seg in message:
                    segs.append(seg)
        except Exception as e:
            logger.warning(f"媒体渲染失败: {e}")

        caption = self._build_caption()

        if segs:
            msg = UniMessage(segs)
            if caption:
                msg += "\n" + caption
            yield msg
        elif caption:
            yield UniMessage(caption)


_renders_mod.RENDERER = MergedRenderer
logger.success("已启用 MergedRenderer：媒体 + 文字合并为单条")
