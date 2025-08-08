local clipboard = require('my.utils.clipboard')
return {
  {
    'folke/snacks.nvim',
    keys = {
      {
        '<leader>gy',
        function()
          ---@diagnostic disable-next-line: missing-fields
          require('snacks.gitbrowse').open({ open = clipboard.copy, notify = false })
          vim.notify('Copied permalink')
        end,
        desc = 'Copy git permalink',
        mode = { 'n', 'v' },
      },
    },
    opts = {
      gitbrowse = {
        what = 'permalink',
        url_patterns = {
          ['github%.com'] = {
            branch = '/tree/{branch}',
            file = '/blob/{branch}/{file}#L{line_start}-L{line_end}',
            permalink = '/blob/{commit}/{file}#L{line_start}-L{line_end}',
            commit = '/commit/{commit}',
          },
          ['gitlab%.1password%.io'] = {
            branch = '/-/tree/{branch}',
            file = '/-/blob/{branch}/{file}#L{line_start}-L{line_end}',
            permalink = '/-/blob/{commit}/{file}#L{line_start}-L{line_end}',
            commit = '/-/commit/{commit}',
          },
        },
      },
    },
  },
  {
    'lewis6991/gitsigns.nvim',
    lazy = false,
    keys = {
      {
        '<leader>bl',
        function()
          vim.cmd.Gitsigns('toggle_current_line_blame')
        end,
        desc = 'Toggle inline git blame',
      },
    },
    opts = {
      current_line_blame = false,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol',
        delay = 100,
      },
      signcolumn = true,
      current_line_blame_formatter = ' <abbrev_sha> | <author>, <author_time> - <summary>',
      on_attach = function()
        vim.cmd.redrawstatus()
      end,
    },
  },
  {
    'sindrets/diffview.nvim',
    cmd = {
      'DiffviewLog',
      'DiffviewOpen',
      'DiffviewClose',
      'DiffviewRefresh',
      'DiffviewFocusFiles',
      'DiffviewFileHistory',
      'DiffviewToggleFiles',
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        file_panel = {
          win_config = {
            position = 'right',
          },
        },
      },
    },
  },
  { 'NicolasGB/jj.nvim', cmd = 'J', opts = {} },
}
