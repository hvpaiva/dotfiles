# ble.sh faces for YSAP. Source this file from ~/.blerc or ~/.config/blesh/init.sh.
#
# Same color layout as the Catppuccin Mocha faces this started from (scheme by
# @abhijeeth-babu, https://github.com/akinomyoga/ble.sh/discussions/411), with each
# Catppuccin color swapped for its YSAP counterpart:
#   Sapphire  commands             -> 4 blue        Blue      directories   -> 6 cyan
#   Peach     builtins, variables  -> orange        Sky       orphans       -> 14 light cyan
#   Mauve     keywords             -> 5 pink        Green     strings       -> 2 green
#   Lavender  function names       -> 12 light blue Red       expansions    -> 1 red
#   Flamingo  options, escapes     -> 13 light pink Rosewater variable names -> 11 light cream
#   Overlay   braces, delimiters   -> border gray   Surface   selection     -> selection
# Comments are 8 gray, since YSAP's yellow is a pale cream. Slot numbers follow
# the terminal palette; orange, the border gray and the selection have no slot.

ble-face \
  argument_error='fg=0,bg=1' \
  argument_option='fg=13,italic' \
  auto_complete='fg=#626262,italic' \
  cmdinfo_cd_cdpath='fg=6,bg=0,italic' \
  command_alias='fg=4' \
  command_builtin='fg=#ffaf5f' \
  command_directory='fg=6' \
  command_file='fg=4' \
  command_function='fg=4' \
  command_keyword='fg=5' \
  command_suffix='fg=0,bg=2' \
  command_suffix_new='fg=0,bg=1' \
  disabled='fg=#626262' \
  filename_character='fg=15,bg=0,underline' \
  filename_directory='fg=6' \
  filename_directory_sticky='fg=0,bg=2' \
  filename_executable='fg=2,bold' \
  filename_ls_colors='none' \
  filename_orphan='fg=14,bold' \
  filename_other='none' \
  filename_setgid='fg=0,bg=3,underline' \
  filename_setuid='fg=0,bg=#ffaf5f,underline' \
  menu_filter_input='fg=0,bg=3' \
  overwrite_mode='fg=0,bg=14' \
  prompt_status_line='fg=0,bg=8' \
  region='bg=#213521' \
  region_insert='bg=#213521' \
  region_match='fg=0,bg=3' \
  region_target='fg=0,bg=5' \
  syntax_brace='fg=#626262' \
  syntax_command='fg=4' \
  syntax_comment='fg=8' \
  syntax_delimiter='fg=#626262' \
  syntax_document='fg=11,bold' \
  syntax_document_begin='fg=11,bold' \
  syntax_error='fg=0,bg=1' \
  syntax_escape='fg=13' \
  syntax_expr='fg=5' \
  syntax_function_name='fg=12' \
  syntax_glob='fg=#ffaf5f' \
  syntax_history_expansion='fg=12,italic' \
  syntax_param_expansion='fg=1' \
  syntax_quotation='fg=2' \
  syntax_tilde='fg=5' \
  syntax_varname='fg=11' \
  varname_array='fg=#ffaf5f' \
  varname_empty='fg=#ffaf5f' \
  varname_export='fg=#ffaf5f' \
  varname_expr='fg=#ffaf5f' \
  varname_hash='fg=#ffaf5f' \
  varname_new='fg=#ffaf5f' \
  varname_number='fg=11' \
  varname_readonly='fg=#ffaf5f' \
  varname_transform='fg=#ffaf5f' \
  varname_unset='fg=0,bg=1' \
  vbell_erase='bg=#626262'
