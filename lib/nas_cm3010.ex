defmodule Parser do
  use Platform.Parsing.Behaviour

    # ELEMENT IoT Parser for NAS "Pulse + Analog Reader UM3023"  v0.5.0
    # Author AS
    # Documentation: https://www.nasys.no/wp-content/uploads/Absolute_encoder_communication_module_CM3010.pdf

    # Gas Usage Message
    def parse(<<liters::little-64>>,%{meta: %{frame_port: 16}}) do
      %{
        message_type: "usage",
        gas: liters
      }
    end

    # Status Message
    def parse(<<usage::little-32, _battery::signed-8, temperature::signed-8, rssi::signed-8, _rest::binary>>,%{meta: %{frame_port: 24}}) do

      %{
        message_type: "status",
        usage: usage,
        temperature: temperature,
        rssi: rssi
      }
    end

    # Boot/Debug Message
    def parse(<<0x00, serial::binary-4, firmware::24, meter_id::little-32>>,%{meta: %{frame_port: 99}}) do
      << a, b, c, d >> = serial
      << major::8, minor::8, patch::8 >> = << firmware::24 >>
      %{
        message_type: "boot",
        serial_nr: Base.encode16(<<d,c,b,a>>),
        firmware: "#{major}.#{minor}.#{patch}",
        elster_id: meter_id
      }
    end

    def parse(<<0x01>>,%{meta: %{frame_port: 99}}) do
      %{
        message_type: "shutdown"
      }
    end

    def fields do
      [
        %{
          field: "gas",
          display: "Gas usage (cumulative)",
          unit: "l"
        },
        %{
          field: "usage",
          display: "Gas usage (since last status)",
          unit: "l"
        }
        %{
          field: "temperature",
          display: "Temperature",
          unit: "°C"
        },
        %{
          field: "serial_nr",
          display: "Serial number"
        },
        %{
          field: "elster_id",
          display: "ELSTER ID"
        },
        %{
          field: "firmware",
          display: "Firmware"
        },
        %{
          field: "message_type",
          display: "Message type"
        }
      ]

    def tests() do
      [
        {
          :parse_hex, "4E29000000000000", %{meta: %{frame_port: 16}}, %{
            message_type: "usage",
            gas: 10574
          }
        },
        {
          :parse_hex, "110000004E24AA0604", %{meta: %{frame_port: 24}}, %{
            message_type: "status",
            usage: 17,
            temperature: 36,
            rssi: -86
          }
        },
        {
          :parse_hex, "003A00024B00029897C8BF01", %{meta: %{frame_port: 99}}, %{
            message_type: "boot",
            serial_nr: "4B02003A",
            firmware: "0.2.152",
            Elster_ID: 29345943
          }
        },
        {
          :parse_hex, "01", %{meta: %{frame_port: 99}}, %{
            message_type: "shutdown"
          }
        },
      ]
    end
  end
