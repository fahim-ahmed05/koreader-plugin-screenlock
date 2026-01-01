local Blitbuffer = require("ffi/blitbuffer")
local sha2 = require("ffi/sha2")

local _ = require("gettext")
local Device = require("device")
local Dispatcher = require("dispatcher")
local DataStorage = require("datastorage")
local LuaSettings = require("luasettings")

local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local InputDialog = require("ui/widget/inputdialog")
local InfoMessage = require("ui/widget/infomessage")
local VirtualKeyboard = require("ui/widget/virtualkeyboard")

local Screen = Device.screen
local DefaultPassword = sha2.sha256("1234")

--[[ Fullscreen Overlay Widget ]]

local FullscreenOverlay = WidgetContainer:extend {}

function FullscreenOverlay:init()
    self.covers_fullscreen = true
    self.dimen = Screen:getSize()
end

function FullscreenOverlay:paintTo(bb, x, y)
    bb:fill(Blitbuffer.COLOR_WHITE)
end

--[[ Screen Lock Widget ]]

local ScreenLock = WidgetContainer:extend {
    name = "screenlock_inputdialog_buttons",
    is_doc_only = false,

    locked = false,
    background_widget = nil,
    settings_file = DataStorage:getSettingsDir() .. "/screen_lock.lua",
    settings = nil,

    password_hash = DefaultPassword,
    hide_content = true
}

function ScreenLock:loadSettings()
    if self.settings then
        return
    end

    self.settings = LuaSettings:open(self.settings_file)

    self.password_hash = self.settings:readSetting("password_hash") or DefaultPassword
    self.hide_content = self.settings:readSetting("hide_content") == true
end

function ScreenLock:onFlushSettings()
    if self.settings then
        self.settings:saveSetting("password_hash", self.password_hash)
        self.settings:saveSetting("hide_content", self.hide_content)

        self.settings:flush()
    end
end

-- Register dispatcher actions
function ScreenLock:onDispatcherRegisterActions()
    Dispatcher:registerAction("screenlock_inputdialog_buttons_lock_screen", {
        category = "none",
        event = "LockScreenButtons",
        title = _("Lock Screen (InputDialog + Buttons)"),
        filemanager = true
    })
end

-- Initialize widget and register wakeup-handler
function ScreenLock:init()
    self:loadSettings()

    -- Initialize fullscreen widget
    self.background_widget = FullscreenOverlay:new()

    -- Register dispatcher action
    self:onDispatcherRegisterActions()

    -- Add to main menu
    self.ui.menu:registerToMainMenu(self)

    -- Safe onResume override to handle device wake-up
    local originalResume = self.onResume
    self.onResume = function(self)
        if originalResume then originalResume(self) end

        if not self.locked then
            self:lockScreen()
        end
    end
end

-- Lock the screen now
function ScreenLock:lockScreen()
    self.locked = true

    -- Show fullscreen overlay
    if self.hide_content then
        UIManager:show(self.background_widget)
    end

    -- Show passowrd prompt
    self:showPasswordPrompt()
end

-- Shows the password prompt and prevents escaping
function ScreenLock:showPasswordPrompt()
    local dialog
    self:addKeyboard()
    dialog = InputDialog:new {
        title = _("Enter Password"),
        input = "",
        text_type = "password",
        buttons = { {
            {
                text = _("Cancel"),
                callback = function()
                    -- Sleep the device
                    UIManager:suspend()
                end
            },
            {
                text = _("OK"),
                is_enter_default = true,
                callback = function()
                    local password_input = dialog:getInputText()
                    local password_hash = sha2.sha256(password_input)

                    if password_hash == self.password_hash then
                        self.locked = false

                        UIManager:close(dialog)
                        UIManager:close(self.background_widget, "full")
                        self:restoreKeyboard()
                    else
                        UIManager:show(InfoMessage:new {
                            text = _("Wrong password! Try again."),
                            timeout = 1
                        })

                        UIManager:close(dialog)
                        self:restoreKeyboard()
                        self:showPasswordPrompt()
                    end
                end
            }
        } }
    }

    UIManager:show(dialog)
    dialog:onShowKeyboard() -- Immediately open the on-screen keyboard
end

-- Dispatch handler when screen is locked
function ScreenLock:onLockScreenButtons()
    self:lockScreen()
    return true
end

-- Shows a dialog to change the password
function ScreenLock:changePassword()
    self:addKeyboard()
    -- Ask for old password
    local old_dialog
    old_dialog = InputDialog:new {
        title = _("Enter old password"),
        input = "",
        text_type = "password",
        buttons = { {
            {
                text = _("Cancel"),
                callback = function()
                    UIManager:close(old_dialog)
                    self:restoreKeyboard()
                end
            },
            {
                text = _("OK"),
                is_enter_default = true,
                callback = function()
                    local old_password_input = old_dialog:getInputText()
                    local old_password_hash = sha2.sha256(old_password_input)

                    if old_password_hash == self.password_hash then
                        UIManager:close(old_dialog)

                        -- Ask for new password
                        local new_dialog
                        new_dialog = InputDialog:new {
                            title = _("Enter new password"),
                            input = "",
                            text_type = "password",
                            buttons = { {
                                {
                                    text = _("Cancel"),
                                    callback = function()
                                        UIManager:close(new_dialog)
                                        self:restoreKeyboard()
                                    end
                                },
                                {
                                    text = _("OK"),
                                    is_enter_default = true,
                                    callback = function()
                                        local new_password_input = new_dialog:getInputText()
                                        local new_password_hash = sha2.sha256(new_password_input)

                                        self.password_hash = new_password_hash

                                        UIManager:show(InfoMessage:new {
                                            text = _("Password changed!"),
                                            timeout = 1
                                        })

                                        UIManager:close(new_dialog)
                                        self:restoreKeyboard()
                                    end
                                }
                            } }
                        }

                        UIManager:show(new_dialog)
                        new_dialog:onShowKeyboard()
                    else
                        UIManager:show(InfoMessage:new {
                            text = _("Wrong password! Try again."),
                            timeout = 1
                        })

                        UIManager:close(old_dialog)
                        self:restoreKeyboard()
                        self:changePassword()
                    end
                end
            }
        } }
    }

    UIManager:show(old_dialog)
    old_dialog:onShowKeyboard()
end

-- Register main menu entry
function ScreenLock:addToMainMenu(menu_items)
    menu_items.screenlock_inputdialog_buttons = {
        text = _("Screenlock"),
        sub_item_table = {
            {
                text = _("Lock now"),
                callback = function()
                    -- Sleep the device
                    UIManager:suspend()
                end,
                separator = true,
            },
            {
                text = _("Change password"),
                callback = function()
                    self:changePassword()
                end,
            },
            {
                text = _("Hide screen content"),
                checked_func = function()
                    return self.hide_content
                end,
                callback = function()
                    self.hide_content = not self.hide_content
                end,
            },
        }
    }
end

function ScreenLock:addKeyboard()
    VirtualKeyboard.lang_to_keyboard_layout[_ "ScreenLockPassword"] = "password_keyboard"
    VirtualKeyboard.layout_file = "password_keyboard"
    self.original_keyboard_layout = G_reader_settings:readSetting("keyboard_layout")
    G_reader_settings:saveSetting("keyboard_layout", "ScreenLockPassword")
end

function ScreenLock:restoreKeyboard()
    VirtualKeyboard.lang_to_keyboard_layout[_ "ScreenLockPassword"] = nil
    VirtualKeyboard.layout_file = nil

    G_reader_settings:saveSetting("keyboard_layout", self.original_keyboard_layout)
end

return ScreenLock
