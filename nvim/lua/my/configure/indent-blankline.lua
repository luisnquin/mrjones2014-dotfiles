return {
  'lukas-reineke/indent-blankline.nvim',
  main = 'ibl',
  event = 'BufRead',
  opts = {
    exclude = {
      buftypes = {
        'terminal',
        'nofile',
        'quickfix',
        'prompt',
      },
      filetypes = {
        'terminal',
        'term',
        'gitcommit',
        'qf',
        'lspinfo',
        'packer',
        'checkhealth',
        'help',
        'man',
        'gitcommit',
        '',
      },
    },

    scope = {
      enabled = true,
      char = '│',
      show_start = false,
      show_end = false,
      include = {
        node_type = {
          ['*'] = {
            '*',
          },
        },
      },
    },
  },
}
