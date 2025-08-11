-- plugins with little or no config can go here

return {
  { 'nvim-lua/plenary.nvim' },
  {
    'DaikyXendo/nvim-material-icon',
    opts = {},
  },
  { 'tpope/vim-eunuch', cmd = { 'Delete', 'Move', 'Chmod', 'SudoWrite', 'Rename' } },
  { 'tpope/vim-sleuth', event = 'BufReadPre' },
  {
    'nat-418/boole.nvim',
    keys = { '<C-a>', '<C-x>' },
    opts = { mappings = { increment = '<C-a>', decrement = '<C-x>' } },
  },
  {
    'mrjones2014/iconpicker.nvim',
    cmds = { 'Icons' },
    init = function()
      vim.api.nvim_create_user_command('Icons', function()
        require('iconpicker').pick(function(icon)
          if not icon or #icon == 0 then
            return
          end

          require('my.utils.clipboard').copy(icon)
          vim.notify('Copied icon to clipboard.', vim.log.levels.INFO)
        end)
      end, { desc = 'Pick NerdFont icons and copy to clipboard' })
    end,
  },
  { 'mrjones2014/lua-gf.nvim', dev = true, ft = 'lua' },
  {
    'echasnovski/mini.splitjoin',
    keys = {
      {
        'gS',
        function()
          require('mini.splitjoin').toggle()
        end,
        desc = 'Split/join arrays, argument lists, etc. from one vs. multiline and vice versa',
      },
    },
  },
  { 'echasnovski/mini.trailspace', event = 'BufRead', opts = {} },
  {
    'max397574/better-escape.nvim',
    event = 'InsertEnter',
    opts = {
      mappings = {
        -- do not map jj because I use jujutsu and the command is jj
        i = { j = { k = '<Esc>', j = false } },
        c = { j = { k = '<Esc>', j = false } },
      },
    },
  },
  {
    'saecki/crates.nvim',
    event = { 'BufRead Cargo.toml' },
    opts = {},
  },
  {
    'folke/lazy.nvim',
    lazy = false,
  },
}
