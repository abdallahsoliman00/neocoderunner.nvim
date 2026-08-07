# neocoderunner.nvim

A lightweight plugin to make running your code so much easier. A plugin to streamilne everything that isn't coding.

The aim of this plugin is to make the whole build and run process seamless by making them only a single command away.
Configure once, and run forever.

(Inspired by VSCode's code runner.)

<p>
  <video src="media/neocoderunner-demo.mp4" width="80%" controls></video>
</p>


## Overview
By default, this plugin provides a quick way to test a small piece of code very quickly. Either run the whole file, or highlight a section and run that.

However, a custom configuration can be made to tailor the plugin specifically for the project in the nvim working directory, making it also useful for handling large run workflows.
See the [Runner Configuration](#runner-configuration) section to see how to configure this plugin per project and to understand what the explanations below refer to.

If making a custom configuration for your project doesn't interest you, no need to read all this documentation, have a look below at the
[Out of the box](#out-of-the-box) section on how this plugin behaves out of the box. Otherwise, you've got some reading to do (sorry).

The plugin provides five commands:
- `:NCRunnerBuild` - Runs the build command for the filetype of the file in the current buffer, if defined.
- `:NCRunnerRun` - Runs the run command for the filetype of the file in the current buffer.
- `:NCRunCurrentFile` - Runs both the build and run commands in one sweep.
- `:NCRunCodeSnippet` - Runs a visually selected snippet by writing it to a temporary file, executing it, then cleaning up automatically.
- `:NCRunnerConfig` - Creates and initialises the file where the current working directory's configuration will be configured.

All commands are best mapped to keybinds for the smoothest workflow. (See the [Setup](#setup) section.)

### Out of the box
By adding this plugin, you now have access to two commands that can help you quickly run test pieces of code or whole files
without any additional configuration:

- **`:NCRunCurrentFile`**: Runs the entire file in your active buffer inside a terminal split. Just open a file and run the command.

- **`:NCRunCodeSnippet`**: Works visually. Highlight any block of code, run the command, and only that selected snippet gets executed in a temporary file that cleans up after itself.

Both commands automatically detect the filetype and use the appropriate runner. The following languages are supported out of the box:

| Language   | Default Run Command |
|-----------|----------------|
| C         |  `gcc -o ${fileName} ${filePath} && ./${fileName}`  |
| C++       | `g++ -o ${fileName} ${filePath} && ./${fileName}` |
| Rust      | `rustc ${filePath} && ./${fileName}`          |
| Lua       | `lua ${filePath}`         |
| Python    | `python -u ${filePath}`          |
| JavaScript| `node ${filePath}`          |
| TypeScript| `npx tsx ${filePath}`          |
| Perl      | `perl ${filePath}`          |
| Go        | `go run ${filePath}`          |
| PHP       | `php ${filePath}`         |
| Zig       | `zig run ${filePath}`         |

*Note: The exact commands that are run depend on the shell being used, but the above are a close approximation and are the ones run in a bash shell.
And don't worry, the plugin detects the shell and adjusts the default commands accordingly.

If that's all you need, map the commands and you're done. Check the [Setup](#setup) section for keybind examples.
If your project has a more involved build pipeline, continue reading below.


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
        -- Easy run with keymaps (optional)
        { "<C-S-B>", ":NCRunnerBuild<CR>", mode = "n", silent = true, noremap = true },
        { "<C-S-R>", ":NCRunnerRun<CR>", mode = "n", silent = true, noremap = true },
        { "<C-S-N>", ":NCRunCurrentFile<CR>", mode = "n", silent = true, noremap = true },
        { "<C-S-N>", ":<C-U>NCRunCodeSnippet<CR>", mode = "v", silent = true, noremap = true },
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
        vim.keymap.set("n", "<C-S-B>", ":NCRunnerBuild<CR>", { silent = true, noremap = true })
        vim.keymap.set("n", "<C-S-R>", ":NCRunnerRun<CR>", { silent = true, noremap = true })
        vim.keymap.set("n", "<C-S-N>", ":NCRunCurrentFile<CR>", { silent = true, noremap = true })
        vim.keymap.set("v", "<C-S-N>", ":<C-U>NCRunCodeSnippet<CR>", { silent = true, noremap = true })
    end
})
```


### Default Plugin Configuration
```lua
{
    -- Position of the neocoderunner terminal
    terminal_position = "bottom",    -- "bottom", "top", "left", "right", "floating", or a number >= 1

    -- How much of the existing window the neocoderunner terminal will occupy
    terminal_footprint = 0.33,
}
```

When `terminal_position` is `"floating"`, the terminal opens in a centered floating window (80% width, 70% height) with rounded borders instead of a split.
If set to a number >= 1, the terminal opens in a new tab instead of a split (overriding the footprint value).

The `terminal_footprint` controls the size ratio: for horizontal splits (`"top"`, `"bottom"`) it determines the height ratio;
for vertical splits (`"left"`, `"right"`) it determines the width ratio.


## Runner Configuration

### Setup
To configure the runner for each filetype, the command `:NNCRunnerConfig` can be used to generate a json file
(at `{root}/.ncrunner/runners.json`) containing the default commands and environment used.

If the file already exists, and you want to create a new one, try `:NCRunnerConfig override` or `:NCRunnerConfig o` to override the currently existing file.
The resulting generated json should look something like this:
```json
{
    "env": {
        "cd": "${cwd}",
        "export": {},
        "scripts": []
    },
    "runners": {
        "global": "",
        "c": "gcc -o ${fileName} ${filePath} && ./${fileName}",
        "cpp": "g++ -o ${fileName} ${filePath} && ./${fileName}",
        "lua": "lua ${filePath}",
        "python": "python3 -u ${filePath}",
        "rust": "rustc ${filePath} && ./${fileName}",
        "javascript": "node ${filePath}",
        "typescript": "npx tsx ${filePath}",
        "perl": "perl ${filePath}",
        "go": "go run ${filePath}",
        "php": "php ${filePath}",
        "zig": "zig run ${filePath}"
    }
}
```
Alternatively, you could just create a file at `{root}/.ncrunner/runners.json` and just write the runner for whatever filetype you want.
```json
{
    "cpp": {
        "build": "cmake --build build",
        "run": "build/out.exe"
    }
}
```
Yes, the `"env"` section is optional.

### Configuration Syntax
There are two main sections: one controls the environment in which commands execute, and the other controls the commands themselves.

Before explaining these sections in detail, here are a few comments about the placeholders present to aid with configuration.
These are helpful for anything involving paths and navigation.

In the above examples, you will see some placeholder names `${cwd}`, `${fileName}`, `${filePath}`. These are the placeholders that this plugin understands,
so when writing your own runner configuration, use a combination of these to help.
- `${cwd}`: Stands for 'Current Working Directory' and it is the directory that your neovim instance is in, and it is where the `.ncrunner` file should exist.
- `${fileName}`: Is the name of whatever file is open in your current buffer at the time the command is executed.
  For example, if a file called `src/myfile.c` is open in your current buffer, at runtime, `${fileName}` will resolve to just `myfile`.
- `${filePath}`: Is the path relative to the current working directory, so `src/myfile.c` will be `src/myfile.c`.

#### The "env" section:
The env section, from the name, controls the environment where the run command executes. Everything here is run before any build or run commands. A few things can be configured:
- **"cd"**: A string that represents the directory where commands will run from; the runner cd's into this directory before running anything else. e.g. `"cd": "${cwd}/build"`
- **"export"**: Stores variable-value pairs as such `"export": { "API_KEY": "abc123", "VAR": "123" }`. These variables are exported using the correct syntax for your shell,
                so no need to worry about writing the correct export command.
- **"scripts"**: An ordered list of shell commands or scripts to run. Useful for sourcing environment setup scripts such as Python virtual environments.
                 e.g. `"scripts": ["source .venv/bin/activate", "echo 'Ready'"]`

#### The "runners" section:
This section is where the run commands are configured. Each runner can be configured in one of two forms:

**One-liner**:
```json
"python": "python3 -u ${filePath}"
```

**Separate build/run commands**:
```json
"cpp": {
    "build": "cmake --build build",
    "run": "build/out.exe"
}
```
When using the split build/run form, `:NCRunnerBuild` runs only the `build` command and `:NCRunnerRun` runs only the `run` command.
`:NCRunCurrentFile` chains both together with `&&` (or `;` for PowerShell). This is useful for larger projects where compiling and executing are separate steps.

If a runner is a single string (one-liner), `:NCRunnerBuild` has no effect (since there is no separate build step),
while `:NCRunnerRun` and `:NCRunCurrentFile` both execute the full command.

#### The "global" runner
For large projects where different filetypes may be open in your buffer, switching to a buffer where, for example, Python is open only to execute the Python-specific
run command may be tedious. This is where the `"global"` runner comes in handy.

You can set a `"global"` runner that applies to all filetypes, regardless of what file is open:
```json
{
    "runners": {
        "global": "python3 -m main"
    }
}
// or
{
    "runners": {
        "global": {
            "build": "cargo build --release",
            "run": "cargo run --release"
        }
    }
}
```
If a global runner is empty (`""`), it is ignored and the plugin falls back to filetype-specific or default runners.

#### Runner Resolution Order
When you run a command, the plugin resolves the runner in this order:

1. **Global runner**: If defined and non-empty in `runners.json`, use it.
2. **Filetype-specific runner**: If a runner exists for the current buffer's filetype in `runners.json` and is non-empty, use it.
3. **Built-in default**: Fall back to the plugin's hardcoded default runner for that filetype.

If no runner exists at any level, a warning is shown.

## Contributing
I haven't yet added runner commands for all languages, but the most commonly used ones (that don't have a complicated build system) are supported.

See [this file](lua/neocoderunner/languages.lua) or the [Runner Configuration](#runner-configuration) section for more.

If there's a language I missed, or a feature to add, feel free to open a pull request.
