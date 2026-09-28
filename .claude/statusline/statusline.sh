#!/usr/bin/env bash
# Claude Code status line (statusLine in ~/.claude/settings.json).
# Reads the session JSON on stdin and prints one line:
#   model ·effort │ dir branch* │ k8s │ context bar │ cost · duration │ 7d limit

input=$(cat)
# printf/awk must use a dot as the decimal separator regardless of the system locale.
export LC_NUMERIC=C

eval "$(jq -r '
  @sh "model=\(.model.display_name // .model.id // "?")",
  @sh "effort=\(.effort.level // "")",
  @sh "fast=\(.fast_mode // false)",
  @sh "dir=\(.workspace.current_dir // .cwd // "")",
  @sh "project=\(.workspace.project_dir // "")",
  @sh "ctx_pct=\(.context_window.used_percentage // 0)",
  @sh "ctx_size=\(.context_window.context_window_size // 0)",
  @sh "ctx_used=\((.context_window.current_usage // {}) | [.input_tokens, .cache_creation_input_tokens, .cache_read_input_tokens] | map(. // 0) | add)",
  @sh "cost=\(.cost.total_cost_usd // 0)",
  @sh "dur_ms=\(.cost.total_duration_ms // 0)",
  @sh "week_pct=\(.rate_limits.seven_day.used_percentage // "")",
  @sh "five_pct=\(.rate_limits.five_hour.used_percentage // "")"
' <<<"$input")"

# Palette (256 colors), tuned for a dark background.
e=$'\e'
reset="${e}[0m"
dim="${e}[38;5;244m"
c_model="${e}[38;5;175m"
c_dir="${e}[38;5;110m"
c_git="${e}[38;5;144m"
c_dirty="${e}[38;5;179m"
c_k8s="${e}[38;5;74m"
c_ok="${e}[38;5;108m"
c_warn="${e}[38;5;179m"
c_bad="${e}[38;5;167m"
sep=" ${dim}│${reset} "

# Green below 50%, yellow below 80%, red above.
level_color() {
  if (( $1 >= 80 )); then printf '%s' "$c_bad"
  elif (( $1 >= 50 )); then printf '%s' "$c_warn"
  else printf '%s' "$c_ok"
  fi
}

human_tokens() {
  local n=$1
  if (( n >= 1000000 )); then
    awk -v n="$n" 'BEGIN { v = n / 1000000; printf (v == int(v) ? "%dM" : "%.1fM"), v }'
  elif (( n >= 1000 )); then printf '%dk' $(( n / 1000 ))
  else printf '%d' "$n"
  fi
}

human_duration() {
  local s=$(( $1 / 1000 ))
  if (( s >= 86400 )); then printf '%dd%02dh' $(( s / 86400 )) $(( s % 86400 / 3600 ))
  elif (( s >= 3600 )); then printf '%dh%02dm' $(( s / 3600 )) $(( s % 3600 / 60 ))
  elif (( s >= 60 )); then printf '%dm' $(( s / 60 ))
  else printf '%ds' "$s"
  fi
}

segments=()

# Model: "Opus 5 (1M context)" -> "Opus 5 1M", plus effort and fast mode.
model=$(sed -E 's/ \(([0-9.]+[KM]) context\)/ \1/' <<<"$model")
seg="${c_model}󰚩 ${model}${reset}"
[[ -n $effort ]] && seg+="${dim} ·${effort}${reset}"
[[ $fast == true ]] && seg+=" ${c_warn}⚡${reset}"
segments+=("$seg")

# Directory: basename, or project/sub when inside the project; deeper paths
# collapse to project/…/basename.
if [[ -n $dir ]]; then
  if [[ -n $project && $dir == "$project"/* ]]; then
    rel=${dir#"$project"/}
    name=${project##*/}
    [[ $project == "$HOME" ]] && name="~"
    if [[ $rel == */* ]]; then
      where="${name}/…/${dir##*/}"
    else
      where="${name}/${rel}"
    fi
  else
    where="${dir##*/}"
  fi
  [[ $dir == "$HOME" ]] && where="~"
  seg="${c_dir} ${where}${reset}"

  branch=$(git -C "$dir" --no-optional-locks symbolic-ref --short -q HEAD 2>/dev/null \
    || git -C "$dir" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  if [[ -n $branch ]]; then
    seg+=" ${c_git} ${branch}${reset}"
    if [[ -n $(git -C "$dir" --no-optional-locks status --porcelain 2>/dev/null | head -n1) ]]; then
      seg+="${c_dirty}*${reset}"
    fi
  fi
  segments+=("$seg")
fi

# Kubernetes context: a project-local kubeconfig (like the lab's .kube/config)
# wins over $KUBECONFIG and ~/.kube/config. Parsed directly, no kubectl call.
kubeconfig=""
for candidate in "${project:+$project/.kube/config}" "${dir:+$dir/.kube/config}" "${KUBECONFIG%%:*}" "$HOME/.kube/config"; do
  [[ -n $candidate && -f $candidate ]] && { kubeconfig=$candidate; break; }
done
if [[ -n $kubeconfig ]]; then
  kctx=$(awk -F': *' '/^current-context:/ { gsub(/["'\'']/, "", $2); print $2; exit }' "$kubeconfig")
  [[ -n $kctx ]] && segments+=("${c_k8s}󱃾 ${kctx}${reset}")
fi

# Context window: 10-cell bar, percentage and used/total tokens.
ctx_pct=${ctx_pct%.*}
filled=$(( (ctx_pct + 5) / 10 ))
(( filled > 10 )) && filled=10
bar=""
for (( i = 0; i < 10; i++ )); do
  (( i < filled )) && bar+="▰" || bar+="▱"
done
color=$(level_color "$ctx_pct")
seg="${color}${bar} ${ctx_pct}%${reset}"
if (( ctx_size > 0 )); then
  (( ctx_used == 0 )) && ctx_used=$(( ctx_size * ctx_pct / 100 ))
  seg+=" ${dim}$(human_tokens "$ctx_used")/$(human_tokens "$ctx_size")${reset}"
fi
segments+=("$seg")

# Session cost and wall-clock duration.
segments+=("${dim}\$$(printf '%.2f' "$cost") · $(human_duration "$dur_ms")${reset}")

# Plan usage limits, when the payload carries them.
limits=""
if [[ -n $five_pct ]]; then
  five_pct=${five_pct%.*}
  limits+="$(level_color "$five_pct")5h ${five_pct}%${reset}"
fi
if [[ -n $week_pct ]]; then
  week_pct=${week_pct%.*}
  [[ -n $limits ]] && limits+=" "
  limits+="$(level_color "$week_pct")7d ${week_pct}%${reset}"
fi
[[ -n $limits ]] && segments+=("$limits")

out=""
for s in "${segments[@]}"; do
  [[ -n $out ]] && out+="$sep"
  out+="$s"
done
printf '%s\n' "$out"
