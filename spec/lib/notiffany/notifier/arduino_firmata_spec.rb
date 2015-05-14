require "notiffany/notifier/arduino_firmata"

module Notiffany
  RSpec.describe Notifier::ArduinoFirmata do
    module FakeArduinoFirmata
      def self.connect(device = nil, params = {}, &block); end
      class Error < RuntimeError; end
      class FakeArduino
        def digital_write(pin, value); end
      end
    end
    let(:arduino_firmata) { FakeArduinoFirmata }
    let(:arduino) { FakeArduinoFirmata::FakeArduino.new }

    let(:options) { {} }
    subject { described_class.new(options) }

    before do
      allow(Kernel).to receive(:require)

      stub_const "ArduinoFirmata", arduino_firmata
      allow(arduino_firmata).to receive(:connect).and_return arduino

      stub_const "ArduinoFirmata::Arduino", arduino
      allow(arduino).to receive(:digital_write)
    end

    describe "#initialize" do
      context "with arduino_firmata not installed" do
        before do
          allow(Kernel).to receive(:require).and_raise(LoadError)
        end
        it "fails" do
          expect { subject }.to raise_error(Notifier::Base::UnavailableError)
        end
      end

      context "without arduino connected" do
        before do
          allow(arduino_firmata).to receive(:connect).and_raise(ArduinoFirmata::Error)
        end
        it "fails" do
          expect { subject }.to raise_error(Notifier::Base::UnavailableError)
        end
      end

      context "with arduino connected" do
        it "works" do
          subject
        end
      end
    end

    describe "#options" do
      let(:leds) { subject.options.select { |k,v| %i(red yellow green).include? k } }
      let(:device) { subject.options.fetch :device }

      context "by default" do
        it "uses pins 9, 10 and 11" do
          expect(leds).to eq red: 11, yellow: 10, green: 9
        end

        it "uses default device" do
          expect(device).to be nil
        end
      end

      context "can be overridden" do
        let(:options) { { red: 13, yellow: 7, green: 1, device: '/dev/ttyUSB0' } }

        it "uses custom pins" do
          expect(leds).to eq red: 13, yellow: 7, green: 1
        end

        it "uses custom device" do
          expect(arduino_firmata).to receive(:connect).with('/dev/ttyUSB0')
          expect(device).to eq '/dev/ttyUSB0'
        end
      end
    end

    describe "#notify" do
      context "on failures" do
        let(:red) { subject.options.fetch :red }
        it "turns red LED on" do
          expect(arduino).to receive(:digital_write).with(red, true)
          subject.notify 'message', type: :failed
        end
      end
      context "on pending" do
        let(:yellow) { subject.options.fetch :yellow }
        it "turns yellow LED on" do
          expect(arduino).to receive(:digital_write).with(yellow, true)
          subject.notify 'message', type: :pending
        end
      end
      context "on success" do
        let(:green) { subject.options.fetch :green }
        it "turns green LED on" do
          expect(arduino).to receive(:digital_write).with(green, true)
          subject.notify 'message', type: :success
        end
      end
      context "on notify" do
        it "does not turn on any led" do
          expect(arduino).not_to receive(:digital_write).with(instance_of(Fixnum), true)
          subject.notify 'message', type: :notify
        end
      end
    end

    shared_examples_for "turns off all the LEDS" do
      it "turns off all the LEDS" do
        subject.options.values_at(:red, :yellow, :green).each do |pin|
          expect(arduino).to receive(:digital_write).with(pin, false)
        end
        subject.turn_off
      end
    end

    describe "#turn_on" do
      it_behaves_like "turns off all the LEDS"
    end

    describe "#turn_off" do
      it_behaves_like "turns off all the LEDS"
    end

  end
end
