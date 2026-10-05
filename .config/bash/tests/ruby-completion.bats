#!/usr/bin/env bats

setup_file() {
  export RUBY_COMPLETION_PROJECT_A="$BATS_FILE_TMPDIR/project one"
  export RUBY_COMPLETION_PROJECT_B="$BATS_FILE_TMPDIR/project two"
  mkdir -p "$RUBY_COMPLETION_PROJECT_A/spec" "$RUBY_COMPLETION_PROJECT_B"
  cat >"$RUBY_COMPLETION_PROJECT_A/Rakefile" <<'RUBY'
task :alpha_only
namespace :check do
  task :unit do
    raise "Completion must not execute tasks"
  end
end
RUBY
  printf '%s\n' 'task :beta_only' >"$RUBY_COMPLETION_PROJECT_B/Rakefile"
  printf '%s\n' 'task :alternate_only' >"$RUBY_COMPLETION_PROJECT_A/custom tasks.rake"
  printf '%s\n' 'source "https://rubygems.org"' 'gem "rake"' >"$RUBY_COMPLETION_PROJECT_A/Gemfile"
  touch "$RUBY_COMPLETION_PROJECT_A/spec/a spec.rb"
  (cd "$RUBY_COMPLETION_PROJECT_A" && BUNDLE_LOCKFILE_CHECKSUMS=false bundle lock --local >/dev/null)
}

setup() {
  source /usr/share/bash-completion/bash_completion
  source "$BATS_TEST_DIRNAME/../ruby-completion"
  cd "$RUBY_COMPLETION_PROJECT_A" || return
}

