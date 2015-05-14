require "notiffany/notifier/base"

module Notiffany
  class Notifier
    # Shows notifications by turning on LEDs on an Arduino board using the
    # Firmata protocol.
    #
    # It is expected to have three LEDs: red, yellow and green.
    #
    class ArduinoFirmata < Base
      DEFAULTS = {
        device: nil,
        red:    11,
        yellow: 10,
        green:   9
      }

      # Turns off all the LEDs.
      def turn_off
        _all_off if @arduino
      end

      # When turning on ensures that all LEDs are off.
      alias_method :turn_on, :turn_off

      private

      # Tries to connect to the Arduino board.
      def _check_available(options = {})
        @arduino = ::ArduinoFirmata.connect options.fetch :device
      rescue ::ArduinoFirmata::Error => e
        fail UnavailableError, e.message
      end

      # Shows a notification by turning on one LED.
      #
      # @param [Hash] opts additional notification library options
      # @option opts [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      #
      def _perform_notify(message, opts = {})
        _all_off

        case opts.fetch :type
        when :success
          @arduino.digital_write opts[:green], true
        when :pending
          @arduino.digital_write opts[:yellow], true
        when :failed
          @arduino.digital_write opts[:red], true
        end
      end

      # Turns off all LEDS.
      def _all_off
        @options.values_at(:red, :yellow, :green).each do |pin|
          @arduino.digital_write pin, false
        end
      end
    end
  end
end
