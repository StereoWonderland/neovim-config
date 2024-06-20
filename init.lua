-- NvimTree recommends to disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Function to set the Python interpreter dynamically
local function get_python_path(workspace)
  -- Use activated virtualenv
  if vim.env.VIRTUAL_ENV then
    return vim.env.VIRTUAL_ENV .. '/bin/python'
  end

  -- Find and use virtualenv in workspace directory
  local match = vim.fn.glob(workspace .. '/.venv/bin/python')
  if match ~= '' then
    return match
  end

  -- Fallback to system Python
  return '/usr/bin/python3'
end


-- Lazy
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Lazy Plugins
require("lazy").setup({
  -- Telescope
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.6',
    dependencies = { 'nvim-lua/plenary.nvim' }
  },

  -- Lualine
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' }
  },

  -- Dashboard
  {
    'nvimdev/dashboard-nvim',
    event = 'VimEnter',
    config = function()
      require('dashboard').setup {
        -- config
      }
    end,
    dependencies = { {'nvim-tree/nvim-web-devicons'}}
  },

  -- Nvim-Tree
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("nvim-tree").setup {}
    end,
  },

  -- TreeSitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function () 
      local configs = require("nvim-treesitter.configs")

      configs.setup({
          ensure_installed = { "c", "lua", "vim", "vimdoc", "python" },
          sync_install = false,
          highlight = { enable = true },
          indent = { enable = true },  
        })
    end
  },

  -- Floaterm
  {
    'voldikss/vim-floaterm',
    dependencies = {
      'jremmen/vim-ripgrep',
    }
  },

  -- Nvim-cmp
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
      'hrsh7th/cmp-vsnip',
      'hrsh7th/vim-vsnip',
    }
  },

  -- LspConfig
  {
    'neovim/nvim-lspconfig',
    config = function()
      -- Insert the configuration code here

      -- General on_attach function for all LSP servers
      local function on_attach(client, bufnr)
        local buf_set_keymap = vim.api.nvim_buf_set_keymap
        local buf_set_option = vim.api.nvim_buf_set_option

        -- Set omnifunc to use LSP's completion function
        buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

        -- Key mappings for LSP features
        local opts = { noremap=true, silent=true }
        buf_set_keymap(bufnr, 'n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
        buf_set_keymap(bufnr, 'n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
        buf_set_keymap(bufnr, 'n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
        buf_set_keymap(bufnr, 'n', 'gi', '<Cmd>lua vim.lsp.buf.implementation()<CR>', opts)
        buf_set_keymap(bufnr, 'n', '<C-k>', '<Cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
        buf_set_keymap(bufnr, 'n', '<leader>rn', '<Cmd>lua vim.lsp.buf.rename()<CR>', opts)
        buf_set_keymap(bufnr, 'n', 'gr', '<Cmd>lua vim.lsp.buf.references()<CR>', opts)
        buf_set_keymap(bufnr, 'n', '<leader>ca', '<Cmd>lua vim.lsp.buf.code_action()<CR>', opts)
        -- buf_set_keymap(bufnr, 'n', '<leader>e', '<Cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
        buf_set_keymap(bufnr, 'n', '[d', '<Cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
        buf_set_keymap(bufnr, 'n', ']d', '<Cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
        buf_set_keymap(bufnr, 'n', '<leader>q', '<Cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
      end

      -- Function to get the Python interpreter path
      local function get_python_path(workspace)
        if vim.env.VIRTUAL_ENV then
          return vim.env.VIRTUAL_ENV .. '/bin/python'
        end
        local match = vim.fn.glob(workspace .. '/.venv/bin/python')
        if match ~= '' then
          return match
        end
        return '/usr/bin/python3'
      end


      -- Setup lspconfig for nvim-cmp
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- Setup for pyright
      require('lspconfig').pyright.setup{
        on_attach = function(client, bufnr)
          -- Call the general on_attach function
          on_attach(client, bufnr)

          -- Update the Python path for the current buffer
          local function update_python_path()
            local python_path = get_python_path(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p:h"))
            client.config.settings.python.pythonPath = python_path
            client.notify('workspace/didChangeConfiguration', { settings = client.config.settings })
            print("Updated Python path to: " .. python_path)
          end

          -- Attach the autocommand to BufEnter
          vim.api.nvim_create_autocmd('BufEnter', {
            buffer = bufnr,
            callback = function()
              vim.schedule(update_python_path)
            end,
          })

          -- Initial update of Python path
          vim.schedule(update_python_path)
        end,

        -- Initial settings
        settings = {
          python = {
            pythonPath = get_python_path(vim.fn.getcwd())
          }
        },
	
	capabilities = capabilities
      }
    end
  },

  -- Themes
  {'navarasu/onedark.nvim'},
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  }
})

-- Telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

-- Lualine
require('lualine').setup()

--Nvim-Tree
require("nvim-tree").setup()
vim.keymap.set('n', '<leader>e', ':NvimTreeFindFileToggle<CR>', { noremap = true })

-- Floaterm
vim.keymap.set('n', '<leader>ft', ':FloatermNew<CR>')
vim.keymap.set('n', '<leader>t', ':FloatermToggle<CR>')
vim.keymap.set('n', '<leader>g', ':FloatermNew --width=0.8 --height=0.9 lazygit<CR>')
-- Note that you can enter normal mode in the terminal with <C-\><C-n>

-- Load nvim-cmp and its sources
local cmp = require'cmp'

cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
    end,
  },
  mapping = {
    ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
    ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
    ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
    ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
    ['<C-e>'] = cmp.mapping({
      i = cmp.mapping.abort(),
      c = cmp.mapping.close(),
    }),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i', 's' }),
  },
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
  }, {
    { name = 'buffer' },
  })
})

-- Set theme
vim.cmd[[colorscheme tokyonight-storm]]

-- custom dashboard header
local db = require("dashboard")
db.setup {
  config = {
    header = {
      "██╗   ██╗██╗███╗   ███╗",
      "██║   ██║██║████╗ ████║",
      "██║   ██║██║██╔████╔██║",
      "╚██╗ ██╔╝██║██║╚██╔╝██║",
      " ╚████╔╝ ██║██║ ╚═╝ ██║",
      "  ╚═══╝  ╚═╝╚═╝     ╚═╝",
    }
  },
}
