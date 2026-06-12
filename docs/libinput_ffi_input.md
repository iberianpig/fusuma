# libinput FFI input (experimental)

`libinput_ffi_input` is an experimental input plugin that talks to
`libinput.so` directly via Fiddle (FFI) instead of spawning the
`libinput debug-events` subprocess. It removes the runtime dependency on
the libinput CLI (libinput-tools), discovers devices through the udev
backend (hotplug included), and skips text parsing entirely.

## Enabling

Disabled by default. Switch the inputs and re-point the parser source in
`~/.config/fusuma/config.yml`:

```yaml
plugin:
  inputs:
    libinput_command_input:
      enabled: false
    libinput_ffi_input:
      enabled: true
      # --- optional parameters (CLI option equivalents) ---
      enable-tap: true            # libinput tap-to-click
      enable-dwt: true            # disable-while-typing on
      disable-dwt: false          # disable-while-typing off
      device: "Magic Touchpad"    # mute gesture devices whose name doesn't match
      touch-events: true          # emit TouchRecord from touchscreens (default: true)
      pointer-events: false       # emit PointerRecord motion/button/scroll (default: false)
  parsers:
    libinput_gesture_parser:
      source: libinput_ffi_input
```

Requirements:

- `libinput.so.10` (or `libinput.so`) and `libudev.so.1` present —
  the *library* package, not libinput-tools
- read access to `/dev/input/event*` (typically the `input` group)
- Ruby 3.5+: `fiddle` is no longer a default gem; `gem install fiddle`

## How to verify it works

### 1. Unit + integration specs (local)

```console
$ bundle exec rspec
```

Unit specs stub the FFI layer and run anywhere. The integration specs
(`spec/fusuma/libinput/integration_spec.rb`) create virtual devices via
`/dev/uinput` and drive real libinput end-to-end (swipe/pinch/hold on a
virtual touchpad, TOUCH events on a virtual touchscreen, and the full
plugin pipe over the udev backend). They self-skip unless:

- `/dev/uinput` is writable (e.g. your user is in the `uinput`/`input`
  group, or `sudo chmod 666 /dev/uinput` after `sudo modprobe uinput`)
- `libinput.so` is loadable

### 2. Docker

`Dockerfile.integration` reproduces the integration environment on any
machine with Docker (see the header comment in that file for details on
why each flag is needed — uinput devices live in the host kernel and
libinput classifies devices via the host udev daemon's database):

```console
$ docker build -f Dockerfile.integration -t fusuma-ffi-test .
$ docker run --rm \
    --device /dev/uinput \
    --device-cgroup-rule='c 13:* rmw' \
    -v /dev/input:/dev/input \
    -v /run/udev:/run/udev:ro \
    fusuma-ffi-test                          # integration specs only
$ docker run --rm ... fusuma-ffi-test bundle exec rspec   # full suite
```

### 3. CI

The `integration` job in `.github/workflows/main.yml` runs the
integration specs on the runner VM (modprobe uinput + udev rule). The
regular `build` matrix runs the rest of the suite without libinput
installed, which also verifies fusuma still boots without the library.

### 4. On a real machine

Enable the plugin as above, then run fusuma verbosely and perform a
3-finger swipe on the touchpad:

```console
$ bundle exec exe/fusuma -v
```

You should see:

- `Fusuma::Plugin::Events::Event` debug lines with
  `tag: libinput_ffi_input` and `GestureRecord` payloads
  (`swipe, Finger: 3, Status: update`) instead of raw libinput text
- no `libinput debug-events` child process
  (`pgrep -af libinput` shows nothing while fusuma is running)
- your configured gestures still trigger their commands

To verify device discovery without the CLI, `fusuma -l` lists devices;
with the FFI input enabled it enumerates them via FFI instead of
`libinput list-devices`.

## Event records

The FFI input emits pre-parsed Ruby records over an internal pipe
(length-prefixed `Marshal`), not text lines:

| libinput event              | Record                                    | default |
|-----------------------------|-------------------------------------------|---------|
| `GESTURE_SWIPE/PINCH/HOLD_*`| `Events::Records::GestureRecord`          | on      |
| `TOUCH_*` (touchscreens)    | `Events::Records::TouchRecord`            | on (`touch-events`) |
| `POINTER_MOTION/BUTTON/SCROLL_*` | `Events::Records::PointerRecord`     | off (`pointer-events`) |

`LibinputGestureParser` passes `GestureRecord` through unchanged, so the
standard gesture pipeline works once `source:` points at this plugin.
`TouchRecord`/`PointerRecord` events keep the `libinput_ffi_input` tag;
they are intended for plugins that consume them directly.

## Known limitations

- **External plugins that parse libinput's text output do not work with
  this input.** Plugins like fusuma-plugin-touchscreen read raw
  `libinput debug-events` lines from `libinput_command_input`; with the
  FFI input they need to be ported to consume `TouchRecord` /
  `PointerRecord` instead. Until then, keep using
  `libinput_command_input` with those plugins.
- `libinput_device_filter` (keep_device) does not apply to this input.
  Use the `device:` parameter above instead.
- If the FFI event thread dies unexpectedly, fusuma exits (the reader
  sees EOF, mirroring the CLI input's behavior when its subprocess
  dies). Run fusuma under a supervisor with restart (e.g. the systemd
  user service from the README) for automatic recovery.
- The gem does not declare a dependency on `fiddle` while this plugin is
  experimental; on Ruby 3.5+ install it manually.
