# Starts the shell under a headless sway of its own, walks it through every
# page it has from the ipc, and fails if quickshell said anything at warning
# level or above that is not one of the few things a session with no
# hyprland, no pipewire and no system bus is expected to say.
#
#     shell-smoke          the packaged build
#     shell-smoke ./src    the working tree, through quickshell --path
#
# Nothing of the session it is started from reaches it: it gets a runtime
# directory, a home, a session bus and a compositor of its own, and no system
# bus at all, so it can be run from inside a live hyprland session — or the
# nix sandbox, where `nix flake check` runs it — without seeing or touching
# anything there. The notifications and launches it would keep go into the
# throwaway home with everything else.

# How long the shell gets to say it has loaded, and how long each page is
# left up before the next one; generous, because in the sandbox every frame
# is drawn on the processor.
load_timeout=${SMOKE_LOAD_TIMEOUT:-60}
dwell=${SMOKE_DWELL:-1}

if [ $# -gt 0 ]; then
    run=(quickshell --path "$(realpath "$1")")
else
    run=("$SMOKE_SHELL")
fi

work=$(mktemp -d "${TMPDIR:-/tmp}/shell-smoke.XXXXXX")
log=$work/shell.log
pids=()

cleanup() {
    for pid in "${pids[@]}"; do
        kill "$pid" 2>/dev/null || true
    done
    wait 2>/dev/null || true
    if [ -z "${SMOKE_KEEP:-}" ]; then
        rm -rf "$work"
    else
        echo "smoke: kept $work"
    fi
}
trap cleanup EXIT

fail() {
    echo "smoke: $*" >&2
    echo "── shell log ──" >&2
    cat "$log" >&2 || true
    echo "── sway log (tail) ──" >&2
    tail -n 20 "$work/sway.log" >&2 || true
    exit 1
}

# ── a session of its own ──────────────────────────────────────────────────

unset WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE SWAYSOCK I3SOCK \
    DBUS_SESSION_BUS_ADDRESS QS_CONFIG_PATH QS_CONFIG_NAME QS_MANIFEST

export HOME=$work/home
export XDG_RUNTIME_DIR=$work/run
export XDG_CONFIG_HOME=$HOME/.config
export XDG_STATE_HOME=$HOME/.local/state
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
mkdir -p "$XDG_CONFIG_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME"
mkdir -m 700 "$XDG_RUNTIME_DIR"

# No system bus: bluez and logind are left unreachable rather than borrowed
# from the machine, so a run outside the sandbox sees what one inside it does.
export DBUS_SYSTEM_BUS_ADDRESS=unix:path=$work/no-system-bus

# A session bus that activates nothing, so a portal or a notification daemon
# of the host's is never started on the shell's behalf.
cat > "$work/bus.conf" <<EOF
<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-Bus Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <type>session</type>
  <listen>unix:path=$work/bus</listen>
  <auth>EXTERNAL</auth>
  <policy context="default">
    <allow send_destination="*" eavesdrop="true"/>
    <allow eavesdrop="true"/>
    <allow own="*"/>
  </policy>
</busconfig>
EOF
dbus-daemon --nofork --config-file="$work/bus.conf" > "$work/bus.log" 2>&1 &
pids+=($!)
export DBUS_SESSION_BUS_ADDRESS=unix:path=$work/bus

# Two outputs, so there are two notches and two Spotlights to keep apart.
export WLR_BACKENDS=headless
export WLR_HEADLESS_OUTPUTS=2
export WLR_RENDERER=pixman
export WLR_LIBINPUT_NO_DEVICES=1
printf 'xwayland disable\n' > "$work/sway.conf"
sway --config "$work/sway.conf" > "$work/sway.log" 2>&1 &
pids+=($!)

for _ in $(seq 100); do
    socket=$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name 'wayland-*' -type s -print -quit)
    [ -n "$socket" ] && [ -S "$work/bus" ] && break
    sleep 0.1
done
[ -n "$socket" ] || fail "sway never came up"
[ -S "$work/bus" ] || fail "the session bus never came up"
WAYLAND_DISPLAY=$(basename "$socket")
export WAYLAND_DISPLAY

# ── the shell ─────────────────────────────────────────────────────────────

export QT_QPA_PLATFORM=wayland
export QT_QUICK_BACKEND=software
export NO_COLOR=1

