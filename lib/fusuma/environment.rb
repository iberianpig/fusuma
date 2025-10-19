# frozen_string_literal: true

require_relative "version"
require_relative "libinput_command"
require_relative "multi_logger"

module Fusuma
  # Output Environment information
  class Environment
    class << self
      #: () -> void
      def dump_information
        MultiLogger.info "---------------------------------------------"
        print_version
        MultiLogger.info "---------------------------------------------"
        print_enabled_plugins
        MultiLogger.info "---------------------------------------------"
      end

      #: () -> void
      def print_version
        libinput_command = Plugin::Inputs::LibinputCommandInput.new.command
        MultiLogger.info "Fusuma: #{VERSION}"
        MultiLogger.info "libinput: #{libinput_command.version}"
        MultiLogger.info "ruby #{RUBY_VERSION}p#{RUBY_PATCHLEVEL}"
        MultiLogger.info "OS: #{`uname -rsv`}".strip
        MultiLogger.info "Distribution: #{`cat /etc/issue`}".strip
        MultiLogger.info "Desktop session: #{`echo $DESKTOP_SESSION $XDG_SESSION_TYPE`}".strip
      end

      #: () -> void
      def print_enabled_plugins
        MultiLogger.info "Enabled Plugins: "
        Plugin::Manager.plugins
          .reject { |k, _v| k.to_s =~ /Base/ }
          .map { |_base, plugins| plugins.map { |plugin| "  #{plugin}" } }
          .flatten.sort.each { |name| MultiLogger.info(name) }
      end

      #: () -> void
      def print_device_list
        Plugin::Filters::LibinputDeviceFilter.new.keep_device.all.map do |device|
          puts device.name
        end
      end

      def print_config
        Config.instance.keymap.each do |conf|
          puts conf.deep_stringify_keys.to_yaml
        end
      end
    end
  end
end
