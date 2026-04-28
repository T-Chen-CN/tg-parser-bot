import nonebot
from nonebot.adapters.telegram import Adapter as TelegramAdapter

nonebot.init()
driver = nonebot.get_driver()
driver.register_adapter(TelegramAdapter)

nonebot.load_plugin("nonebot_plugin_parser")
nonebot.load_plugins("plugins")

if __name__ == "__main__":
    nonebot.run()
