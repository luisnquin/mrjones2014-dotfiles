local conditions = require('heirline.conditions')
local my_conditions = require('my.configure.heirline.conditions')
local utils = require('heirline.utils')
local sep = require('my.configure.heirline.separators')
local path = require('my.utils.path')
local clipboard = require('my.utils.clipboard')
local editor = require('my.utils.editor')

local M = {}

M.Mode = {
  init = function(self)
    self.mode = vim.fn.mode(1)
  end,
  static = {
    mode_icons = {
      n = '',
      no = '',
      nov = '',
      noV = '',
      ['no\22'] = '',
      niI = '',
      niR = '',
      niV = '',
      nt = '',
      v = '',
      vs = '',
      V = '',
      Vs = '',
      ['\22'] = '',
      ['\22s'] = '',
      s = '󱐁',
      S = '󱐁',
      ['\19'] = '󱐁',
      i = '',
      ic = '',
      ix = '',
      R = '',
      Rc = '',
      Rx = '',
      Rv = '',
      Rvc = '',
      Rvx = '',
      c = '',
      cv = '',
      r = '',
      rm = '',
      ['r?'] = '',
      ['!'] = '',
      t = '',
    },
    mode_colors = {
      n = 'green',
      i = 'blue',
      v = 'yellow',
      V = 'yellow',
      ['\22'] = 'cyan',
      c = 'orange',
      s = 'yellow',
      S = 'yellow',
      ['\19'] = 'orange',
      R = 'purple',
      r = 'purple',
      ['!'] = 'green',
      t = 'green',
    },
  },
  {
    provider = function(self)
      return string.format(' %s ', self.mode_icons[self.mode])
    end,
    hl = function(self)
      local mode = self.mode:sub(1, 1)
      return { bg = self.mode_colors[mode], fg = 'black', bold = true }
    end,
  },
  {
    provider = sep.rounded_right,
    hl = function(self)
      local mode = self.mode:sub(1, 1)
      if conditions.is_git_repo() or vim.fs.root(assert(vim.uv.cwd()), '.git') then
        return { fg = self.mode_colors[mode], bg = 'gray' }
      else
        return { fg = self.mode_colors[mode], bg = 'surface0' }
      end
    end,
  },
}

local _cached_branch = ''
local _cached_jj_bookmark = ''
local _branch_cache_valid = false
local _jj_cache_valid = false
local _git_watcher
local _jj_watcher

local function setup_git_watcher()
  if _git_watcher then
    _git_watcher:stop()
    _git_watcher = nil
  end

  local git_dir = vim.fn.finddir('.git', '.;')
  if git_dir == '' then
    return
  end

  _git_watcher = vim.uv.new_fs_event()
  if _git_watcher == nil then
    return
  end
  _git_watcher:start(git_dir, { recursive = true }, function(err, filename)
    if err then
      return
    end
    -- Invalidate cache on HEAD or refs changes
    if filename and (filename:match('HEAD') or filename:match('refs/')) then
      _branch_cache_valid = false
      vim.schedule(vim.cmd.redrawstatus)
    end
  end)
end

local function setup_jj_watcher()
  if _jj_watcher then
    _jj_watcher:stop()
    _jj_watcher = nil
  end

  local jj_dir = vim.fn.finddir('.jj', '.;')
  if jj_dir == '' then
    return
  end

  _jj_watcher = vim.uv.new_fs_event()
  if _jj_watcher == nil then
    return
  end
  _jj_watcher:start(jj_dir, { recursive = true }, function(err)
    if err then
      return
    end
    -- Invalidate cache on any .jj directory changes
    _jj_cache_valid = false
    vim.schedule(vim.cmd.redrawstatus)
  end)
end

local function git_branch()
  if my_conditions.is_jj_repo() then
    if not _jj_watcher then
      setup_jj_watcher()
    end

    if not _jj_cache_valid then
      vim.system({
        'jj',
        'log',
        '--ignore-working-copy',
        '-r',
        '@-',
        '-n',
        '1',
        '--no-graph',
        '--no-pager',
        '-T',
        "separate(' ', format_short_change_id(self.change_id()), self.bookmarks())",
      }, { text = true }, function(out)
        local trimmed = vim.trim(out.stdout or '')
        if trimmed ~= '' then
          _cached_jj_bookmark = trimmed
          _jj_cache_valid = true
          vim.schedule(vim.cmd.redrawstatus)
        end
      end)
    end

    return _cached_jj_bookmark
  end

  local branch = vim.g.gitsigns_head or vim.b.gitsigns_head
  if branch then
    return branch
  end

  if not _git_watcher then
    setup_git_watcher()
  end

  if not _branch_cache_valid then
    _cached_branch = vim.trim(vim.system({ 'git', 'branch', '--show-current' }, { text = true }):wait().stdout or '')
    _branch_cache_valid = true
  end

  return _cached_branch
end

-- Cleanup function to stop watchers when needed
local function cleanup_watchers()
  if _git_watcher then
    _git_watcher:stop()
    _git_watcher = nil
  end
  if _jj_watcher then
    _jj_watcher:stop()
    _jj_watcher = nil
  end
end

-- Auto-cleanup on VimLeavePre
vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = cleanup_watchers,
})

