# Contributing to Fusuma

1. Fork the repo, develop and test your code changes.
2. Send a pull request.

## Setup

In order to use the Fusuma console and run the project's tests,
there is a small amount of setup:

1. Install Ruby. Fusuma requires Ruby 2.3+. You may choose to
   manage your Ruby and gem installations with [RVM](https://rvm.io/),
   [rbenv](https://github.com/rbenv/rbenv), or
   [chruby](https://github.com/postmodern/chruby).

2. Install [Bundler](http://bundler.io/).

   ```sh
   $ gem install bundler
   ```

3. Install the top-level project dependencies.

   ```sh
   $ bundle install
   ```

## Fusuma Tests

Tests are very important part of Fusuma. All contributions
should include tests that ensure the contributed code behaves as expected.

To run tests:

``` sh
$ bundle exec rspec
```

### Fusuma Document

The project uses [YARD](https://github.com/lsegal/yard) for generating documentation.  

If you're not sure about YARD, please refer to [YARD cheatsheet](https://gist.github.com/phansch/db18a595d2f5f1ef16646af72fe1fb0e).

To run the Fusuma documentation tests:

``` sh
$ bundle exec yard --fail-on-warning
```

To check Fusuma documents with running local server:

```
$ bundle exec yard server
```
Then open (http://localhost:8808/)

## Coding Style

Please follow the established coding style in the library.
The style is is largely based on [The Ruby Style Guide](https://github.com/bbatsov/ruby-style-guide).

You can check your code against these rules by running Rubocop like so:

```sh
$ bundle exec rubocop
```

## Code of Conduct

Please note that this project is released with a Contributor Code of Conduct. By
participating in this project you agree to abide by its terms.
