local Dispatcher = require("dispatcher")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")

local InputDialog = require("ui/widget/inputdialog")
local InfoMessage = require("ui/widget/infomessage")
local _ = require("gettext")

local ScreenLock = WidgetContainer:extend{
    name = "screenlock_inputdialog_buttons",
    is_doc_only = false,

    locked   = false,      -- Track locked state
    password = "1234",     -- Your hard-coded password
}

------------------------------------------------------------------------------
-- REGISTER DISPATCHER ACTIONS
------------------------------------------------------------------------------
function ScreenLock:onDispatcherRegisterActions()
    Dispatcher:registerAction("screenlock_inputdialog_buttons_lock_screen", {
        category = "none",
        event = "LockScreenButtons",
        title = _("Lock Screen (InputDialog + Buttons)"),
        filemanager = true,
    })
end

------------------------------------------------------------------------------
-- INIT (including wake-up handling via onResume)
------------------------------------------------------------------------------
function ScreenLock:init()
    -- 1) Register dispatcher action
    self:onDispatcherRegisterActions()
    
    -- 2) Add to main menu
    self.ui.menu:registerToMainMenu(self)

    -- 3) Override onResume to handle device wake-up
    function self:onResume()
        if not self.locked then
            self:lockScreen()
        end
    end
end

------------------------------------------------------------------------------
-- LOCK SCREEN
------------------------------------------------------------------------------
function ScreenLock:lockScreen()
    self.locked = true
    self:showPasswordPrompt()
end

------------------------------------------------------------------------------
-- SHOW PASSWORD PROMPT (USING BUTTONS ARRAY)
-- "Cancel" button reopens the prompt, preventing escape
------------------------------------------------------------------------------
function ScreenLock:showPasswordPrompt()
    local dialog
    dialog = InputDialog:new{
        title     = _("Enter Password"),
        input     = "",
        maskinput = true,
        hint      = _("Password"),
        buttons   = {
            {
                -- CANCEL => Reopen dialog (cannot escape)
                {
                    text = _("Cancel"),
                    callback = function()
                        UIManager:show(
                            InfoMessage:new{
                                text = _("You must enter the correct password!"),
                                timeout = 1    -- Dismiss after 1 second
                            }
                        )
                        UIManager:close(dialog)
                        -- Reopen the password prompt
                        self:showPasswordPrompt()
                    end
                },
                -- OK => Check password
                {
                    text = _("OK"),
                    is_enter_default = true,
                    callback = function()
                        local userInput = dialog:getInputText()
                        if userInput == self.password then
                            -- Correct => Unlock and show success InfoMessage
                            self.locked = false
                            UIManager:close(dialog)
                            UIManager:show(
                                InfoMessage:new{
                                    text    = _("Screen unlocked."),
                                    timeout = 1    -- Dismiss after 1 second
                                }
                            )
                        else
                            -- Wrong => Show error InfoMessage and re-display prompt
                            UIManager:show(
                                InfoMessage:new{
                                    text    = _("Wrong password! Try again."),
                                    timeout = 1    -- Dismiss after 1 second
                                }
                            )
                            UIManager:close(dialog)
                            self:showPasswordPrompt()
                        end
                    end
                },
            }
        },
    }

    UIManager:show(dialog)
    dialog:onShowKeyboard()  -- Immediately open the on-screen keyboard
end

------------------------------------------------------------------------------
-- DISPATCHER HANDLER
------------------------------------------------------------------------------
function ScreenLock:onLockScreenButtons()
    self:lockScreen()
    return true
end

------------------------------------------------------------------------------
-- MAIN MENU ENTRY
------------------------------------------------------------------------------
function ScreenLock:addToMainMenu(menu_items)
   menu_items.screenlock_inputdialog_buttons = {
       text = _("Lock Screen"),
       callback = function()
           self:lockScreen()
       end
  }
end

return ScreenLock

