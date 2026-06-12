local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local CODE_ACTION = methods.internal.CODE_ACTION

return h.make_builtin({
    name = "refactoring",
    meta = {
        url = "https://github.com/ThePrimeagen/refactoring.nvim",
        description = "The Refactoring library based off the Refactoring book by Martin Fowler.",
        notes = {
            [[Requires either providing a textobject selection or visually selecting the code you want to refactor and call `:'<,'>lua vim.lsp.buf.code_action()`]],
        },
        config = {
            {
                key = "enable_debug",
                type = "boolean",
                default = false,
                description = "Show debug print code actions",
            },
            {
                key = "use_picker",
                type = "boolean",
                default = false,
                description = "Use vim.ui.select picker instead of showing all actions in the code action menu",
            },
        },
    },
    method = CODE_ACTION,
    filetypes = { "c", "cs", "cpp", "go", "javascript", "lua", "python", "typescript", "php", "java", "ruby", "vim" },
    generator = {
        -- the plugin currently returns all refactors, regardless of context / availability
        -- so we ignore params
        fn = function(params)
            local ok, refactoring = pcall(require, "refactoring")
            if not ok then
                return {}
            end
            local items =
            {
                { name = "Inline variable",  fn = refactoring.inline_var },
                { name = "Extract variable", fn = refactoring.extract_var },
                { name = "Inline function",  fn = refactoring.inline_func },
                { name = "Extract function", fn = refactoring.extract_func },
            }

            local config = params:get_config()
            if config.enable_debug then
                local ok_debug, debug = pcall(require, "refactoring.debug")
                if ok_debug then
                    table.insert(items, { name = "Debug print variable", fn = debug.print_var })
                    table.insert(items, { name = "Debug print expression", fn = debug.print_exp })
                    table.insert(items, { name = "Debug print location", fn = debug.print_loc })
                    table.insert(items, { name = "Debug print cleanup", fn = debug.cleanup })
                end
            end

            local mode = vim.api.nvim_get_mode().mode
            local function run(item)
                local keys = item.fn()
                if (mode == "v" or mode == "V" or mode == "\22") and keys == "g@" then
                    keys = "gvg@"
                end
                vim.api.nvim_input(keys)
            end

            if config.use_picker then
                return {
                    {
                        title = "Refactoring...",
                        action = function()
                            vim.ui.select(items, {
                                prompt = "Select refactoring:",
                                format_item = function(item) return item.name end,
                            }, function(choice)
                                if choice then
                                    run(choice)
                                end
                            end)
                        end,
                    },
                }
            end

            local actions = {}
            for _, item in ipairs(items) do
                table.insert(actions, {
                    title = item.name,
                    action = function() run(item) end,
                })
            end
            return actions
        end,
    },
})
