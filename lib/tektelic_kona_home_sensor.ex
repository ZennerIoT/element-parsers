defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # Parser for Tektelic Kona home sensor.
  #
  # Changelog:
  #   2019-10-15 [jb]: Initial implementation according to "T0005370_TRM_ver2.0.pdf"
  #

  def parse(payload, %{meta: %{frame_port: 10}}) do
    payload
    |> parse_frames([])
    |> Enum.into(%{})
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  def parse_frames(<<0x00, 0xFF, battery::16-signed, rest::binary>>, frames) do
    battery_volt = (battery*10) / 1000 # Conversion 10mV in V
    parse_frames(rest, [{:battery, battery_volt}|frames])
  end
  def parse_frames(<<0x01, 0x00, reed_switch, rest::binary>>, frames) do
    parse_frames(rest, [{:reed_switch, digital_inverse(reed_switch)}|frames])
  end
  def parse_frames(<<0x02, 0x00, light_detected, rest::binary>>, frames) do
    parse_frames(rest, [{:light_detected, digital(light_detected)}|frames])
  end
  def parse_frames(<<0x03, 0x67, temperature::16-signed, rest::binary>>, frames) do
    temperature_c = temperature/10 # Conversion from 0.1°C to °C
    parse_frames(rest, [{:temperature, temperature_c}|frames])
  end
  def parse_frames(<<0x04, 0x68, relative_humidity, rest::binary>>, frames) do
    relative_humidity_percent = relative_humidity / 2 # Conversion from 0.5% to %
    parse_frames(rest, [{:relative_humidity, relative_humidity_percent}|frames])
  end
  def parse_frames(<<0x05, 0x02, impact::16-signed, rest::binary>>, frames) do
    impact_g = impact / 1000 # Conversion from 1 milli-g to g
    parse_frames(rest, [{:impact, impact_g}|frames])
  end
  def parse_frames(<<0x06, 0x00, break_in, rest::binary>>, frames) do
    parse_frames(rest, [{:break_in, digital(break_in)}|frames])
  end
  def parse_frames(<<0x07, 0x71, accelero::binary-6, rest::binary>>, frames) do
    <<x::16-signed, y::16-signed, z::16-signed>> = accelero
    parse_frames(rest, [
      {:acceleration_x, x / 100}, # g
      {:acceleration_y, y / 100}, # g
      {:acceleration_z, z / 100} # g
    |frames])
  end
  def parse_frames(<<0x08, 0x04, counter::16, rest::binary>>, frames) do
    parse_frames(rest, [{:reed_switch_counter, counter}|frames])
  end
  def parse_frames(<<0x09, 0x00, moisture, rest::binary>>, frames) do
    parse_frames(rest, [{:moisture, digital(moisture)}|frames])
  end
  def parse_frames(<<0x0A, 0x00, motion, rest::binary>>, frames) do
    parse_frames(rest, [{:motion, digital(motion)}|frames])
  end
  def parse_frames(<<0x0B, 0x67, temperature::16-signed, rest::binary>>, frames) do
    temperature_c = temperature/10 # Conversion from 0.1°C to °C
    parse_frames(rest, [{:temperature_mcu, temperature_c}|frames])
  end
  def parse_frames(<<0x0C, 0x00, impact_alarm, rest::binary>>, frames) do
    parse_frames(rest, [{:impact_alarm, impact_alarm}|frames])
  end
  def parse_frames(<<0x0D, 0x04, motion_count::16, rest::binary>>, frames) do
    parse_frames(rest, [{:motion_count, motion_count}|frames])
  end
  def parse_frames(<<0x0E, 0x00, external_input, rest::binary>>, frames) do
    parse_frames(rest, [{:external_input, digital_inverse(external_input)}|frames])
  end
  def parse_frames(<<0x0F, 0x04, external_input_count, rest::binary>>, frames) do
    parse_frames(rest, [{:external_input_count, external_input_count}|frames])
  end
  def parse_frames(<<>>, frames), do: Enum.reverse(frames)
  def parse_frames(payload, frames) do
    Logger.warn("Tektelic.Parser: Unknown frame found: #{inspect payload}")
    frames
  end

  def digital(0x00), do: 0
  def digital(0xFF), do: 1

  def digital_inverse(0x00), do: 1
  def digital_inverse(0xFF), do: 0

  # Define fields with human readable name and a SI unit if available.
  def fields() do
    [
      %{
        field: "battery",
        display: "Battery",
        unit: "V",
      },
      %{
        field: "reed_switch",
        display: "Reed Switch",
      },
      %{
        field: "light_detected",
        display: "Light Detected",
      },
      %{
        field: "temperature",
        display: "Temperature",
        unit: "°C",
      },
      %{
        field: "temperature_mcu",
        display: "Temperature-MCU",
        unit: "°C",
      },
      %{
        field: "relative_humidity",
        display: "Relative Humidity",
        unit: "%",
      },
      %{
        field: "impact",
        display: "Impact",
        unit: "g",
      },
      %{
        field: "break_in",
        display: "Break In",
      },
      %{
        field: "acceleration_x",
        display: "Acceleration X",
        unit: "g",
      },
      %{
        field: "acceleration_y",
        display: "Acceleration Y",
        unit: "g",
      },
      %{
        field: "acceleration_z",
        display: "Acceleration Z",
        unit: "g",
      },
      %{
        field: "reed_switch_counter",
        display: "Reed Switch Counter",
      },
      %{
        field: "moisture",
        display: "Moisture",
      },
      %{
        field: "motion",
        display: "Motion",
      },
      %{
        field: "impact_alarm",
        display: "Impact-Alarm",
      },
      %{
        field: "motion_count",
        display: "Motion-Count",
      },
      %{
        field: "external_input",
        display: "External Input",
      },
      %{
        field: "external_input_count",
        display: "External Input Count",
      },
    ]
  end

  def tests() do
    [
      # Real payload
      {:parse_hex, "036700DE04686A00FF0133", %{meta: %{frame_port: 10}}, %{battery: 3.07, relative_humidity: 53.0, temperature: 22.2}},

      # Examples from docs
      {:parse_hex, "03 67 00 0A 04 68 28", %{meta: %{frame_port: 10}}, %{relative_humidity: 20.0, temperature: 1.0}},
      {:parse_hex, "04 68 14 01 00 FF 08 04 00 05", %{meta: %{frame_port: 10}}, %{reed_switch: 0, reed_switch_counter: 5, relative_humidity: 10.0}},
      {:parse_hex, "04 68 2A 03 67 FF FF 00 FF 01 2C", %{meta: %{frame_port: 10}}, %{battery: 3.0, relative_humidity: 21.0, temperature: -0.1}},
      {:parse_hex, "02 00 FF 07 71 00 3A 00 07 00 53 0E 00 00", %{meta: %{frame_port: 10}}, %{
        acceleration_x: 0.58,
        acceleration_y: 0.07,
        acceleration_z: 0.83,
        external_input: 1,
        light_detected: 1
      }},
      {:parse_hex, "0D 04 00 02 06 00 FF", %{meta: %{frame_port: 10}}, %{break_in: 1, motion_count: 2}},
    ]
  end
end
