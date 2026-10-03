mode = ARGV.shift

values = case mode
when "ri"
  require "rdoc/ri/driver"
  prefix = ARGV.pop || ""
  ENV.delete("RI")
  options = RDoc::RI::Driver.process_args(ARGV)
  RDoc::RI::Driver.new(options.merge(use_stdout: true, interactive: false)).complete(prefix)
when "ri-formats"
  require "rdoc/ri/driver"
  RDoc::Markup.constants.grep(/^To[A-Z][a-z]+$/).map { |name| name.to_s.delete_prefix("To").downcase } - %w[html label test]
when "gem-commands"
  require "rubygems/command_manager"
  Gem::CommandManager.instance.command_names
when "gem-names"
  Gem::Specification.map(&:name)
when "bundle-commands"
  require "bundler"
  require "bundler/cli"
  cli = ARGV.empty? ? Bundler::CLI : Bundler::CLI.subcommand_classes.fetch(ARGV.first)
  cli.all_commands.reject { |_, command| command.hidden? }.keys
when "bundle-gems"
  require "bundler"
  Bundler::LockfileParser.new(Bundler.read_file(Bundler.default_lockfile)).specs.map(&:name)
when "bundle-settings"
  require "bundler"
  %i[BOOL_KEYS NUMBER_KEYS ARRAY_KEYS STRING_KEYS].flat_map { |name| Bundler::Settings.const_get(name) }
when "encodings"
  Encoding.name_list
when "requires"
  prefix = ARGV.first || ""
  paths = $LOAD_PATH + Gem::Specification.flat_map(&:full_require_paths)
  paths.uniq.flat_map do |path|
    Dir.glob("**/*.{rb,so,bundle}", base: path).filter_map do |file|
      name = file.sub(/\.(rb|so|bundle)\z/, "")
      name if name.start_with?(prefix)
    end
  end
else
  []
end

puts values.uniq.sort
