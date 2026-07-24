-- ~/.config/nvim/init.lua — minimal starter. Replace with your own config later.

-- ---- Leader --------------------------------------------------------------
-- Must be set before lazy.nvim loads: plugin `keys` specs resolve <leader> at
-- load time.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ---- Options -------------------------------------------------------------
local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
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
			-- `transparent` is a setup-time option, so switching it means re-running
			-- setup and re-applying the colorscheme. Dark stays transparent (looks
			-- good over Ghostty's blur); light goes opaque (transparency washes the
			-- pale Day palette out to the point it stops reading as light mode).
			---@param background string "dark" | "light"
			local function applyTheme(background)
				---@type boolean
				local isDark = background == "dark"
				require("tokyonight").setup({
					---@type string
					style = "night", -- dark variant: storm | moon | night
					---@type string
					light_style = "day", -- used when vim.o.background == "light"
					transparent = isDark,
					terminal_colors = true,
					styles = {
						comments = { italic = true },
						keywords = { italic = true },
						functions = {},
						variables = {},
						-- Match the buffer: clear in dark, normal (opaque) in light.
						sidebars = isDark and "transparent" or "normal",
						floats = isDark and "transparent" or "normal",
					},
					---@param highlights table<string, table>
					---@param colors table<string, string>
					on_highlights = function(highlights, colors)
						-- Only clear float/gutter backgrounds when transparent; in light
						-- mode let them keep the theme's opaque backgrounds.
						---@type string
						local clearBg = isDark and "NONE" or colors.bg_float
						highlights.NormalFloat = { bg = clearBg }
						highlights.FloatBorder = { fg = colors.blue, bg = clearBg }
						highlights.TelescopeNormal = { bg = clearBg }
						highlights.TelescopeBorder = { fg = colors.blue, bg = clearBg }
						highlights.TelescopePromptNormal = { bg = clearBg }
						highlights.TelescopePromptBorder = { fg = colors.blue, bg = clearBg }
						highlights.SignColumn = { bg = isDark and "NONE" or colors.bg }
						highlights.LineNr = { fg = colors.fg_gutter, bg = isDark and "NONE" or colors.bg }
						highlights.CursorLineNr = { fg = colors.orange, bg = isDark and "NONE" or colors.bg }
					end,
				})
				vim.o.background = background
				vim.cmd.colorscheme("tokyonight")
			end

			-- Match the macOS system appearance so the (transparent) dark buffer is
			-- never rendered over Ghostty's light background, and vice versa.
			-- `AppleInterfaceStyle` is "Dark" in dark mode and unset (command fails)
			-- in light mode.
			---@return string "dark" | "light"
			local function detectSystemBackground()
				local isDark = vim.fn.system("defaults read -g AppleInterfaceStyle 2>/dev/null"):match("Dark")
				return isDark and "dark" or "light"
			end

			applyTheme(detectSystemBackground())

			-- Re-detect on demand (e.g. after flipping macOS appearance).
			vim.api.nvim_create_user_command("ThemeSync", function()
				applyTheme(detectSystemBackground())
			end, { desc = "Match theme to macOS appearance" })
			map("n", "<leader>us", "<cmd>ThemeSync<cr>", { desc = "Sync theme to macOS" })

			-- Auto-follow the system: changing macOS appearance happens outside
			-- Neovim, so refocusing the terminal is the reliable moment to catch it.
			-- Only re-apply when the mode actually changed, to avoid flicker.
			vim.api.nvim_create_autocmd("FocusGained", {
				callback = function()
					---@type string
					local detected = detectSystemBackground()
					if detected ~= vim.o.background then
						applyTheme(detected)
					end
				end,
				desc = "Follow macOS light/dark on focus",
			})

			-- Flip between the light and dark tokyonight variants live. Ghostty's
			-- own theme follows macOS on its own.
			vim.api.nvim_create_user_command("ThemeToggle", function()
				applyTheme(vim.o.background == "dark" and "light" or "dark")
			end, { desc = "Toggle light/dark tokyonight" })
			map("n", "<leader>ut", "<cmd>ThemeToggle<cr>", { desc = "Toggle light/dark theme" })
		end,
	},

	-- File tree sidebar. Loads on the keymaps/command only, so it costs nothing
	-- at startup.
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		cmd = "Neotree",
		keys = {
			{ "<leader>fe", "<cmd>Neotree toggle<cr>", desc = "Toggle file explorer" },
			{ "<leader>fE", "<cmd>Neotree reveal<cr>", desc = "Reveal current file in explorer" },
		},
		opts = {
			-- Close the sidebar as soon as a file is opened; the bufferline takes
			-- over navigation from there.
			close_if_last_window = true,
			filesystem = {
				-- Move the tree's root when :cd changes, and track the current buffer.
				follow_current_file = { enabled = true },
				-- Use the OS watcher rather than polling, so external changes show up.
				use_libuv_file_watcher = true,
				filtered_items = {
					-- Dotfiles are shown but dimmed; toggle with H inside the tree.
					hide_dotfiles = false,
					hide_gitignored = true,
					hide_by_name = { ".git", "node_modules", ".gradle", ".idea", "build" },
				},
			},
			window = {
				width = 32,
			},
		},
	},

	-- Replaces the cmdline, messages and search prompt with floating windows.
	-- Pairs with the transparent theme: no opaque bar at the bottom of the screen.
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify", -- routes :messages and notifications to toasts
		},
		config = function()
			require("notify").setup({
				---@type string
				-- Follows the active theme instead of a hardcoded colour so it works in
				-- both light and dark mode; resolved from the NormalFloat highlight.
				background_colour = "NormalFloat",
				render = "compact",
				stages = "static", -- no fade animation; avoids artefacts over a blurred terminal
				timeout = 3000,
			})

			require("noice").setup({
				lsp = {
					-- Render LSP hover/signature markdown through Treesitter.
					override = {
						["vim.lsp.util.convert_input_to_markdown_lines"] = true,
						["vim.lsp.util.stylize_markdown"] = true,
					},
				},
				presets = {
					bottom_search = true, -- classic bottom cmdline for / and ?
					command_palette = true, -- : cmdline and popupmenu together, centred
					long_message_to_split = true, -- long messages open in a split, not a toast
					lsp_doc_border = true,
				},
			})

			map("n", "<leader>nh", "<cmd>NoiceHistory<cr>", { desc = "Message history" })
			map("n", "<leader>nd", "<cmd>NoiceDismiss<cr>", { desc = "Dismiss notifications" })
		end,
	},

	-- Vertical guides at each indent level, plus an underline marking the
	-- start/end of the block the cursor sits in. tokyonight colours these.
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("ibl").setup({
				indent = { char = "\u{2502}" },
				scope = {
					enabled = true,
					show_start = true,
					show_end = false,
				},
				-- Buffers where guides are noise rather than structure.
				exclude = {
					filetypes = {
						"help",
						"lazy",
						"mason",
						"checkhealth",
						"gitcommit",
						"markdown",
						"TelescopePrompt",
						"TelescopeResults",
					},
				},
			})
		end,
	},

	-- Tab bar across the top listing open buffers. tokyonight styles this
	-- automatically via its bufferline integration.
	{
		"akinsho/bufferline.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		event = "VeryLazy",
		config = function()
			require("bufferline").setup({
				options = {
					---@type string
					mode = "buffers", -- one entry per buffer, not per tabpage
					diagnostics = "nvim_lsp",
					show_buffer_close_icons = false,
					separator_style = "thin",
					-- Indent the bar so it doesn't sit under a file tree, if one is open.
					offsets = {
						{ filetype = "neo-tree", text = "Files", highlight = "Directory", separator = true },
					},
				},
			})

			map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
			map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous buffer" })
			map("n", "<leader>bp", "<cmd>BufferLineTogglePin<cr>", { desc = "Pin/unpin buffer" })
			map("n", "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", { desc = "Close other buffers" })
			map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Close buffer" })
		end,
	},

	-- Popup listing the available follow-up keys after a prefix (<leader>, g, z, ").
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		config = function()
			-- How long which-key waits before showing. Vim's default of 1000ms is
			-- too slow to be useful as a reminder.
			vim.o.timeout = true
			vim.o.timeoutlen = 400

			local wk = require("which-key")
			wk.setup({
				---@type string
				preset = "helix", -- right-hand side panel; "classic" for the bottom bar
				win = { border = "rounded" },
			})

			-- Names for the prefixes used above, so the popup groups them instead of
			-- listing bare keys.
			wk.add({
				{ "<leader>b", group = "buffer" },
				{ "<leader>n", group = "noice (messages)" },
				{ "<leader>u", group = "ui / toggle" },
				{ "<leader>f", group = "find (telescope)" },
				{ "<leader>g", group = "git (diffview)" },
				{ "<leader>h", group = "git hunk" },
				{ "<leader>d", group = "diagnostics / symbols" },
				{ "<leader>c", group = "code" },
				{ "<leader>w", group = "write / workspace" },
			})
		end,
	},

	-- Statusline. `theme = "auto"` picks up tokyonight; the section backgrounds
	-- are cleared to NONE so the transparent buffer background carries through.
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			---@type table
			local theme = require("lualine.themes.tokyonight")
			for _, mode in pairs({ "normal", "insert", "visual", "replace", "command", "inactive" }) do
				if theme[mode] then
					if theme[mode].c then
						theme[mode].c.bg = "NONE"
					end
					if theme[mode].b then
						theme[mode].b.bg = "NONE"
					end
				end
			end

			require("lualine").setup({
				options = {
					theme = theme,
					icons_enabled = true, -- needs a Nerd Font (JetBrains Mono Nerd Font is set in Ghostty)
					component_separators = { left = "", right = "" },
					section_separators = { left = "", right = "" },
					-- One statusline for the whole window instead of one per split.
					globalstatus = true,
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch", "diff", "diagnostics" },
					-- Path relative to cwd, with a modified/readonly marker.
					lualine_c = { { "filename", path = 1 } },
					lualine_x = { "filetype" },
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
				extensions = { "lazy", "mason", "quickfix" },
			})
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

			-- `--hidden` includes dotfiles/dotdirs; .git/ is still excluded via
			-- file_ignore_patterns below. Needs `fd` (brew install fd); when it is
			-- missing we leave find_command unset so Telescope uses its builtin
			-- finder instead of erroring.
			---@type boolean
			local hasFd = vim.fn.executable("fd") == 1
			---@type string[]
			local fdFindCommand = { "fd", "--type", "f", "--strip-cwd-prefix", "--hidden" }
			---@type string[]
			local fdFindAllCommand = vim.list_extend(vim.deepcopy(fdFindCommand), { "--no-ignore" })

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
						-- Also hides files listed in .gitignore (build output usually is).
						find_command = hasFd and fdFindCommand or nil,
					},
				},
			})
			pcall(telescope.load_extension, "fzf")

			local builtin = require("telescope.builtin")
			map("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
			map("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
			map("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
			map("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
			map("n", "<leader>fa", function()
				builtin.find_files({ find_command = hasFd and fdFindAllCommand or nil, no_ignore = true })
			end, { desc = "Find all files including ignored" })
		end,
	},

	-- LSP: mason installs/manages servers, lspconfig wires them into nvim
	{
		"mason-org/mason.nvim",
		config = true,
	},
	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = { "mason-org/mason.nvim" },
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = { "kotlin_language_server", "ts_ls" },
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = { "mason-org/mason-lspconfig.nvim" },
		config = function()
			vim.lsp.enable("kotlin_language_server")
			vim.lsp.enable("ts_ls")

			-- Keymaps that apply once an LSP client attaches to a buffer
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local telescope = require("telescope.builtin")

					-- Buffer-local map with a description, so which-key can label it.
					---@param mode string|string[]
					---@param lhs string
					---@param rhs function
					---@param desc string
					local function lspMap(mode, lhs, rhs, desc)
						map(mode, lhs, rhs, { buffer = args.buf, desc = desc })
					end

					-- Navigation
					lspMap("n", "gd", vim.lsp.buf.definition, "Go to definition")
					lspMap("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
					lspMap("n", "gi", telescope.lsp_implementations, "Go to implementations")
					lspMap("n", "gy", vim.lsp.buf.type_definition, "Go to type definition")
					lspMap("n", "gr", telescope.lsp_references, "Find references (usages)")

					-- Info
					lspMap("n", "K", vim.lsp.buf.hover, "Hover docs")
					lspMap("i", "<C-k>", vim.lsp.buf.signature_help, "Signature help")

					-- Symbols (fuzzy-searchable via Telescope)
					lspMap("n", "<leader>ds", telescope.lsp_document_symbols, "Document symbols")
					lspMap("n", "<leader>ws", telescope.lsp_dynamic_workspace_symbols, "Workspace symbols")

					-- Refactoring
					lspMap("n", "grn", vim.lsp.buf.rename, "Rename symbol")
					lspMap({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")

					-- Diagnostics
					lspMap("n", "<leader>e", vim.diagnostic.open_float, "Show diagnostic under cursor")
					lspMap("n", "[d", function()
						vim.diagnostic.jump({ count = -1, float = true })
					end, "Previous diagnostic")
					lspMap("n", "]d", function()
						vim.diagnostic.jump({ count = 1, float = true })
					end, "Next diagnostic")
					lspMap("n", "<leader>dl", vim.diagnostic.setloclist, "All diagnostics to loclist")
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

			map("n", "]c", function()
				gitsigns.nav_hunk("next")
			end, { desc = "Next git hunk" })
			map("n", "[c", function()
				gitsigns.nav_hunk("prev")
			end, { desc = "Prev git hunk" })
			map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "Preview hunk" })
			map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "Stage hunk" })
			map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "Reset hunk" })
			map("n", "<leader>hb", gitsigns.blame_line, { desc = "Blame line" })
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
				map({ "n", "v", "x" }, key, func)
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

-- ---- Secondary leader ----------------------------------------------------
-- <leader> is expanded to the current mapleader when each mapping is defined,
-- so every mapping above is bound to <Space> only. Forward `\` (the Vim default
-- leader) into <Space> so both prefixes work. `remap = true` is required: the
-- point is to recurse into the leader mappings.
map({ "n", "v", "x" }, "\\", "<Space>", { remap = true, desc = "Alias for <leader>" })
