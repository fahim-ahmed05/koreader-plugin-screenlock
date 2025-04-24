# KOReader Plugin: ScreenLock
This plugin lets you lock your screen with a password, either triggered from the menu or automatically upon device wake-up.

## Setup
1. Put `screenlock.koplugin` into the `kodreader/plugins` directory.
2. Change the hardcoded password at the top of the `main.lua` from `1234` to something else.

## Note
The plugin will automatically activate on resume from suspend. There is also a screenlock menu entry added.

> [!CAUTION]  
> This plugin is made for basic protection, not security — it may not protect your device from an experienced attacker.
>
> Always keep your device out of the hands of real threats.