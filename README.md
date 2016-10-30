# Fusuma

Fusuma is multitouch gesture recognizer.
This gem makes your linux PC able to recognize swipes or pinchs and assign shortcuts to them.

[![https://gyazo.com/757fef526310b9d68f68e80eb1e4540f](https://i.gyazo.com/757fef526310b9d68f68e80eb1e4540f.png)](https://gyazo.com/757fef526310b9d68f68e80eb1e4540f)

襖(Fusuma) means sliding door used to partition off rooms in a Japanese house.

## Installation

IMPORTANT: You must be a member of the _input_ group to have permission
to read the touchpad device:

    $ sudo gpasswd -a $USER input  # Log out and back in to assign this group

You need libinput release 1.0 or later. Install prerequisites:

If you are using pacman (for archlinux).

    $ sudo pacman -S xdotool

If you are using apt (for ubuntu/debian based distributions).

    $ sudo apt-get install xdotool


Install Fusuma

    $ gem install fusuma

## Usage

    $ fusuma

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iberianpig/fusuma. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

