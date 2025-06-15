local utils = require("colorful-menu.utils")
local Kind = require("colorful-menu").Kind
local config = require("colorful-menu").config

local M = {}

---@param completion_item lsp.CompletionItem
---@param ls string
---@return CMHighlights
local function _volar_completion_highlights(completion_item, ls)
    local label = completion_item.label
    local documentation = completion_item.documentation
    local kind = completion_item.kind

    if not kind then
        return utils.highlight_range(label, ls, 0, #label)
    end

    local highlight_name
    if kind == Kind.Class or kind == Kind.Interface or kind == Kind.Enum then
        highlight_name = "@type"
    elseif kind == Kind.Constructor then
        highlight_name = "@type"
    elseif kind == Kind.Constant then
        highlight_name = "@constant"
    elseif kind == Kind.Function or kind == Kind.Method then
        highlight_name = "@function"
    elseif kind == Kind.Property or kind == Kind.Field then
        highlight_name = "@property"
    elseif kind == Kind.Variable then
        highlight_name = "@variable"
    elseif kind == Kind.Keyword then
        highlight_name = "@keyword"
    elseif kind == Kind.Color then
        ---@diagnostic disable-next-line
        vim.api.nvim_set_hl(0, label, { fg = documentation })
        highlight_name = label
    else
        highlight_name = config.fallback_highlight
    end

    return {
        text = " " + label,
        highlight_name = {
            highlight_name,
            range = { 0, 1 },
        },
    }
end

---@param completion_item lsp.CompletionItem
---@param ls string
---@return CMHighlights
function M.volar(completion_item, ls)
    local vim_item = _volar_completion_highlights(completion_item, ls)
    if vim_item.text ~= nil then
        local s, e = string.find(vim_item.text, "%b{}")
        if s ~= nil and e ~= nil then
            table.insert(vim_item.highlights, {
                config.ls.volar.arguments_hl,
                range = { s - 1, e },
            })
        end
    end
    return vim_item
end

return M
