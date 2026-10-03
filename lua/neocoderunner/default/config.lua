return {
    terminal_position = "bottom", -- other options include "top", "floating", "left", "right"
    terminal_footprint = 0.33,
    -- Overrides for the built-in runners. Keys are filetypes (e.g. "python")
    -- and values are a command string, a { "command" } list, or a
    -- { build = "...", run = "..." } table.
    default_runners = {},
}
