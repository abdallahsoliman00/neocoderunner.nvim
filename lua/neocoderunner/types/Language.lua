--- An annotation to define a language class
---@class Language
---@field extensions string[]
---@field runner fun(filePath: string, fileName: string): string

---@class Languages
---@field order string[]
---@field [string] Language