probe() {
  COMP_WORDS=("$@")
  COMP_CWORD=$((${#COMP_WORDS[@]} - 1))
  COMP_LINE="${COMP_WORDS[*]}"
  COMP_POINT=${#COMP_LINE}
  COMPREPLY=()
  local result=0
  _ruby_complete "${COMP_WORDS[0]}" "${COMP_WORDS[-1]}" "${COMP_WORDS[-2]}" || result=$?
  return "$result"
}

has_candidate() {
  local candidate
  for candidate in "${COMPREPLY[@]}"; do
    [[ $candidate == "$1" ]] && return 0
  done
  printf 'Missing candidate %s in %s\n' "$1" "${COMPREPLY[*]}" >&2
  return 1
}

@test "ri, riv and rich-ri complete classes and instance methods" {
  probe ri Str
  has_candidate String
  probe ri 'String#sca'
  has_candidate 'String#scan'
  probe riv 'String#sca'
  has_candidate 'String#scan'
  probe rich-ri 'String#sca'
  has_candidate 'String#scan'
  probe rich-ri --no-color 'String#sca'
  has_candidate 'String#scan'
  probe ri "'String#sca"
  has_candidate 'String#scan'
}

@test "rich-ri completes color options and stock formats" {
  probe rich-ri --color=al
  has_candidate always
  probe rich-ri --format=mar
  has_candidate markdown
  probe rich-ri --no-c
  has_candidate --no-color
}

@test "rich-ri discovers method kinds, Ruby pages and gem pages" {
  probe rich-ri String
  has_candidate 'String#'
  has_candidate 'String.'
  has_candidate 'String::'
  probe rich-ri 'String.ne'
  has_candidate 'String.new'
  probe rich-ri rub
  has_candidate 'ruby:'
  probe rich-ri 'ruby:syntax/pat'
  has_candidate 'syntax/pattern_matching.rdoc'
  probe rich-ri --color=always 'rdoc:READ'
  has_candidate 'README.md'
}

@test "rich-ri completion loads the packaged handler on demand" {
  complete -r rich-ri 2>/dev/null || :
  unset -f _rich_ri
  _comp_load rich-ri
  [[ $(complete -p rich-ri) == *'-o filenames -F _rich_ri rich-ri' ]]
  probe rich-ri 'Hash#fet'
  has_candidate 'Hash#fetch'
}

@test "ri alias keeps rich-ri options and page discovery" {
  alias ri=rich-ri
  probe ri --no-c
  has_candidate --no-color
  probe ri --color=al
  has_candidate always
  probe ri 'ruby:syntax/pat'
  has_candidate 'syntax/pattern_matching.rdoc'
  probe ri 'String#sca'
  has_candidate 'String#scan'
}

@test "ri and riv lazily discover rich-ri themes and style roles" {
  alias ri=rich-ri
  unset -f _rich_ri
  probe ri --theme=da
  has_candidate dark
  declare -F _rich_ri >/dev/null
  probe ri --style=met
  has_candidate 'method='
  probe riv --theme li
  has_candidate light
  probe riv --style comm
  has_candidate 'comment='
}

@test "rich-ri and its aliases preserve quoted paths and the completion context" {
  local settings="$BATS_TEST_TMPDIR/settings spaced.yml"
  local docs="$BATS_TEST_TMPDIR/docs spaced"
  printf '%s\n' 'theme: terminal' >"$settings"
  mkdir -p "$docs"
  alias ri=rich-ri

  probe rich-ri --config "'$BATS_TEST_TMPDIR/settings s"
  has_candidate "$settings"
  probe ri --doc-dir "'$BATS_TEST_TMPDIR/docs s"
  has_candidate "$docs/"
  [ "${COMP_WORDS[0]}" = ri ]
  [ "$COMP_CWORD" -eq 2 ]
  [ "$COMP_LINE" = "ri --doc-dir '$BATS_TEST_TMPDIR/docs s" ]
  probe riv "'String#sca"
  has_candidate 'String#scan'
}

@test "ri completes namespaced constants and current RDoc formats" {
  probe ri 'Process::Sta'
  has_candidate Status
  probe ri --format=mar
  has_candidate markdown
}

@test "RubyGems completes commands, negative flags and installed gems" {
  probe gem ins
  has_candidate install
  probe gem install --no-d
  has_candidate --no-document
  probe gem uninstall rdo
  has_candidate rdoc
}

@test "Bundler completes commands and project dependencies" {
  probe bundle ins
  has_candidate install
  probe bundler open ra
  has_candidate rake
  probe bundle install --loc
  has_candidate --local
  probe bundle config set wi
  has_candidate without
}

@test "bundle exec delegates completion to the wrapped tool" {
  probe bundle exec ruby --vers
  has_candidate --version
  probe bundle exec rake check:
  has_candidate unit
}

@test "bundle exec preserves the original completion context" {
  probe bundle exec ruby --vers
  [ "$COMP_LINE" = 'bundle exec ruby --vers' ]
  [ "$COMP_CWORD" -eq 3 ]
  [ "${COMP_WORDS[0]}" = bundle ]
}

@test "rake lists tasks without executing them or writing a project cache" {
  probe rake check:
  has_candidate unit
  [ ! -e .rake_tasks~ ]
}

@test "rake completion follows project changes in the same shell" {
  probe rake alpha
  has_candidate alpha_only
  cd "$RUBY_COMPLETION_PROJECT_B"
  probe rake beta
  has_candidate beta_only
  probe rake alpha
  [ "${#COMPREPLY[@]}" -eq 0 ]
}

@test "rake respects an explicitly selected file with spaces" {
  probe rake --rakefile 'custom tasks.rake' alt
  has_candidate alternate_only
}

@test "Ruby completes flags and require paths" {
  probe ruby --vers
  has_candidate --version
  probe ruby -r json/pa
  [ "${#COMPREPLY[@]}" -eq 0 ]
  probe ruby -r json/ver
  has_candidate json/version
}

@test "Ruby short flags omit help placeholders and include aliases" {
  probe ruby -I
  [ "${COMPREPLY[*]}" = '-I' ]
  probe ruby -d
  has_candidate -d
  probe ruby -o
  [ "${#COMPREPLY[@]}" -eq 0 ]
}

@test "Ruby completes attached require and load path arguments" {
  probe ruby -rjson/ver
  has_candidate -rjson/version
  probe ruby -Isp
  has_candidate -Ispec
}

@test "RuboCop and Standard complete flags and formatter values" {
  probe rubocop --autocorrect
  has_candidate --autocorrect
  probe standardrb --fi
  has_candidate --fix
  probe rubocop --format=js
  has_candidate json
}

@test "rdbg completes flags and commands in command mode" {
  probe rdbg --non
  has_candidate --nonstop
  probe rdbg -c -- ruby --vers
  has_candidate --version
}

@test "Ruby executable search delegates completion" {
  probe ruby -S rake check:
  has_candidate unit
}

@test "file completion preserves spaces" {
  probe rspec spec/a
  has_candidate 'spec/a spec.rb'
}

@test "gems completes options without suggesting files as search terms or page numbers" {
  probe gems --pa
  has_candidate --page
  probe gems --page 2
  [ "${#COMPREPLY[@]}" -eq 0 ]
  probe gems html
  [ "${#COMPREPLY[@]}" -eq 0 ]
}

@test "IRB, RDoc, ERB, Ruby LSP and try have completions" {
  probe irb --noauto
  has_candidate --noautocomplete
  probe rdoc --mar
  has_candidate --markup=
  probe erb --ver
  has_candidate --version
  probe ruby-lsp --deb
  has_candidate --debug
  probe try clo
  has_candidate clone
}

@test "an unavailable bundle leaves completion empty without creating a lockfile" {
  export BUNDLE_GEMFILE="$BATS_TEST_TMPDIR/missing/Gemfile"
  probe bundle open ra
  [ "${#COMPREPLY[@]}" -eq 0 ]
  [ ! -e "$BUNDLE_GEMFILE.lock" ]
}
