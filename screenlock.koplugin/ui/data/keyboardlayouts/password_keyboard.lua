--[[
    Keyboard layout for number password
]]

return {
    min_layer = 1,
    max_layer = 1,
    shiftmode_keys = {},
    symbolmode_keys = {},
    utf8mode_keys = {},
    keys = {
        {
            { "1" },
            { "2" },
            { "3" },
        },
        {
            { "4" },
            { "5" },
            { "6" },
        },
        {
            { "7" },
            { "8" },
            { "9" },
        },
        {
            { label = "", width = 1.0, bold = false }, --delete
            { "0" },
            {
                label = "⮠",
                "\n",
                width = 1.0,
                bold = true
            },
        },
    },
}
