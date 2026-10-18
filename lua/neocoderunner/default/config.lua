return {
    terminal_position = "bottom", -- other options include "top", "floating", "left", "right"
    terminal_footprint = 0.33,
    -- Runners for each filetype, keyed by Neovim's 'filetype' (e.g. "python").
    -- Values are a command string, a { "command" } list, or a
    -- { build = "...", run = "..." } table.
    -- These override built-in runners, and can also introduce filetypes that
    -- the plugin doesn't ship with (they will be included in a generated
    -- runners.json).
    default_runners = {},
}
