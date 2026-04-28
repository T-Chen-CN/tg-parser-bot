"""给 parser 的 curl_cffi 下载后端注入 impersonate='chrome'，绕过抖音 abtest CDN 的 TLS 指纹校验。"""
import curl_cffi
from nonebot import logger

_orig = curl_cffi.AsyncSession


class _ImpersonatedSession(_orig):
    def __init__(self, *args, **kwargs):
        kwargs.setdefault("impersonate", "chrome")
        super().__init__(*args, **kwargs)


curl_cffi.AsyncSession = _ImpersonatedSession
logger.info("curl_cffi AsyncSession 已注入 impersonate='chrome'")
