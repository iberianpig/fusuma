# Fusuma [![Gem Version](https://badge.fury.io/rb/fusuma.svg)](https://badge.fury.io/rb/fusuma) [![Build Status](https://travis-ci.com/iberianpig/fusuma.svg?branch=master)](https://travis-ci.com/iberianpig/fusuma) [![Coverage Status](https://coveralls.io/repos/github/iberianpig/fusuma/badge.svg?branch=master)](https://coveralls.io/github/iberianpig/fusuma?branch=master) [![Inline docs](http://inch-ci.org/github/iberianpig/fusuma.svg?branch=master)](http://inch-ci.org/github/iberianpig/fusuma)

Fusuma is multitouch gesture recognizer.
This gem makes your linux able to recognize swipes or pinchs and assign commands to them.

![fusuma_image](https://repository-images.githubusercontent.com/69813387/60879a00-166c-11ea-9875-3bf0818c62ec)

襖(Fusuma) means sliding door used to partition off rooms in a Japanese house.

## Features

- Easy installation with RubyGems
- Defining Gestures and Actions in YAML
- Sensitivity setting (threshold, interval) for gesture recognition
- Automatic device addition for reconnecting external touchpads
- Extension of gesture recognition by [plugin system](https://github.com/iberianpig/fusuma/#fusuma-plugins)

## Installation

### Grant permission to read the touchpad device

**IMPORTANT**: You **MUST** be a member of the **INPUT** group to read touchpad by Fusuma.

```bash
$ sudo gpasswd -a $USER input
```

Then, You apply the change with no logout or reboot.

```bash
$ newgrp input
```

### For Debian Based Distros (Ubuntu, Debian, Mint, Pop!OS)

#### 1. Install libinput-tools

You need `libinput` release 1.0 or later.

```bash
$ sudo apt-get install libinput-tools
```

#### 2. Install Ruby

Fusuma runs in Ruby, so you must install it first.

```bash
$ sudo apt-get install ruby
```

#### 3. Install Fusuma

```bash
$ sudo gem install fusuma
```

#### 4. Install xdotool (optional)

For sending shortcuts:

```bash
$ sudo apt-get install xdotool
```

### For Arch Based Distros (Manjaro, Arch)

#### 1. Install libinput.

You need `libinput` release 1.0 or later. This is most probably installed by default on Manjaro

```z-h
$ sudo pacman -S libinput
```

#### 2. Install Ruby

Fusuma runs in Ruby, so you must install it first.

```zsh
$ sudo pacman -S ruby
```

#### 3. Install Fusuma

**Note:** By default in Arch Linux, when running `gem`, gems are installed per-user (into `~/.gem/ruby/`), instead of system-wide (into `/usr/lib/ruby/gems/`). This is considered the best way to manage gems on Arch, because otherwise they might interfere with gems installed by Pacman. (From Arch Wiki)

To install gems system-wide, see any of the methods listed on [Arch Wiki](https://wiki.archlinux.org/index.php/ruby#Installing_gems_system-wide)

```zsh
$ sudo gem install fusuma
```

#### 4. Install xdotool (optional)

For sending shortcuts:

```zsh
$ sudo pacman -S xdotool
```

### Touchpad not working in GNOME

Ensure the touchpad events are being sent to the GNOME desktop by running the following command:

```bash
$ gsettings set org.gnome.desktop.peripherals.touchpad send-events enabled
```

## Usage

```bash
$ fusuma
```

## Update

```bash
$ sudo gem update fusuma
```

## Customize Gesture Mapping

You can customize the settings for gestures to put and edit `~/.config/fusuma/config.yml`.
**NOTE: You will need to create the `~/.config/fusuma` directory if it doesn't exist yet.**

```bash
$ mkdir -p ~/.config/fusuma        # create config directory
$ nano ~/.config/fusuma/config.yml # edit config file.
```


### Available gestures

* `swipe:`
  * support `3:`, `4:` fingers
  * support `left:`, `right:`, `up:`, `down:` directions
  * support `begin:`, `update:`, `end:` events
* `pinch:`
  * support `2:`, `3:`, `4:` fingers
  * support `in:`, `out:` directions
  * support `begin:`, `update:`, `end:` events
* `rotate:`
  * support `2:`, `3:`, `4:` fingers
  * support `clockwise:`,`counterclockwise:` directions
  * support `begin:`, `update:`, `end:` events

### About YAML Basic Syntax

- Comments in YAML begins with the `#` character.
- Comments must be separated from other tokens by whitespaces.
- Indentation of whitespace is used to denote structure.
- Tabs are not included as indentation for YAML files.

### Example: Gesture Mapping for Ubuntu

https://github.com/iberianpig/fusuma/wiki/Ubuntu

```yaml
swipe:
  3:
    left:
      command: "xdotool key alt+Right" # History forward
    right:
      command: "xdotool key alt+Left" # History back
    up:
      command: "xdotool key super" # Activity
    down:
      command: "xdotool key super" # Activity
  4:
    left:
      command: "xdotool key ctrl+alt+Down" # Switch to next workspace
    right:
      command: "xdotool key ctrl+alt+Up" # Switch to previous workspace
    up:
      command: "xdotool key ctrl+alt+Down" # Switch to next workspace
    down:
      command: "xdotool key ctrl+alt+Up" # Switch to previous workspace
pinch:
  in:
    command: "xdotool keydown ctrl click 4 keyup ctrl" # Zoom in
  out:
    command: "xdotool keydown ctrl click 5 keyup ctrl" # Zoom out
```

### More Example of config.yml

The following wiki pages can be edited by everyone.

- [Ubuntu](https://github.com/iberianpig/fusuma/wiki/Ubuntu)
- [elementary OS](https://github.com/iberianpig/fusuma/wiki/elementary-OS)
- [i3](https://github.com/iberianpig/fusuma/wiki/i3)
- [KDE to mimic MacOS](https://github.com/iberianpig/fusuma/wiki/KDE-to-mimic-MacOS)
- [POP OS with Cinnamon](https://github.com/iberianpig/fusuma/wiki/POP-OS-with-Cinnamon)
- [PopOS Default Gnome](https://github.com/iberianpig/fusuma/wiki/PopOS-Default-Gnome)
- [Ubuntu OS to mimic Mac a little](https://github.com/iberianpig/fusuma/wiki/Ubuntu-OS-to-mimic-Mac-a-little)
- [3 fingers Drag (OS X Style)](https://github.com/iberianpig/fusuma/wiki/3-fingers-Drag-(OS-X-Style))
- [3 fingers Alt Tab Switcher(Windows Style)](https://github.com/iberianpig/fusuma/wiki/3-fingers-Alt-Tab-Switcher(Windows-Style))

If you have a nice configuration, please share `~/.config/fusuma/config.yml` with everyone.

### Threshold and Interval

if `command:` properties are blank, the swipe/pinch doesn't execute command.

`threshold:` is sensitivity to swipe/pinch. Default value is 1.
If the swipe's threshold is `0.5`, shorten swipe-length by half.

`interval:` is delay between swipes/pinches. Default value is 1.
If the swipe's interval is `0.5`, shorten swipe-interval by half to recognize a next swipe.

### Example of `threshold:` / `interval:` settings

```yaml
swipe:
  3:
    left:
      command: 'xdotool key alt+Right' # threshold: 0.5, interval: 0.75
      threshold: 0.5
    right:
      command: 'xdotool key alt+Left' # threshold: 0.5, interval: 0.75
      threshold: 0.5
    up:
      command: 'xdotool key super' # threshold: 1, interval: 0.75
    down:
      command: 'xdotool key super' # threshold: 1, interval: 0.75
pinch:
  2:
    in:
      command: "xdotool keydown ctrl click 4 keyup ctrl" # threshold: 0.5, interval: 0.5
    out:
      command: "xdotool keydown ctrl click 5 keyup ctrl" # threshold: 0.5, interval: 0.5

threshold:
  pinch: 0.5

interval:
  swipe: 0.75
  pinch: 0.5
```

There are three priorities of `threshold:` and `interval:`.
The individual `threshold:` and `interval:` settings (under "direction") have a higher priority than the global one (under "root")

1. child elements in the direction (left/right/down/up → threshold/interval)
1. root child elements (threshold/interval → swipe/pinch)
1. default value (= 1)

### `command:` property for assigning commands

On fusuma version 0.4 `command:` property is available!
You can assign any command each gestures.

**`shortcut:` property is deprecated**, **it was removed on fusuma version 1.0**.
You need to replace to `command:` property.

```diff
swipe:
  3:
    left:
-      shortcut: 'alt+Left'
+      command: 'xdotool key alt+Left'
    right:
-      shortcut: 'alt+Right'
+      command: 'xdotool key alt+Right'
```

### About xdotool

- xdotool manual (https://github.com/jordansissel/xdotool/blob/master/xdotool.pod)
- Available keys' hint (https://github.com/jordansissel/xdotool/issues/212#issuecomment-406156157)

**NOTE: xdotool has some issues**

- Gestures take a few seconds to react(https://github.com/iberianpig/fusuma/issues/113)

#### Alternatives to xdotool

- [fusuma-plugin-sendkey](https://github.com/iberianpig/fusuma-plugin-sendkey)

  - Emulates keyboard events
  - Low latency
  - Wayland compatible

- `xte`
  - [xte(1) - Linux man page](https://linux.die.net/man/1/xte)
  - install with `sudo apt xautomation`

- [ydotool](https://github.com/ReimuNotMoe/ydotool)
  - Wayland compatible
  - Needs more maintainers.
  - Requires only replacing `xdotool` with `ydotool` in fusuma conf.

## Options

- `-c`, `--config=path/to/file` : Use an alternative config file
- `-d`, `--daemon` : Daemonize process
- `-l`, `--list-devices` : List available devices
- `-v`, `--verbose` : Show details about the results of running fusuma
- `--version` : Show fusuma version

### Specify touchpads by device name
Set the following options to recognize multi-touch gestures only for the specified touchpad device.

```yaml
plugin:
  filters:
    libinput_device_filter:
      keep_device_names:
        - "BUILT-IN TOUCHPAD NAME"
        - "EXTERNAL TOUCHPAD NAME"
```

## Autostart (gnome-session-properties)

1. Check the path where you installed fusuma with `$ which fusuma`
2. Open `$ gnome-session-properties`
3. Add Fusuma and enter the location where the above path was checked in the command input field
4. Add the `-d` option at the end of the command input field

## Fusuma Plugins

Following features are provided as plugins.

- Adding new gestures or combinations
- Features for specific Linux distributions
- Setting different gestures per applications

### Installation of Fusuma plugins

Fusuma plugins are provided with the `fusuma-plugin-XXXXX` naming convention and hosted on [RubyGems](https://rubygems.org/search?utf8=%E2%9C%93&query=fusuma-plugins).

`$ sudo gem install fusuma-plugin-XXXXX`

### Available plugins

| Name                                                                               | Version                                                               | About                                         |
| ---------------------------------------------------------------------------------- | --------------------------------------------------------------------- | --------------------------------------------- |
| [fusuma-plugin-sendkey](https://github.com/iberianpig/fusuma-plugin-sendkey)       | ![Gem Version](https://badge.fury.io/rb/fusuma-plugin-sendkey.svg)    | Emulates keyboard events                      |
| [fusuma-plugin-wmctrl](https://github.com/iberianpig/fusuma-plugin-wmctrl)         | ![Gem Version](https://badge.fury.io/rb/fusuma-plugin-wmctrl.svg)     | Manages Window and Workspace                  |
| [fusuma-plugin-keypress](https://github.com/iberianpig/fusuma-plugin-keypress)     | ![Gem Version](https://badge.fury.io/rb/fusuma-plugin-keypress.svg)   | Detects gestures while pressing multiple keys |
| [fusuma-plugin-tap](https://github.com/iberianpig/fusuma-plugin-tap)               | ![Gem Version](https://badge.fury.io/rb/fusuma-plugin-tap.svg)        | Detects Tap and Hold gestures                 |
| [fusuma-plugin-appmatcher](https://github.com/iberianpig/fusuma-plugin-appmatcher) | ![Gem Version](https://badge.fury.io/rb/fusuma-plugin-appmatcher.svg) | Configure app-specific gestures               |

## Tutorial Video

[![Multitouch Touchpad Gestures in Linux with Fusuma](http://img.youtube.com/vi/bn11Iwvf29I/0.jpg)](http://www.youtube.com/watch?v=bn11Iwvf29I "Multitouch Touchpad Gestures in Linux with Fusuma")
[Multitouch Touchpad Gestures in Linux with Fusuma](http://www.youtube.com/watch?v=bn11Iwvf29I) by [Eric Adams](https://www.youtube.com/user/igster75)

## Support

I'm a Freelance Engineer in Japan and working on these products after finishing my regular work or on my holidays.
Currently, my open-source contribution times is not enough.
If you like my work and want to contribute and become a sponsor, I will be able to focus on my projects.

- [GitHub Sponsors](https://github.com/sponsors/iberianpig)
- [Patreon](https://www.patreon.com/iberianpig)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iberianpig/fusuma. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
