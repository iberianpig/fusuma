# frozen_string_literal: true

require "fiddle"

module Fusuma
  module Libinput
    # libinput_interface struct with open_restricted/close_restricted callbacks
    class Interface
      SIZEOF_VOIDP = Fiddle::SIZEOF_VOIDP

      attr_reader :to_ptr

      #: () -> void
      def initialize
        # Create callbacks and retain references to prevent GC
        @open_restricted = Fiddle::Closure::BlockCaller.new(
          Fiddle::TYPE_INT,
          [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP]
        ) do |path_ptr, flags, _user_data|
          path = path_ptr.to_s
          begin
            fd = IO.sysopen(path, flags)
            fd
          rescue SystemCallError => e
            -e.errno
          end
        end

        @close_restricted = Fiddle::Closure::BlockCaller.new(
          Fiddle::TYPE_VOID,
          [Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP]
        ) do |fd, _user_data|
          IO.for_fd(fd, autoclose: true).close
        rescue IOError, Errno::EBADF
          # already closed, ignore
        end

        # Build the struct: two function pointers packed sequentially
        @to_ptr = Fiddle::Pointer.malloc(SIZEOF_VOIDP * 2, Fiddle::RUBY_FREE)
        @to_ptr[0, SIZEOF_VOIDP] = [@open_restricted.to_i].pack(ptr_pack_format)
        @to_ptr[SIZEOF_VOIDP, SIZEOF_VOIDP] = [@close_restricted.to_i].pack(ptr_pack_format)
      end

      private

      #: () -> String
      def ptr_pack_format
        (SIZEOF_VOIDP == 8) ? "Q" : "L"
      end
    end
  end
end
