-- ~/.config/nvim/init.lua — minimal starter. Replace with your own config later.

-- ---- Options -------------------------------------------------------------
local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.wrap = false
opt.ignorecase = true
opt.smartcase = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.undofile = true
opt.scrolloff = 8
opt.wrap = true
opt.linebreak = true

-- ---- Basic keymaps -------------------------------------------------------
local map = vim.keymap.set
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Yank/paste via the system clipboard explicitly (works in normal + visual mode).
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
map({ "n", "v" }, "<leader>p", [["+p]], { desc = "Paste from system clipboard" })

-- Bootstrap lazy.nvim (plugin manager)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local out = vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
	if vim.v.shell_error ~= 0 then
		error("Error cloning lazy.nvim:\n" .. out)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
require("lazy").setup({
	-- Colorscheme (gives the highlight groups actual colors)
	{
		"folke/tokyonight.nvim",
		lazy = false, -- load during startup
		priority = 1000, -- load before other plugins
		config = function()
			vim.cmd.colorscheme("tokyonight")
		end,
	},

	-- Treesitter: real syntax highlighting for Kotlin, TypeScript, etc.
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
		config = function()
			-- The `main` branch dropped `nvim-treesitter.configs`: parsers are
			-- installed imperatively and highlighting/indent are wired up per
			-- buffer via an autocmd.
			local treesitter = require("nvim-treesitter")
			treesitter.setup({})

			---@type string[]
			local parsers = {
				"kotlin",
				"typescript",
				"tsx",
				"javascript",
				"lua",
				"json",
				"yaml",
				"html",
				"css",
				"bash",
				"markdown",
				"markdown_inline",
        "python"
			}
			treesitter.install(parsers)

			-- markdown crashes the TS highlighter on fenced code blocks with
			-- Neovim 0.12 (nvim-treesitter#8618). Fall back to Vim's built-in
			-- regex markdown highlighting instead.
			---@type table<string, boolean>
			local highlightDisabledFiletypes = { markdown = true }

			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					---@type string
					local filetype = vim.bo[args.buf].filetype
					---@type string|nil
					local lang = vim.treesitter.language.get_lang(filetype)
					if lang == nil or not vim.treesitter.language.add(lang) then
						return
					end

					if highlightDisabledFiletypes[filetype] then
						pcall(vim.treesitter.stop, args.buf)
						return
					end

					vim.treesitter.start(args.buf, lang)
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})
		end,
	},

	{
		"nvim-telescope/telescope.nvim",
		branch = "master",
		dependencies = {
			"nvim-lua/plenary.nvim",
			-- native fzf sorter for speed (needs `make`, which macOS has via Xcode CLT)
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")
			telescope.setup({
				defaults = {
					-- Horizontally scroll the results list to reveal long paths.
					mappings = {
						i = {
							["<C-l>"] = actions.results_scrolling_right,
							["<C-h>"] = actions.results_scrolling_left,
						},
						n = {
							["<C-l>"] = actions.results_scrolling_right,
							["<C-h>"] = actions.results_scrolling_left,
						},
					},
					-- Show filename first, then the shortened path in parentheses.
					-- Fixes long paths hiding the filename on narrow terminals.
					path_display = { "filename_first" },
					-- Preview on top, results list gets full terminal width below.
					-- Best for narrow terminals so filenames aren't truncated.
					layout_strategy = "vertical",
					layout_config = {
						vertical = { preview_height = 0.5 },
					},
					-- Skip build/generated/vendored junk (esp. Android/Kotlin).
					file_ignore_patterns = {
						"%.git/",
						"node_modules/",
						"build/",
						"%.gradle/",
						"%.idea/",
						"%.kotlin/",
						"gen/",
						"%.class$",
					},
				},
				pickers = {
					find_files = {
						-- Also hide files listed in .gitignore (build output usually is).
						-- `--hidden` includes dotfiles/dotdirs; .git/ is still excluded
						-- via file_ignore_patterns above.
						-- Requires `fd` (brew install fd); falls back gracefully if absent.
						find_command = { "fd", "--type", "f", "--strip-cwd-prefix", "--hidden" },
					},
				},
			})
			pcall(telescope.load_extension, "fzf")

			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
			vim.keymap.set("n", "<leader>fa", function()
				require("telescope.builtin").find_files({
					find_command = {
						"fd",
						"--type",
						"f",
						"--strip-cwd-prefix",
						"--no-ignore",
						"--hidden",
					},
				})
			end, { desc = "Find all files including ignored" })
		end,
	},

	-- LSP: mason installs/manages servers, lspconfig wires them into nvim
	{
		"williamboman/mason.nvim",
		config = true,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = { "kotlin_language_server" },
				ensure_installed = { "ts_ls" },
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = { "williamboman/mason-lspconfig.nvim" },
		config = function()
			vim.lsp.enable("kotlin_language_server")
			vim.lsp.enable("ts_ls")

			-- Keymaps that apply once an LSP client attaches to a buffer
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local opts = { buffer = args.buf }
					local telescope = require("telescope.builtin")

					-- Navigation
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
					vim.keymap.set("n", "gi", telescope.lsp_implementations, opts)
					vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)
					vim.keymap.set("n", "gr", telescope.lsp_references, opts) -- find usages

					-- Info
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, opts)

					-- Symbols (fuzzy-searchable via Telescope)
					vim.keymap.set("n", "<leader>ds", telescope.lsp_document_symbols, opts)
					vim.keymap.set("n", "<leader>ws", telescope.lsp_dynamic_workspace_symbols, opts)

					-- Refactoring
					vim.keymap.set("n", "grn", vim.lsp.buf.rename, opts)
					vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

					-- Diagnostics
					vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
					vim.keymap.set("n", "[d", function()
						vim.diagnostic.jump({ count = -1, float = true })
					end, opts)
					vim.keymap.set("n", "]d", function()
						vim.diagnostic.jump({ count = 1, float = true })
					end, opts)
					vim.keymap.set("n", "<leader>dl", vim.diagnostic.setloclist, opts) -- all diagnostics in loclist
				end,
			})
		end,
	},

	-- Flutter/Dart: wraps the Dart SDK's language server (dartls) and adds
	-- Flutter extras (hot reload on save, device/emulator picker, DevTools).
	-- dartls ships with the Flutter SDK, so it needs `flutter` on your PATH
	-- (not installed via mason). LSP keymaps come from the LspAttach autocmd above.
	{
		"akinsho/flutter-tools.nvim",
		lazy = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"stevearc/dressing.nvim", -- nicer UI for the device/emulator picker
		},
		config = function()
			require("flutter-tools").setup({
				lsp = {
					settings = {
						completeFunctionCalls = true,
						showTodos = true,
						renameFilesWithClasses = "prompt",
					},
				},
			})
		end,
	},

	-- Gitsigns: git change markers in the sign column, hunk navigation/staging
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			local gitsigns = require("gitsigns")
			gitsigns.setup()

			vim.keymap.set("n", "]c", gitsigns.next_hunk, { desc = "Next git hunk" })
			vim.keymap.set("n", "[c", gitsigns.prev_hunk, { desc = "Prev git hunk" })
			vim.keymap.set("n", "<leader>hp", gitsigns.preview_hunk, { desc = "Preview hunk" })
			vim.keymap.set("n", "<leader>hs", gitsigns.stage_hunk, { desc = "Stage hunk" })
			vim.keymap.set("n", "<leader>hr", gitsigns.reset_hunk, { desc = "Reset hunk" })
			vim.keymap.set("n", "<leader>hb", gitsigns.blame_line, { desc = "Blame line" })
		end,
	},

	-- Neoscroll: smooth/animated scrolling for <C-u>/<C-d>/zz/etc.
	{
		"karb94/neoscroll.nvim",
		event = "VeryLazy",
		config = function()
			local neoscroll = require("neoscroll")
			neoscroll.setup({
				-- Only animate the mappings below; leave everything else instant.
				mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "zt", "zz", "zb" },
				hide_cursor = true, -- hide cursor while scrolling
				stop_eof = true, -- stop at <EOF> when scrolling downwards
				respect_scrolloff = false,
				cursor_scrolls_alone = true, -- cursor keeps moving even if the window can't scroll
				duration_multiplier = 1.0,
				easing = "quadratic",
				performance_mode = false,
			})

			-- Slightly faster for the big jumps, snappier for the small ones.
			local keymap = {
				["<C-u>"] = function()
					neoscroll.ctrl_u({ duration = 150 })
				end,
				["<C-d>"] = function()
					neoscroll.ctrl_d({ duration = 150 })
				end,
				["<C-b>"] = function()
					neoscroll.ctrl_b({ duration = 350 })
				end,
				["<C-f>"] = function()
					neoscroll.ctrl_f({ duration = 350 })
				end,
				["zt"] = function()
					neoscroll.zt({ half_win_duration = 100 })
				end,
				["zz"] = function()
					neoscroll.zz({ half_win_duration = 100 })
				end,
				["zb"] = function()
					neoscroll.zb({ half_win_duration = 100 })
				end,
			}
			for key, func in pairs(keymap) do
				vim.keymap.set({ "n", "v", "x" }, key, func)
			end
		end,
	},

	-- DiffView for Git changes
	{
		"sindrets/diffview.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFileHistory" },
		keys = {
			{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Git diff view" },
			{ "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close diff view" },
			{ "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File git history" },
			{ "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Repo git history" },
		},
		config = function()
			require("diffview").setup()
		end,
	},
})
