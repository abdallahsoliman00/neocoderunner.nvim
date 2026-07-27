--- An annotation to define a language class
---@class Language
---@field extensions string[]
---@field runner fun(filePath: string, fileName: string): string

--- A table of language names, each with their `Language` instance
---@class Languages
---@field order string[]
---@field [string] Language
