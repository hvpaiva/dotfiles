# ble.sh faces for YSAP. Source this file from ~/.blerc or ~/.config/blesh/init.sh.
#
# Same color layout as the Catppuccin Mocha faces this started from (scheme by
# @abhijeeth-babu, https://github.com/akinomyoga/ble.sh/discussions/411), with each
# Catppuccin color swapped for its YSAP counterpart:
#   Sapphire  commands             -> 4 blue        Blue      directories   -> 6 cyan
#   Peach     builtins, variables  -> orange        Sky       orphans       -> 14 light cyan
#   Mauve     keywords             -> 5 pink        Green     strings       -> 2 green
#   Lavender  function names       -> 12 light blue Red       expansions    -> 1 red
#   Flamingo  options, escapes     -> 13 light pink Rosewater variable names -> 15 white
#   Overlay   braces, delimiters   -> border gray   Surface   selection     -> selection
# Comments are 8 gray, because YSAP's yellow is the text cream. Slot numbers follow
# the terminal palette; orange, the border gray and the selection have no slot.

ble-face -s argument_error            'fg=0,bg=1'
ble-face -s argument_option           'fg=13,italic'
ble-face -s auto_complete             'fg=#626262,italic'
ble-face -s cmdinfo_cd_cdpath         'fg=6,bg=0,italic'
ble-face -s command_alias             'fg=4'
ble-face -s command_builtin           'fg=#ffaf5f'
ble-face -s command_directory         'fg=6'
ble-face -s command_file              'fg=4'
ble-face -s command_function          'fg=4'
ble-face -s command_keyword           'fg=5'
ble-face -s command_suffix            'fg=0,bg=2'
ble-face -s command_suffix_new        'fg=0,bg=1'
ble-face -s disabled                  'fg=#626262'
ble-face -s filename_character        'fg=15,bg=0,underline'
ble-face -s filename_directory        'fg=6'
ble-face -s filename_directory_sticky 'fg=0,bg=2'
ble-face -s filename_executable       'fg=2,bold'
ble-face -s filename_ls_colors        'none'
ble-face -s filename_orphan           'fg=14,bold'
ble-face -s filename_other            'none'
ble-face -s filename_setgid           'fg=0,bg=3,underline'
ble-face -s filename_setuid           'fg=0,bg=#ffaf5f,underline'
ble-face -s menu_filter_input         'fg=0,bg=3'
ble-face -s overwrite_mode            'fg=0,bg=14'
ble-face -s prompt_status_line        'fg=0,bg=8'
ble-face -s region                    'bg=#213521'
ble-face -s region_insert             'bg=#213521'
ble-face -s region_match              'fg=0,bg=3'
ble-face -s region_target             'fg=0,bg=5'
ble-face -s syntax_brace              'fg=#626262'
ble-face -s syntax_command            'fg=4'
ble-face -s syntax_comment            'fg=8'
ble-face -s syntax_delimiter          'fg=#626262'
ble-face -s syntax_document           'fg=15,bold'
ble-face -s syntax_document_begin     'fg=15,bold'
ble-face -s syntax_error              'fg=0,bg=1'
ble-face -s syntax_escape             'fg=13'
ble-face -s syntax_expr               'fg=5'
ble-face -s syntax_function_name      'fg=12'
ble-face -s syntax_glob               'fg=#ffaf5f'
ble-face -s syntax_history_expansion  'fg=12,italic'
ble-face -s syntax_param_expansion    'fg=1'
ble-face -s syntax_quotation          'fg=2'
ble-face -s syntax_tilde              'fg=5'
ble-face -s syntax_varname            'fg=15'
ble-face -s varname_array             'fg=#ffaf5f'
ble-face -s varname_empty             'fg=#ffaf5f'
ble-face -s varname_export            'fg=#ffaf5f'
ble-face -s varname_expr              'fg=#ffaf5f'
ble-face -s varname_hash              'fg=#ffaf5f'
ble-face -s varname_new               'fg=#ffaf5f'
ble-face -s varname_number            'fg=15'
ble-face -s varname_readonly          'fg=#ffaf5f'
ble-face -s varname_transform         'fg=#ffaf5f'
ble-face -s varname_unset             'fg=0,bg=1'
ble-face -s vbell_erase               'bg=#626262'
