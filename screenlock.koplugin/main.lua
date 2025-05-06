local Blitbuffer = require("ffi/blitbuffer")

local Device = require("device")
local Dispatcher = require("dispatcher")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")

local InputDialog = require("ui/widget/inputdialog")
local InfoMessage = require("ui/widget/infomessage")
local _ = require("gettext")

local Screen = Device.screen

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
    background_widget = nil,

    locked = false,     -- Track locked state
    password = "1234",  -- Your hard-coded password
    hide_content = true -- Hide screen content before password is entered
}

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
    dialog = InputDialog:new {
        title = _("Enter Password"),
        input = "",
        maskinput = true,
        text_type = "password",
        hint = _("Password"),
        buttons = { {
            {
                text = _("Cancel"),
                callback = function()
                    UIManager:show(InfoMessage:new {
                        text = _("You must enter the correct password!"),
                        timeout = 1
                    })

                    UIManager:close(dialog)
                    self:showPasswordPrompt()
                end
            },
            {
                text = _("OK"),
                is_enter_default = true,
                callback = function()
                    local userInput = dialog:getInputText()
                    if userInput == self.password then
                        self.locked = false

                        UIManager:close(dialog)
                        UIManager:close(self.background_widget, "full")
                    else
                        UIManager:show(InfoMessage:new {
                            text = _("Wrong password! Try again."),
                            timeout = 1
                        })

                        UIManager:close(dialog)
                        self:showPasswordPrompt()
                    end
                end
            }
        } }
    }

    UIManager:show(dialog)
    dialog:onShowKeyboard() -- Immediately open the on-screen keyboard
end

-- Dispatch handler
function ScreenLock:onLockScreenButtons()
    self:lockScreen()
    return true
end

-- Register main menu entry
function ScreenLock:addToMainMenu(menu_items)
    menu_items.screenlock_inputdialog_buttons = {
        text = _("Lock Screen"),
        callback = function()
            self:lockScreen()
        end
    }
end

return ScreenLock