M.Branch = {
  init = function(self)
    local url = require('my.utils.git').git_remote()
    if string.find(url, 'github.com') then
      self.icon = ' '
    elseif string.find(url, 'gitlab') then
      self.icon = '󰮠 '
    else
      self.icon = ' '
    end
  end,
  condition = function()
    local branch = git_branch()
    return branch ~= nil and branch ~= ''
  end,
  on_click = {
    callback = function()
      local branch = git_branch()
      if branch and branch ~= '' then
        clipboard.copy(branch)
        vim.notify('Git branch copied to clipboard')
      end
    end,
    name = 'heirline_copy_git_branch',
  },
  {
    provider = function(self)
      return string.format(' %s %s', self.icon, git_branch())
    end,
    hl = { fg = 'green', bg = 'gray' },
  },
  {
    provider = sep.rounded_right,
    hl = { fg = 'gray', bg = 'surface0' },
  },
}

M.IsTmpFile = {
  init = function(self)
    self.bufname = vim.api.nvim_buf_get_name(0)
    -- if its in the tmpdir just show the filename and an icon
    if self.bufname:find(vim.fn.stdpath('run')) then
      self.temporary = true
    else
      self.temporary = false
    end
  end,
  hl = { bg = 'surface0' },
  {
    condition = function(self)
      return self.temporary
    end,
    provider = ' 󰪺',
  },
}

M.FilePath = {
  init = function(self)
    self.bufname = vim.api.nvim_buf_get_name(0)
    -- if its in the tmpdir just show the filename and an icon
    if self.bufname:find(vim.fn.stdpath('run')) then
      self.temporary = true
    else
      self.temporary = false
    end
  end,
  hl = { bg = 'surface0' },
  provider = ' ',
  {
    condition = function(self)
      return my_conditions.should_show_filename(self.bufname)
    end,
    provider = function(self)
      local filepath = vim.api.nvim_buf_get_name(0)
      if self.temporary then
        filepath = path.filename(filepath)
      end
      return path.relative(filepath)
    end,
    on_click = {
      callback = function()
        clipboard.copy(path.relative(vim.api.nvim_buf_get_name(0)))
        vim.notify('Relative filepath copied to clipboard')
      end,
      name = 'heirline_copy_filepath',
    },
  },
}

local function unsaved_count()
  if #vim.fn.expand('%') == 0 then
    return 0
  else
    return #vim
      .iter(vim.api.nvim_list_bufs())
      :filter(function(buf)
        return vim.bo[buf].ft ~= 'minifiles'
          and vim.bo[buf].ft ~= 'dap-repl'
          and vim.bo[buf].bt ~= 'acwrite'
          and vim.bo[buf].modifiable
          and vim.bo[buf].modified
          and vim.bo[buf].buflisted
      end)
      :totable()
  end
end

M.UnsavedChanges = {
  init = function(self)
    self.unsaved_count = unsaved_count()
  end,
  {
    condition = function(self)
      return self.unsaved_count > 0
    end,
    {
      {

        provider = sep.rounded_left,
        hl = { fg = 'yellow', bg = 'surface0' },
      },
      {
        provider = function(self)
          return string.format(' %s', self.unsaved_count)
        end,
        hl = { bg = 'yellow', fg = 'black' },
      },
      {
        provider = sep.rounded_right,
        hl = { fg = 'yellow', bg = 'surface0' },
      },
    },
  },
}

M.LspFormatToggle = {
  provider = function()
    if require('my.utils.lsp').get_formatter_name(0) and require('my.utils.lsp').is_formatting_enabled() then
      return '   '
    else
      return '   '
    end
  end,
  hl = { bg = 'surface0' },
  on_click = {
    callback = function()
      require('my.utils.lsp').toggle_formatting_enabled()
    end,
    name = 'heirline_LSP',
  },
  {
    provider = '󰗈  auto-format',
    hl = { bg = 'surface0' },
  },
  {
    provider = function()
      local name = require('my.utils.lsp').get_formatter_name(0)
      if name then
        return string.format(' (%s)  ', name)
      end
      return '  '
    end,
    hl = { bg = 'surface0' },
  },
}

M.SpellCheckToggle = {
  provider = function()
    if editor.spellcheck_enabled() then
      return '   '
    else
      return '   '
    end
  end,
  hl = { bg = 'surface0' },
  on_click = {
    callback = editor.toggle_spellcheck,
    name = 'heirline_Spellcheck',
  },
  {
    provider = '󰓆  Spellcheck  ',
    hl = { bg = 'surface0' },
  },
}

M.RecordingMacro = {
  provider = function()
    local macro_reg = vim.fn.reg_recording()
    if macro_reg == '' then
      return ''
    end

    return string.format(' Recording macro: %s  ', macro_reg)
  end,
  hl = { bg = 'surface0' },
}

local Tabpage = {
  provider = function(self)
    return '%' .. self.tabnr .. 'T ' .. self.tabpage .. ' %T'
  end,
  hl = function(self)
    if self.is_active then
      return { bg = 'cyan', fg = 'surface0' }
    else
      return { bg = 'surface1' }
    end
  end,
}

M.Tabs = {
  -- only show this component if there's 2 or more tabpages
  condition = function()
    return #vim.api.nvim_list_tabpages() >= 2
  end,
  utils.make_tablist(Tabpage),
}

return M
