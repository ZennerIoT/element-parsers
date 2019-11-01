defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for NAS "LoRaWAN Modularis Module CM 3020" Wasserzähler
  #
  # Changelog:
  #   2019-00-0 [tr]: Initial implementation according to "https://www.nasys.no/wp-content/uploads/Wehrle_Modularis_module_CM3020_3.pdf"
  #

  # Water Usage Message
  def parse(<<liters::little-32>>, %{meta: %{frame_port: 14}}) do
    %{
      message_type: "usage",
      water: liters
    }
  end

  # Status Message
  def parse(<<usage::little-32, battery::8, temperature::signed-8, _::signed-8, status::16>>, %{meta: %{frame_port: 24}}) do
    <<mode::8, state::8>> = <<status::16>>
    <<_::5, temp_detec_m::1, _::2 >> = <<mode>>
    <<is_alert::1, user_trig::1, _::3, temp_detec_s::1, _::2>> = <<state>>
    temp_detec_m = case temp_detec_m do
      0 -> "Off"
      1 -> "On"
    end
    temp_detec_s = case temp_detec_s do
      0 -> "Ok"
      1 -> "Alert"
    end
    %{
      message_type: "status",
      battery: battery*16,
      temp_detec_m: temp_detec_m,
      temp_detec_s: temp_detec_s,
      user_trig: user_trig,
      is_alert: is_alert,
      usage: usage,
      temperature: temperature
    }
  end

  # Boot/Debug Message. Payload description is wrong. Stick to example (debug_info has 10 Byte)
  def parse(<<0x00, serial::binary-4, firmware::24, reason::8, debug_info::binary>>, %{meta: %{frame_port: 99}}) do
    <<a, b, c, d>> = serial # need to reverse binary
    << major::8, minor::8, patch::8 >> = << firmware::24 >>
    reason = case reason do
      0x10 -> "Calibration Timeout"
      0x31 -> "Shutdown by user (magnet)"
      _ -> "Unknown reason"
    end
    %{
      message_type: "boot",
      serial_nr: Base.encode16(<<d,c,b,a>>),
      firmware: "#{major}.#{minor}.#{patch}",
      reason: reason,
      debug_info: Base.encode16(debug_info),
    }
  end

  # Shutdown Message
  def parse(<<0x01, reason::8, usage::little-32, battery::8, temperature::signed-8, _::signed-8, status::16>>, %{meta: %{frame_port: 99}}) do
    <<mode::8, state::8>> = <<status::16>>
    <<_::5, temp_detec_m::1, _::2 >> = <<mode>>
    <<is_alert::1, user_trig::1, _::3, temp_detec_s::1, _::2>> = <<state>>
    temp_detec_m = case temp_detec_m do
      0 -> "Off"
      1 -> "On"
    end
    temp_detec_s = case temp_detec_s do
      0 -> "Ok"
      1 -> "Alert"
    end
    reason = case reason do
      0x10 -> "Calibration Timeout"
      0x31 -> "Shutdown by user (magnet)"
    end
    %{
      message_type: "shutdown",
      battery: battery*16,
      temperature: temperature,
      temp_detec_m: temp_detec_m,
      temp_detec_s: temp_detec_s,
      user_trig: user_trig,
      is_alert: is_alert,
      usage: usage,
      reason: reason,
    }
  end

  def parse(payload, meta) do
    Logger.info("Unknown payload #{inspect payload} and frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  def fields do
    [
      %{
        field: "message_type",
        display: "Message type"
      },
      %{
        field: "water",
        display: "Liter count",
        unit: "l"
      },
      %{
        field: "usage",
        display: "Usage counter",
        unit: "l"
      },
      %{
        field: "temp_detec_m",
        display: "Temp. detection Mode"
      },
      %{
        field: "temp_detec_s",
        display: "Temp. detection Status"
      },
      %{
        field: "temperature",
        display: "Temperature",
        unit: "°C"
      },
      %{
        field: "user_trig",
        display: "User triggered"
      },
      %{
        field: "is_alert",
        display: "is alert"
      },
      %{
        field: "battery",
        display: "battery",
        unit: "mV"
      },
      %{
        field: "serial_nr",
        display: "Serial number"
      },
      %{
        field: "firmware",
        display: "Firmware"
      },
      %{
        field: "reason",
        display: "Reason"
      },
      %{
        field: "debug_info",
        display: "Debug Info"
      }
    ]
  end

  def tests() do
    [
      {
        :parse_hex, "800A0000", %{meta: %{frame_port: 14}}, %{
          message_type: "usage",
          water: 2688
        }
      },
      {
        #Changed batteyvoltage from 1278 to 1248 mV. Datasheet mistake
        :parse_hex, "110000004e24000440", %{meta: %{frame_port: 24}}, %{
          message_type: "status",
          usage: 17,
          temperature: 36,
          battery: 1248,
          temp_detec_m: "On",
          temp_detec_s: "Ok",
          user_trig: 1,
          is_alert: 0
        }
      },
      {
        #Removed 2 Byte from example payload (17 expected, 19 given originally)
        :parse_hex, "001601114C0006001004008300280140000000", %{meta: %{frame_port: 99}}, %{
          message_type: "boot",
          serial_nr: "4C110116",
          firmware: "0.6.0",
          reason: "Calibration Timeout",
          debug_info: "04008300280140000000"
        }
      },
      {
        :parse_hex, "0131110000004e24000440", %{meta: %{frame_port: 99}}, %{
          message_type: "shutdown",
          reason: "Shutdown by user (magnet)",
          temperature: 36,
          battery: 1248,
          temp_detec_m: "On",
          temp_detec_s: "Ok",
          user_trig: 1,
          is_alert: 0,
          usage: 17
        }
      },
    ]
  end
end
