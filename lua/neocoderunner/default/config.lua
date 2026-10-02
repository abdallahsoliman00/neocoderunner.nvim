return {
    terminal_position = "bottom", -- other options include "top", "floating", "left", "right"
    terminal_footprint = 0.33,
    default_runners = {
        c = { "gcc -o ${fileName} ${filePath} && ./${fileName}" },
        cpp = { "g++ -o ${fileName} ${filePath} && ./${fileName}" },
        rust = { "rustc ${filePath} && ./${fileName}" },
        lua = { "lua ${filePath}" },
        python = { "python -u ${filePath}" },
        javascript = { "node ${filePath}" },
        typescript = { "npx tsx ${filePath}" },
        perl = { "perl ${filePath}" },
        go = { "go run ${filePath}" },
        php = { "php ${filePath}" },
        zig = { "zig run ${filePath}" },
    },
}
