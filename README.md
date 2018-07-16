# Fusuma [![Gem Version](https://badge.fury.io/rb/fusuma.svg)](https://badge.fury.io/rb/fusuma) [![Build Status](https://travis-ci.org/iberianpig/fusuma.svg?branch=master)](https://travis-ci.org/iberianpig/fusuma)

Fusuma is multitouch gesture recognizer.
This gem makes your linux PC able to recognize swipes or pinchs and assign commands to them.

[![https://gyazo.com/757fef526310b9d68f68e80eb1e4540f](https://i.gyazo.com/757fef526310b9d68f68e80eb1e4540f.png)](https://gyazo.com/757fef526310b9d68f68e80eb1e4540f)

襖(Fusuma) means sliding door used to partition off rooms in a Japanese house.

## Installation

### 1. **IMPORTANT**: You **MUST** be a member of the _input_ group to have permission to read the touchpad device:

```bash
$ sudo gpasswd -a $USER input
```

Then, You **MUST** **LOGOUT/LOGIN or REBOOT** to assign this group.

### 2. You need `libinput` release 1.0 or later.
Install `libinput-tools`: 

```bash
$ sudo apt-get install libinput-tools
```

### 3. For sending shortcuts(optional):

```bash
$ sudo apt-get install xdotool
```

### 4. Install Fusuma:

```bash
$ sudo gem install fusuma
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

### Example (Gesture Mapping for Elementary OS)

```yaml
swipe:
  3: 
    left: 
      command: 'xdotool key alt+Left'
    right: 
      command: 'xdotool key alt+Right'
    up: 
      command: 'xdotool key ctrl+t'
    down: 
      command: 'xdotool key ctrl+w'
  4:
    left: 
      command: 'xdotool key super+Left'
    right: 
      command: 'xdotool key super+Right'
    up: 
      command: 'xdotool key super+a'
    down: 
      command: 'xdotool key super+s'
pinch:
  in:
    command: 'xdotool key ctrl+plus'
  out:
    command: 'xdotool key ctrl+minus'

threshold:
  swipe: 1
  pinch: 1

interval:
  swipe: 1
  pinch: 1
```

if `command: ` properties are blank, the swipe/pinch doesn't trigger command.

`threshold:` is sensitivity to swipe/pinch. Default value is 1.
If the swipe's threshold is `0.5`, shorten swipe-length by half.

`interval:` is delay between swipes/pinches. Default value is 1.
If the swipe's interval is `0.5`, shorten swipe-interval by half to recognize a next swipe.

### `command: ` property for assigning commands
On fusuma version 0.4 `command: ` property is available!
You can assign any command each gestures.

**`shortcut: ` property is deprecated**, **it will be removed on fusuma version 1.0**.
You need to replace to `command: ` property.


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

## Options

*   `-c`, `--config=path/to/file` : Use an alternative config file
*   `-d`, `--daemon`              : Daemonize process
*   `-l`, `--list-devices`        : List available devices
*   `-v`, `--verbose`             : Show details about the results of running fusuma
*   `--device="Device name"`      : Open the given device only
*   `--version`                   : Show fusuma version

## AutoStart(gnome-session-properties)
1. Check where you installed fusuma
2. Open `$ gnome-session-properties`
3. Add Fusuma and input location where you checked above's path

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iberianpig/fusuma. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

