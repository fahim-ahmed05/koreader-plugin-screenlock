# screenlock_koreader_plugin
This is a small plugin to enable locking the screen of the KOReader.

## Setup
1. Put `screenlock.koplugin` into the `kodreader/plugins` directory.
2. Change the hardcoded password at the top of the main.lua from 1234 to something else.

The plugin will automatically activate on resume from suspend. There is also a screenlock menu entry added.

### Hide Content Feature
Change `hide_content` bool to `true` to enlarge the input box and hide the screen until the password is entered correctly. This stops unauthorized users from seeing what books you're reading even if they turn on the device. Set bool to `false` to return to the small password box.

> [!CAUTION]  
> This plugin is made for basic protection, not security — it may not protect your device from an experienced attacker.
>
> Always keep your device out of the hands of real threats.