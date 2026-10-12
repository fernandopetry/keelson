#!/usr/bin/env bash
# subagent-window-marker — hook SubagentStop que delega ao window-marker (decisão
# 4.474). Existe porque cada script do manifesto hooks/hooks.json entra uma vez só;
# o medidor é o mesmo, e lê `hook_event_name` do payload para agir no modo certo.
# Fallback gracioso: medidor ausente → exit 0. Bash 3.2-compatível.
set -u
WM="$(cd "$(dirname "$0")" 2>/dev/null && pwd)/window-marker.sh"
[ -f "$WM" ] || exit 0
exec bash "$WM"
