# Print an optspec for argparse to handle cmd's options that are independent of any subcommand.
function __fish_monk_global_optspecs
	string join \n h/help V/version
end

function __fish_monk_needs_command
	# Figure out if the current invocation already has a command.
	set -l cmd (commandline -opc)
	set -e cmd[1]
	argparse -s (__fish_monk_global_optspecs) -- $cmd 2>/dev/null
	or return
	if set -q argv[1]
		# Also print the command, so this can be used to figure out what it is.
		echo $argv[1]
		return 1
	end
	return 0
end

function __fish_monk_using_subcommand
	set -l cmd (__fish_monk_needs_command)
	test -z "$cmd"
	and return 1
	contains -- $cmd[1] $argv
end

complete -c monk -n "__fish_monk_needs_command" -s h -l help -d 'Print help'
complete -c monk -n "__fish_monk_needs_command" -s V -l version -d 'Print version'
complete -c monk -n "__fish_monk_needs_command" -f -a "create" -d 'Creates the weekly markdown file'
complete -c monk -n "__fish_monk_needs_command" -f -a "open" -d 'Opens current week\'s file in Vim'
complete -c monk -n "__fish_monk_needs_command" -f -a "daily" -d 'Shows tasks for daily report'
complete -c monk -n "__fish_monk_needs_command" -f -a "completion" -d 'Generates autocomplete script for supported shells'
complete -c monk -n "__fish_monk_needs_command" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c monk -n "__fish_monk_using_subcommand create" -s h -l help -d 'Print help'
complete -c monk -n "__fish_monk_using_subcommand open" -s h -l help -d 'Print help'
complete -c monk -n "__fish_monk_using_subcommand daily" -s h -l help -d 'Print help'
complete -c monk -n "__fish_monk_using_subcommand completion" -s h -l help -d 'Print help'
complete -c monk -n "__fish_monk_using_subcommand help; and not __fish_seen_subcommand_from create open daily completion help" -f -a "create" -d 'Creates the weekly markdown file'
complete -c monk -n "__fish_monk_using_subcommand help; and not __fish_seen_subcommand_from create open daily completion help" -f -a "open" -d 'Opens current week\'s file in Vim'
complete -c monk -n "__fish_monk_using_subcommand help; and not __fish_seen_subcommand_from create open daily completion help" -f -a "daily" -d 'Shows tasks for daily report'
complete -c monk -n "__fish_monk_using_subcommand help; and not __fish_seen_subcommand_from create open daily completion help" -f -a "completion" -d 'Generates autocomplete script for supported shells'
complete -c monk -n "__fish_monk_using_subcommand help; and not __fish_seen_subcommand_from create open daily completion help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
