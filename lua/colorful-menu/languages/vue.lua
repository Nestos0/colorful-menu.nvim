local utils = require("colorful-menu.utils")
local Kind = require("colorful-menu").Kind
local config = require("colorful-menu").config

local M = {}

local function expand_hex(s)
    s = s:lower()
    if #s == 4 then
        return "#" .. s:sub(2,2):rep(2) .. s:sub(3,3):rep(2) .. s:sub(4,4):rep(2)
    end

    return s
end

local function is_hex_color(s)
    if string.match(s, "^#[a-fA-F0-9]%x%x$") then
        return true
    end

    if string.match(s, "^#[a-fA-F0-9]%x%x%x%x%x$") then
        return true
    end

    if string.match(s, "^#[a-fA-F0-9]%x%x%x%x%x%x%x$") then
        return true
    end

    return false
end

local function _hex_to_rgb(hex)
    -- 去掉 #
    hex = hex:gsub("#", "")

    -- 提取 R, G, B
    local r = tonumber("0x" .. hex:sub(1, 2))
    local g = tonumber("0x" .. hex:sub(3, 4))
    local b = tonumber("0x" .. hex:sub(5, 6))

    return r, g, b
end

local function rgb_to_hex(str)
    local s, e = string.find(str, "%b()")
    if not s then
        return nil, "No parentheses found"
    end

    local content = string.sub(str, s + 1, e - 1)
    content = string.gsub(content, "%s+", "")

    local values = {}
    for v in string.gmatch(content, "[^,]+") do
        local num = tonumber(v)
        if not num then
            return nil, "Invalid numeric value: " .. v
        end
        table.insert(values, num)
    end

    local r, g, b = values[1], values[2], values[3]
    if #values == 4 then
        local hex_bg = string.format("#%06x", vim.api.nvim_get_hl(0, { name = "Pmenu" }).bg or 0)
        local dr, dg, db = _hex_to_rgb(hex_bg)
        local a = values[4]
        r = math.floor(r * a + dr * (1 - a))
        g = math.floor(g * a + dg * (1 - a))
        b = math.floor(b * a + db * (1 - a))
    end
    return string.format("#%02x%02x%02x", r, g, b)
end

local highlight_num = 0

local function get_unique_highlight_name(prefix)
    highlight_num = highlight_num + 1
    -- 确保 prefix 只包含合法字符
    prefix = prefix:gsub("[^a-zA-Z0-9_]", "_")
    return string.format("%s%d", prefix, highlight_num)
end

---@param completion_item lsp.CompletionItem
---@param ls string
---@return CMHighlights
local function _volar_completion_highlights(completion_item, ls)
    local label = completion_item.label
    local documentation = completion_item.documentation
    local detail = completion_item.detail
    local kind = completion_item.kind
    local hl

    local text = (detail and config.ls.ts_ls.extra_info_hl ~= false) and (label .. " " .. detail) or label

    if not kind then
        return utils.highlight_range(text, ls, 0, #text)
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
        if documentation ~= nil then
            hl = label
            ---@diagnostic disable-next-line
            vim.api.nvim_set_hl(0, label, { fg = documentation })
        elseif string.match(label, "rgb") ~= nil then
            local hl_name = get_unique_highlight_name("ColorMenu")
            hl = hl_name
            local rgb_fg = rgb_to_hex(label)
            vim.api.nvim_set_hl(0, hl_name, { fg = rgb_fg })
        elseif is_hex_color(label) then
            local hl_name = get_unique_highlight_name("ColorMenu")
            hl = hl_name
            vim.api.nvim_set_hl(0, hl_name, { fg = expand_hex(label) })
        end
        highlight_name = hl
        return {
            text = label .. " ",
            highlights = {
                {
                    highlight_name,
                    range = { #label, #label + 2 },
                },
            },
        }
    else
        highlight_name = config.fallback_highlight
    end
    return {
        text = label,
        highlights = { {
            highlight_name,
            range = { 0, #label },
        } },
    }
end

---@param completion_item lsp.CompletionItem
---@param ls string
---@return CMHighlights
function M.volar(completion_item, ls)
    local vim_item = _volar_completion_highlights(completion_item, ls)
    local function one_line(s)
        s = s:gsub("\n", "↲")
        table.insert(vim_item.highlights, {
            vim_item.highlights[1][1],
            range = { #vim_item.text - 1, #s },
        })
        return s
    end
    if vim_item.text ~= nil and string.find(vim_item.text, "\n") then
        vim_item.text = one_line(vim_item.text)
    end
    return vim_item
end

return M
