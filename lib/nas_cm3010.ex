defmodule Parser do
  use Platform.Parsing.Behaviour

  require Logger

  # ELEMENT IoT Parser for NAS "ACM CM3010" v1.3.0
  # Author AS
  # Documentation: 1.2.0: https://www.nasys.no/wp-content/uploads/Absolute_encoder_communication_module_CM3010.pdf
  #                1.3.0: https://www.nasys.no/wp-content/uploads/ACM_CM3010.pdf
  #
  # Changelog:
  #   2018-06-26 [as]: Initial implementation according to "Absolute_encoder_communication_module_CM3010.pdf"
  #   2019-08-27 [gw]: Update parser to v1.3.0; added catchall
  #   2019-11-15 [jb]: Handling 32bit usage payload too.
  #   2019-12-09 [jb]: Fixed boot message for newer longer payloads.
  #

  # Gas Usage Message
  def parse(<<liters::little-32>>,%{meta: %{frame_port: 16}}) do
    %{
      message_type: "usage",
      gas: liters
    }
  end
  def parse(<<liters::little-64>>,%{meta: %{frame_port: 16}}) do
    %{
      message_type: "usage",
      gas: liters
    }
  end

  # Status Message
  def parse(<<usage::little-32, _battery::signed-8, temperature::signed-8, _rssi::binary-1, _rest::binary>>,%{meta: %{frame_port: 24}}) do
    %{
      message_type: "status",
      usage: usage,
      temperature: temperature,
    }
  end

  # Boot/Debug Message
  def parse(<<0x00, serial::binary-4, firmware::24, meter_id::little-32, _rest::binary>>,%{meta: %{frame_port: 99}}) do
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

  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
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
      },
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
  end

  def tests() do
    [
      {
        :parse_hex, "4E290000", %{meta: %{frame_port: 16}}, %{
          message_type: "usage",
          gas: 10574
        }
      },
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
#          rssi: -42
        }
      },
      {
        :parse_hex, "003A00024B00029897C8BF01", %{meta: %{frame_port: 99}}, %{
          message_type: "boot",
          serial_nr: "4B02003A",
          firmware: "0.2.152",
          elster_id: 29345943
        }
      },
      {
        :parse_hex, "007E00124B00041310734856398200000002", %{meta: %{frame_port: 99}}, %{
          elster_id: 1447588624,
          firmware: "0.4.19",
          message_type: "boot",
          serial_nr: "4B12007E"
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
