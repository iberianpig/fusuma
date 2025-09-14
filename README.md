# Fusuma
![Gem](https://img.shields.io/gem/v/fusuma?color=brightgreen) [![Build Status](https://github.com/iberianpig/fusuma/actions/workflows/main.yml/badge.svg)](https://github.com/iberianpig/fusuma/actions/workflows/main.yml)

Fusuma is a powerful tool designed to enable multitouch gesture recognition on Linux, providing intuitive operations for users. By utilizing gestures like swipes and pinches on laptops and devices with touchpads, you can create a more efficient working environment.

![fusuma_image](https://repository-images.githubusercontent.com/69813387/60879a00-166c-11ea-9875-3bf0818c62ec)

襖(Fusuma) means sliding door used to partition off rooms in a Japanese house.

## Features

- **Easy Installation**: Quick setup via RubyGems.
- **Flexible Configuration**: Customize gestures and actions freely in YAML file format.
- **Sensitivity Settings**: Fine-tune gesture recognition with adjustable thresholds and intervals to suit your preferences and enhance precision.
- **Extension through Plugins**: A [plugin system](https://github.com/iberianpig/fusuma/#fusuma-plugins) allows for additional functionality as needed.

Enhance your Linux experience by evolving your interaction with Fusuma!

## Installation

### Grant permission to read the touchpad device

**IMPORTANT**: You **MUST** be a member of the **INPUT** group to read touchpad by Fusuma.

```sh
sudo gpasswd -a $USER input
```

Then, You apply the change with no logout or reboot.

```sh
newgrp input
```

**IMPORTANT**: This makes `/dev/input/` readable, so if that's an issue for you for some reason (like for privacy- or securityconcerns etc. or if it causes other parts of your OS to misbehave), **consider this your heads-up.** 

<details>
<summary>For Debian Based Distros (Ubuntu, Debian, Mint, Pop!_OS)</summary>

### For Debian Based Distros (Ubuntu, Debian, Mint, Pop!_OS)

#### 1. Install libinput-tools

You need `libinput` release 1.0 or later.

```sh
sudo apt-get install libinput-tools
```

#### 2. Install Ruby

Fusuma runs in Ruby, so you must install it first.

```sh
sudo apt-get install ruby
```

#### 3. Install Fusuma

```sh
sudo gem install fusuma
```

#### 4. Install xdotool (optional)

For sending shortcuts:

```sh
sudo apt-get install xdotool
```

</details>

<details>
<summary> For Arch Based Distros (Manjaro, Arch) </summary>

### For Arch Based Distros (Manjaro, Arch)

#### 1. Install libinput.

You need `libinput` release 1.0 or later. This is most probably installed by default on Manjaro

```sh
sudo pacman -Syu libinput
```

#### 2. Install Ruby

Fusuma runs in Ruby, so you must install it first.

```sh
sudo pacman -Syu ruby
```

#### 3. Install Fusuma

**Note:** By default in Arch Linux, when running `gem`, gems are installed per-user (into `~/.gem/ruby/`), instead of system-wide (into `/usr/lib/ruby/gems/`). This is considered the best way to manage gems on Arch, because otherwise they might interfere with gems installed by Pacman. (From Arch Wiki)

To install gems system-wide, see any of the methods listed on [Arch Wiki](https://wiki.archlinux.org/index.php/ruby#Installing_gems_system-wide)

```sh
sudo gem install fusuma
```

#### 4. Install xdotool (optional)

For sending shortcuts:

```sh
sudo pacman -Syu xdotool
```
**For the truly lazy people:** As with pretty much anything else available as Open-Source-Software, you can install Fusuma via a package from the AUR. As off time of writing (March 2023), the package you would want is called `ruby-fusuma`.

Please keep in mind that this community-built package is NOT officially supported here and while it might do the job, it is not the intended way to install.
Installing Fusuma this way means that if things do not work as intended during or after the installation, you are on your own.
So please do not bombard the Issues-Page here on Github if Fusuma isn't working correctly after installing it via the AUR.
Fusuma's plugins as listed below here in this Readme can be installed as optional dependencies also via the AUR, namescheme being `ruby-fusuma-replacewithnameofplugin`.
</details>

<details>
<summary>For Fedora</summary>

### For Fedora

#### 1. Install libinput-tools

You need `libinput` release 1.0 or later.

```sh
sudo dnf install libinput
```

#### 2. Install Ruby

Fusuma runs in Ruby, so you must install it first.

```sh
sudo dnf install ruby
```

#### 3. Install Fusuma

```sh
sudo gem install fusuma
```

#### 4. Install xdotool (optional)

For sending shortcuts:

```sh
sudo dnf install xdotool
```
</details>

### Touchpad not working in GNOME

Ensure the touchpad events are being sent to the GNOME desktop by running the following command:

```sh
gsettings set org.gnome.desktop.peripherals.touchpad send-events enabled
```

## Usage

```sh
fusuma
```

## Update

```sh
sudo gem update fusuma
```

## Customize Gesture Mapping

You can customize the settings for gestures to put and edit `~/.config/fusuma/config.yml`.
**NOTE: You will need to create the `~/.config/fusuma` directory if it doesn't exist yet.**

```sh
mkdir -p ~/.config/fusuma        # create config directory
nano ~/.config/fusuma/config.yml # edit config file.
```


### Available gestures

#### swipe:

 * support `3:`, `4:` fingers
 * support `left:`, `right:`, `up:`, `down:` directions
 * support `begin:`, `update:`, `end:` events

#### pinch:

 * support `2:`, `3:`, `4:` fingers
 * support `in:`, `out:` directions
 * support `begin:`, `update:`, `end:` events

#### rotate:

 * support `2:`, `3:`, `4:` fingers
 * support `clockwise:`,`counterclockwise:` directions
 * support `begin:`, `update:`, `end:` events

#### hold:
 * require libinput version 1.19.0 or later
 * support `1:`, `2:`, `3:`, `4:` fingers
 * support `begin:`, `end:`, `cancelled:` events

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
hold:
  4:
    command: "xdotool key super" # Activity
```

### More Example of config.yml

The following wiki pages can be edited by everyone.

- [Ubuntu](https://github.com/iberianpig/fusuma/wiki/Ubuntu)
- [elementary OS](https://github.com/iberianpig/fusuma/wiki/elementary-OS)
- [i3](https://github.com/iberianpig/fusuma/wiki/i3)
- [KDE to mimic MacOS](https://github.com/iberianpig/fusuma/wiki/KDE-to-mimic-MacOS)
- [Pop!_OS with Cinnamon](https://github.com/iberianpig/fusuma/wiki/POP-OS-with-Cinnamon)
- [Pop!_OS Default Gnome](https://github.com/iberianpig/fusuma/wiki/PopOS-Default-Gnome)
- [Ubuntu OS to mimic Mac a little](https://github.com/iberianpig/fusuma/wiki/Ubuntu-OS-to-mimic-Mac-a-little)
- [3 fingers Drag (OS X Style)](https://github.com/iberianpig/fusuma/wiki/3-fingers-Drag-(OS-X-Style))
- [3 fingers Alt Tab Switcher(Windows Style)](https://github.com/iberianpig/fusuma/wiki/3-fingers-Alt-Tab-Switcher(Windows-Style))

If you have a nice configuration, please share `~/.config/fusuma/config.yml` with everyone.

### Threshold and Interval

if `command:` properties are blank, the swipe/pinch/hold doesn't execute command.

`threshold:` is sensitivity to swipe/pinch/hold. Default value is 1.
If the swipe's threshold is `0.5`, shorten swipe-length by half.

`interval:` is delay between swipes/pinches/hold. Default value is 1.
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
1. root child elements (threshold/interval → swipe/pinch/hold)
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
  - install with `sudo apt install xautomation`

- [ydotool](https://github.com/ReimuNotMoe/ydotool)
  - Wayland compatible
  - Needs more maintainers.



## Options

- `-c`, `--config=path/to/file` : Use an alternative config file
- `-d`, `--daemon` : Daemonize process
- `-l`, `--list-devices` : List available devices
- `-v`, `--verbose` : Show details about the results of running fusuma
- `--version` : Show fusuma version
- `--log-file=path/to/file` : Set path of log file

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

## Autostart

### Method 1: Using gnome-session-properties

1. Check the path where you installed fusuma with `which fusuma`
2. Open `gnome-session-properties`
3. Add Fusuma and enter the location where the above path was checked in the command input field
4. Add the `-d` option at the end of the command input field

### Method 2: Creating a Desktop Entry Manually

1. Check the path where you installed fusuma with `which fusuma`
2. Create a new file named `fusuma.desktop` in the `~/.config/autostart/` directory.
3. Add the following content to the `fusuma.desktop` file:

```ini
[Desktop Entry]
Name=fusuma
Comment=run fusuma
Exec={path_to_fusuma} -d --log=/tmp/fusuma.log
Icon=input-touchpad
X-GNOME-Autostart-enabled=true
Type=Application
```

   Replace `{path_to_fusuma}` with the path obtained from `which fusuma`.
4. Save the file and ensure its permissions are correctly set to be executable.
5. Restart your system or session to verify that fusuma starts automatically.

## Fusuma Plugins

Fusuma's functionality can be extended with a variety of plugins. Below is a list of available plugins along with their purposes:

### Available Plugins

Fusuma plugins are provided with the `fusuma-plugin-XXXXX` naming convention and hosted on [RubyGems](https://rubygems.org/search?utf8=%E2%9C%93&query=fusuma-plugins).

| Name                                                                               | Version                                                                         | About                                                        |
| ---                                                                                | ---                                                                             | ---                                                          |
| [fusuma-plugin-sendkey](https://github.com/iberianpig/fusuma-plugin-sendkey)       | ![Gem](https://img.shields.io/gem/v/fusuma-plugin-sendkey?color=brightgreen)    | Emulates keyboard events(Wayland compatible)                 |
| [fusuma-plugin-wmctrl](https://github.com/iberianpig/fusuma-plugin-wmctrl)         | ![Gem](https://img.shields.io/gem/v/fusuma-plugin-wmctrl?color=brightgreen)     | Manages Window and Workspace                                 |
| [fusuma-plugin-keypress](https://github.com/iberianpig/fusuma-plugin-keypress)     | ![Gem](https://img.shields.io/gem/v/fusuma-plugin-keypress?color=brightgreen)   | Detecting a combination of key presses and touchpad gestures |
| [fusuma-plugin-appmatcher](https://github.com/iberianpig/fusuma-plugin-appmatcher) | ![Gem](https://img.shields.io/gem/v/fusuma-plugin-appmatcher?color=brightgreen) | Configure app-specific gestures                              |
| [fusuma-plugin-thumbsense](https://github.com/iberianpig/fusuma-plugin-thumbsense) | ![Gem](https://img.shields.io/gem/v/fusuma-plugin-thumbsense?color=brightgreen) | Remapper from key to click only while tapping                |


### Installation of Fusuma plugins

```sh
# install fusuma-plugin-XXXX
sudo gem install fusuma-plugin-XXXXX`
```
```sh
# update
sudo gem list fusuma-plugin- | cut -d' ' -f1 | xargs --no-run-if-empty sudo gem update
```

## Tutorial Video

[![Multitouch Touchpad Gestures in Linux with Fusuma](http://img.youtube.com/vi/bn11Iwvf29I/0.jpg)](http://www.youtube.com/watch?v=bn11Iwvf29I "Multitouch Touchpad Gestures in Linux with Fusuma")  
[Multitouch Touchpad Gestures in Linux with Fusuma](http://www.youtube.com/watch?v=bn11Iwvf29I) by [Eric Adams](https://www.youtube.com/user/igster75)

### Support and Sponsorship

If you enjoy working on Fusuma or find it beneficial, consider supporting the developer through [GitHub Sponsors](https://github.com/sponsors/iberianpig).

I'm a Freelance Engineer in Japan and working on these products after finishing my regular work or on my holidays.
Currently, my open-source contribution times is not enough.
If you like my work and want to contribute and become a sponsor, I will be able to focus on my projects.

## Development

### Type Checking

Fusuma uses [RBS](https://github.com/ruby/rbs) for type signatures and [Steep](https://github.com/soutaro/steep) for type checking.

#### Running Type Checks

```sh
# Generate RBS signatures and run type checking
bundle exec rake rbs:setup && bundle exec steep check

# Validate RBS files
bundle exec rake rbs:validate

# Generate inline RBS from code comments
bundle exec rbs-inline --opt-out lib --output --base .
```

#### RBS Development

The project uses both traditional RBS files and inline RBS comments:
- Inline RBS comments in source code (processed by `rbs-inline`)
- Generated RBS files in `sig/generated/`
- Type checking via Steep with configuration in `Steepfile`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iberianpig/fusuma. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
