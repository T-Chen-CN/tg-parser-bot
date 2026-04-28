"""抖音解析补丁：URL 优选 + iOS headers + 无水印/有水印 fallback + 视频尺寸注入。"""
import asyncio
import tempfile
from functools import wraps
from pathlib import Path
import httpx
import curl_cffi

from nonebot import logger
from nonebot_plugin_parser.parsers.douyin import DouyinParser
from nonebot_plugin_parser.parsers.douyin import slides as _s
from nonebot_plugin_parser.parsers.douyin import video as _v
from nonebot_plugin_parser.constants import IOS_HEADER
from nonebot_plugin_parser.download import downloader as _dl
from nonebot_plugin_parser.exception import DownloadException

# ---- A) URL 优选 ----
def _rank(url: str) -> int:
    if not isinstance(url, str):
        return 3
    if "douyinvod.com" in url:
        return 0
    if "zjcdn.com" in url:
        return 2
    return 1

def _pick(url_list):
    if not url_list:
        raise IndexError("empty url_list")
    return sorted(url_list, key=_rank)[0]

_v.choice = _pick
_s.choice = _pick

# ---- B) iOS headers 对齐 ----
_DOUYIN_HEADERS = {
    **IOS_HEADER,
    "Referer": "https://www.douyin.com/",
    "Accept": "*/*",
    "Accept-Language": "zh-CN,zh;q=0.9",
}

_orig_init = DouyinParser.__init__

def _patched_init(self, *args, **kwargs):
    _orig_init(self, *args, **kwargs)
    self.headers = _DOUYIN_HEADERS.copy()

DouyinParser.__init__ = _patched_init

# ---- C) 下载层 fallback (无水印 -> 有水印兜底) ----
_orig_download = _dl._download_file.__func__

@wraps(_orig_download)
async def _patched_download(self, url: str, **kwargs):
    is_douyin = "aweme.snssdk.com" in url or "douyinvod.com" in url or "zjcdn.com" in url
    
    if is_douyin:
        ext = kwargs.get("ext_headers") or {}
        kwargs["ext_headers"] = {**_DOUYIN_HEADERS, **ext}

    try:
        # 第一发：原 URL（通常是 play 无水印）
        return await _orig_download(self, url, **kwargs)
    except Exception as e:
        if is_douyin and "/aweme/v1/play/" in url:
            # 某些视频（如受版权保护或特定账号）无水印端点返回 403/404
            logger.warning(f"[douyin_url_pick] 无水印下载失败 ({e})，尝试回退 playwm (带水印)")
            fallback_url = url.replace("/aweme/v1/play/", "/aweme/v1/playwm/")
            return await _orig_download(self, fallback_url, **kwargs)
        raise

import types as _types
_dl._download_file = _types.MethodType(_patched_download, _dl)

# ---- D) Telegram send_video 自动注入 width/height ----
async def _ffprobe_dimensions(video_data: bytes) -> tuple[int, int] | None:
    try:
        with tempfile.NamedTemporaryFile(suffix=".mp4", delete=False) as f:
            f.write(video_data)
            tmp_path = f.name

        proc = await asyncio.create_subprocess_exec(
            "ffprobe", "-v", "error", "-select_streams", "v:0",
            "-show_entries", "stream=width,height", "-of", "csv=p=0:s=x",
            tmp_path, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE,
        )
        stdout, _ = await proc.communicate()
        Path(tmp_path).unlink(missing_ok=True)

        if proc.returncode == 0 and stdout.strip():
            parts = stdout.decode().strip().split("x")
            if len(parts) == 2:
                w, h = int(parts[0]), int(parts[1])
                logger.info(f"[douyin_url_pick] ffprobe 视频尺寸: {w}x{h}")
                return w, h
    except Exception as e:
        logger.warning(f"[douyin_url_pick] ffprobe 失败: {e}")
    return None

async def _ffprobe_dimensions_from_path(path: str | Path) -> tuple[int, int] | None:
    try:
        proc = await asyncio.create_subprocess_exec(
            "ffprobe", "-v", "error", "-select_streams", "v:0",
            "-show_entries", "stream=width,height", "-of", "csv=p=0:s=x",
            str(path), stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE,
        )
        stdout, _ = await proc.communicate()
        if proc.returncode == 0 and stdout.strip():
            parts = stdout.decode().strip().split("x")
            if len(parts) == 2:
                w, h = int(parts[0]), int(parts[1])
                logger.info(f"[douyin_url_pick] ffprobe 视频尺寸: {w}x{h}")
                return w, h
    except Exception as e:
        logger.warning(f"[douyin_url_pick] ffprobe 失败: {e}")
    return None

def _install_call_api_hook():
    from nonebot.adapters.telegram.bot import Bot as TgBot
    _orig_call_api = TgBot.call_api

    @wraps(_orig_call_api)
    async def _hooked_call_api(self, api: str, *args, **kargs):
        if api == "send_video" and "width" not in kargs and "height" not in kargs:
            video = kargs.get("video")
            dims = None
            if isinstance(video, bytes):
                dims = await _ffprobe_dimensions(video)
            elif isinstance(video, tuple) and len(video) == 2:
                dims = await _ffprobe_dimensions(video[1])
            elif isinstance(video, str) and Path(video).exists():
                dims = await _ffprobe_dimensions_from_path(video)

            if dims:
                kargs["width"] = dims[0]
                kargs["height"] = dims[1]
                kargs.setdefault("supports_streaming", True)
                logger.info(f"[douyin_url_pick] 注入 send_video: width={dims[0]}, height={dims[1]}")

        return await _orig_call_api(self, api, *args, **kargs)

    TgBot.call_api = _hooked_call_api
    logger.info("[douyin_url_pick] TgBot.call_api hook 已安装（视频尺寸注入）")

try:
    from nonebot import get_driver
    get_driver().on_startup(_install_call_api_hook)
except Exception:
    _install_call_api_hook()

logger.info("抖音解析补丁已启用：优选 + iOS headers + 无/有水印兜底 + 视频尺寸注入")
