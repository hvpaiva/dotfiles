return {
  {
    'nvim-mini/mini.statusline',
    version = '*',
    config = function()
      local ms = require 'mini.statusline'

      local nord = {
        dark = '#252A32',
        gray_blue = '#5E7086',
        polar_night = { '#2E3440', '#3B4252', '#434C5E', '#4C566A' },
        snow_storm = { '#D8DEE9', '#E5E9F0', '#ECEFF4' },
        frost = { '#8FBCBB', '#88C0D0', '#81A1C1', '#5E81AC' },
        aurora = { red = '#BF616A', orange = '#D08770', yellow = '#EBCB8B', green = '#A3BE8C', purple = '#B48EAD' },
      }

      ms.setup {
        set_vim_settings = true,
        content = {
          active = function()
            local mode, mode_hl = ms.section_mode { trunc_width = 4000 }
            local git = ms.section_git { trunc_width = 40 }
            local filename = ms.section_filename { trunc_width = 140 }
            local location = '%l:%c'

            return ms.combine_groups {
              { hl = mode_hl, strings = { mode } },
              { hl = 'MiniStatuslineDevinfo', strings = { git } },
              '%<',
              { hl = 'MiniStatuslineFilename', strings = { filename } },
              '%=',
              { hl = mode_hl, strings = { location, '%P' } },
            }
          end,
        },
      }

      -- local function apply_statusline_hl()
      --   vim.api.nvim_set_hl(0, 'MiniStatuslineDevinfo', { fg = nord.polar_night[4], bg = nord.polar_night[2] })
      --   vim.api.nvim_set_hl(0, 'MiniStatuslineFileinfo', { fg = nord.snow_storm[1], bg = nord.polar_night[3] })
      --   vim.api.nvim_set_hl(0, 'MiniStatuslineFilename', { fg = nord.gray_blue, bg = nord.polar_night[1] })
      --   vim.api.nvim_set_hl(0, 'MiniStatuslineInactive', { fg = nord.polar_night[2], bg = nord.polar_night[1] })
      --   vim.api.nvim_set_hl(0, 'MiniStatuslineModeCommand', { fg = nord.polar_night[1], bg = nord.aurora.yellow, bold = true })
      --   vim.api.nvim_set_hl(0, 'MiniStatuslineModeInsert', { fg = nord.polar_night[1], bg = nord.aurora.green, bold = true })
      --   vim.api.nvim_set_hl(0, 'MiniStatuslineModeNormal', { fg = nord.polar_night[1], bg = nord.frost[3], bold = true })
      --   vim.api.nvim_set_hl(0, 'MiniStatuslineModeOther', { fg = nord.polar_night[1], bg = nord.frost[1], bold = true })
      --   vim.api.nvim_set_hl(0, 'MiniStatuslineModeReplace', { fg = nord.polar_night[1], bg = nord.aurora.red, bold = true })
      --   vim.api.nvim_set_hl(0, 'MiniStatuslineModeVisual', { fg = nord.polar_night[1], bg = nord.aurora.purple, bold = true })
      -- end
      --
      -- apply_statusline_hl()
      --
      -- vim.api.nvim_create_autocmd({ 'ColorScheme', 'VimEnter' }, {
      --   callback = apply_statusline_hl,
      -- })
    end,
  },
}
