# Clean filter for */.claude/settings.json (filter=claude-session).
# Keeps on disk, and out of git:
#   - the model and effort Claude Code records from a session;
#   - the telemetry ProductFactory points at itself, bearer token included;
#   - the Orca agent hooks the ProductFactory ADE installs.
# The runner rewrites these on every start, so git is where they are held back.
def pf_telemetry:
  [
    "CLAUDE_CODE_ENABLE_TELEMETRY",
    "OTEL_EXPORTER_OTLP_ENDPOINT", "OTEL_EXPORTER_OTLP_HEADERS", "OTEL_EXPORTER_OTLP_PROTOCOL",
    "OTEL_LOGS_EXPORTER", "OTEL_LOG_TOOL_DETAILS", "OTEL_METRICS_EXPORTER",
    "OTEL_METRICS_INCLUDE_REPOSITORY", "OTEL_METRICS_INCLUDE_VERSION"
  ];

def pf_hook: (.command // "") | test("ORCA_AGENT_HOOK|\\.productfactory/agent-hooks");

del(.model, .effortLevel, .modelSettings)
| if (.env.OTEL_EXPORTER_OTLP_ENDPOINT // "" | test("productfactory")) then
    .env |= with_entries(select(.key as $k | pf_telemetry | index($k) | not))
  else . end
| if .hooks then
    .hooks |= with_entries(
      .value |= (map(.hooks |= map(select(pf_hook | not))) | map(select(.hooks | length > 0)))
      | select(.value | length > 0))
  else . end