"${run[@]}" > "$log" 2>&1 &
shell=$!
pids+=("$shell")

# Quickshell says this once shell.qml and everything it builds at startup
# have been created; a configuration that fails to load never says it, and
# one that crashes on the way is no longer there to.
loaded=
for _ in $(seq $((load_timeout * 10))); do
    kill -0 "$shell" 2>/dev/null || fail "the shell exited before it loaded"
    if grep -q 'Configuration Loaded' "$log"; then
        loaded=1
        break
    fi
    sleep 0.1
done
[ -n "$loaded" ] || fail "the shell did not load within ${load_timeout}s"

# Every page is built the first time it is opened, so each is opened once,
# along with Spotlight and the pill, for whatever it builds to be built.
steps=(
    "notch toggle"
    "notch open audio"
    "notch open notifications"
    "notch open bluetooth"
    "notch open network"
    "notch open resources"
    "notch open home"
    "notch close"
    "notch peek"
    "spotlight search a"
    "spotlight search 2^10"
    "spotlight clipboard"
    "spotlight toggle"
    "launcher toggle"
    "launcher toggle"
)

# None of the calls returns anything, so a call that answers at all is
# quickshell saying it could not make it — "Target not found.", "Function
# not found." — which it does without failing.
for step in "${steps[@]}"; do
    sleep "$dwell"
    kill -0 "$shell" 2>/dev/null || fail "the shell exited before: ipc call $step"
    # shellcheck disable=SC2086 # a step is the words of the call
    answer=$(quickshell ipc --pid "$shell" call $step 2>&1) ||
        fail "ipc call $step failed: $answer"
    [ -z "$answer" ] || fail "ipc call $step: $answer"
done
sleep "$dwell"
kill -0 "$shell" 2>/dev/null || fail "the shell exited after the last step"

kill "$shell"
wait "$shell" 2>/dev/null || true

# ── what it said ──────────────────────────────────────────────────────────

# What a session with nothing behind it says however well the shell is
# written, each matched in full so nothing else can hide behind it. None of
# them names a file of the shell's own: anything that does is never noise.
expected=(
    # no pipewire in the runtime directory
    '^ *ERROR quickshell\.service\.pipewire\.loop: Failed to connect pipewire context\. Errno: [0-9]+$'
    # no hyprland, so no workspaces and no focused monitor
    '^ *WARN: [$]HYPRLAND_INSTANCE_SIGNATURE is unset\. Cannot connect to hyprland\.$'
    # nor any windows for Spotlight to ask it for
    '^ *WARN quickshell\.hyprland\.ipc: Error making request: QLocalSocket::ServerNotFoundError request: "j/clients"$'
    # no login session for the polkit agent to answer for, and no polkit
    # to register it with
    '^ *WARN quickshell\.service\.polkit\.listener: failed to (create subject for|register) listener: .+$'
    '^ *WARN quickshell\.service\.polkit: failed to register listener on path "/org/quickshell/PolkitAgent"$'
    # no system bus, so no bluez
    '^ *WARN quickshell\.bluetooth: Could not connect to DBus\. Bluetooth integration is not available\.$'
    # a session bus with no portal on it for qt to register with
    '^ *WARN qt\.qpa\.services: Failed to register with host portal QDBusError\("org\.freedesktop\.DBus\.Error\.ServiceUnknown", "The name org\.freedesktop\.portal\.Desktop was not provided by any \.service files"\)$'
)

warnings=$(grep -E '^ *(WARN|ERROR|CRIT|FATAL)' "$log" || true)
unexpected=$(printf '%s\n' "$warnings" | grep -v -E "$(
    IFS='|'
    echo "${expected[*]}"
)" | grep -v '^$' || true)
own=$(printf '%s\n' "$warnings" | grep -E '\.qml([^a-z]|$)' || true)

if [ -n "$unexpected" ] || [ -n "$own" ]; then
    echo "smoke: the shell loaded, but said:" >&2
    printf '%s\n' "$unexpected" "$own" | grep -v '^$' | sort -u >&2
    fail "warnings in the log"
fi

echo "smoke: the shell loaded and took ${#steps[@]} ipc calls without a warning of its own"
if [ -n "$warnings" ]; then
    echo "smoke: expected in a session with nothing behind it:"
    printf '%s\n' "$warnings" | sed 's/^/  /'
fi
