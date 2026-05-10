# neocoderunner.nvim

A lightweight plugin to help run test pieces of code, for dirty drafting or quick prototyping, without leaving your editor.

(Inspired by VSCode's code runner.)

![Demo](media/neocoderunner.gif)

## Overview
This is a plugin that should be used when you quickly want to test a small piece of code very quickly.

The plugin provides two commands:
- `:RunCurrentFile` -  Compiles (if needed) and runs the current file, displaying output in a new buffer.
- `:RunCodeSnippet` - Runs a visually selected snippet by writing it to a temporary file, executing it, then cleaning up automatically.

Both commands are best mapped to keybinds for the smoothest workflow. (See the [Setup](#setup) section.)


## Requirements
Here are the commands executed for each supported language, use them to find what you need to run each:
```
C
gcc -o ${fileName} ${fullpath} && ./${fileName}

C++
g++ -o ${fileName} ${fullpath} && ./${fileName}

Rust
rustc ${fullpath} && ./${fileName}

Lua
lua ${fullpath}

Python
python -u ${fullpath}

Javascript
node ${fullpath}

Typescript
npx tsx ${fullpath}

Perl
perl ${fullpath}

Go
go run ${fullpath}
```
*Note these aren't the actual commands that are run, rather only a representation of the commands behind the scenes. The actual commands depend on the device being used.


## Setup
**lazy**:
```lua
{
    "abdallahsoliman00/neocoderunner.nvim",
    opts = {
        terminal_position = "bottom",
        terminal_footprint = 0.33,
    },
    keys = {
        -- Easy run with keymap (optional)
        { "<C-S-N>", ":RunCurrentFile<CR>", mode = "n", silent = true, noremap = true },
        { "<C-S-n>", ":<C-U>RunCodeSnippet<CR>", mode = "v", silent = true, noremap = true },
    },
}
```

**packer**:
```lua
use({
    "abdallahsoliman00/neocoderunner.nvim",
    config = function()
        require("neocoderunner").setup({
            terminal_position = "bottom",
            terminal_footprint = 0.33,
        })
        -- Easy run with keymap (optional)
        vim.keymap.set("n", "<C-S-N>", ":RunCurrentFile<CR>", { silent = true, noremap = true })
        vim.keymap.set("v", "<C-S-n>", ":<C-U>RunCodeSnippet<CR>", { silent = true, noremap = true })
    end
})
```


## Default Configuration
```lua
{
    -- Position of the neocoderunner terminal
    terminal_position = "bottom",    -- other options include "top", "floating", "left", "right"

    -- How much of the existing window the neocoderunner terminal will occupy
    terminal_footprint = 0.33,
}
```

## Contributing
I haven't yet added runner commands for all languages, but the most commonly used ones (that don't have a complicated build system) are supported.

See [this file](lua/neocoderunner/languages.lua) or the [Requirements](#Requirements) section for more.

If there's a language I missed, or a feature to add, feel free to open a pull request.
