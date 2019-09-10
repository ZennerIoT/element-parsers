defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # Parser for device Sensative Strips Comfort.
  # Link: https://sensative.com/strips/
  #
  # Changelog:
  #   2019-09-10 [jb]: Initial implementation according to "Sensative_LoRa-Strips-Manual-Alpha-2.pdf"
  #

  def parse(<<hist_seq_nr::16, rest::binary>>, %{meta: %{frame_port: 1}}) do
    hist_seq_nr
    |> case  do
      65535 -> %{}
      _ -> %{hist_seq_nr: hist_seq_nr}
    end
    |> parse_parts(rest)
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  # 1.1.1 Empty report
  def parse_parts(result, <<history::1, 0::7, rest::binary>>) do
    result
    |> Map.merge(%{history: history, empty_report: true})
    |> parse_parts(rest)
  end

  # 1.1.2 Battery report
  def parse_parts(result, <<history::1, 1::7, battery::8, rest::binary>>) do
    result
    |> Map.merge(%{history: history, battery: battery})
    |> parse_parts(rest)
  end

  # 1.1.3 Temperature report
  def parse_parts(result, <<history::1, 2::7, temp::signed-16, rest::binary>>) do
    result
    |> Map.merge(%{history: history, temperature: temp/10}) # Celsius
    |> parse_parts(rest)
  end

  # 1.1.4 Temperature level alarm
  def parse_parts(result, <<history::1, 3::7, _spare::6, low_alarm::1, high_alarm::1, rest::binary>>) do
    result
    |> Map.merge(%{history: history, temperature_low_alarm: low_alarm, temperature_high_alarm: high_alarm})
    |> parse_parts(rest)
  end

  # 1.1.5 Average Temperature report
  def parse_parts(result, <<history::1, 4::7, avg_temp::signed-16, rest::binary>>) do
    result
    |> Map.merge(%{history: history, temperature_avg: avg_temp})
    |> parse_parts(rest)
  end

  # 1.1.6 Average Temperature level alarm
  def parse_parts(result, <<history::1, 5::7, _spare::6, low_alarm::1, high_alarm::1, rest::binary>>) do
    result
    |> Map.merge(%{history: history, temperature_avg_low_alarm: low_alarm, temperature_avg_high_alarm: high_alarm})
    |> parse_parts(rest)
  end

  # 1.1.7 Relative Humidity Report
  def parse_parts(result, <<history::1, 6::7, humidity::8, rest::binary>>) do
    result
    |> Map.merge(%{history: history, humidity: humidity/2})
    |> parse_parts(rest)
  end

  # 1.1.8 Ambient light report
  def parse_parts(result, <<history::1, 7::7, ambient::16, rest::binary>>) do
    result
    |> Map.merge(%{history: history, ambient_light: ambient}) # Lux
    |> parse_parts(rest)
  end

  # 1.1.9 Second Ambient light report
  def parse_parts(result, <<history::1, 8::7, ambient::16, rest::binary>>) do
    result
    |> Map.merge(%{history: history, ambient_light2: ambient})
    |> parse_parts(rest)
  end

  # 1.1.10 Door report
  def parse_parts(result, <<history::1, 9::7, _::7, door_closed::1, rest::binary>>) do
    result
    |> Map.merge(%{history: history, door_closed: door_closed})
    |> parse_parts(rest)
  end

  # 1.1.11 Door alarm
  def parse_parts(result, <<history::1, 10::7, _::7, door_alarm::1, rest::binary>>) do
    result
    |> Map.merge(%{history: history, door_alarm: door_alarm})
    |> parse_parts(rest)
  end

  # 1.1.12 Tamper switch report
  def parse_parts(result, <<history::1, 11::7, _::7, tamper::1, rest::binary>>) do
    result
    |> Map.merge(%{history: history, tamper: tamper})
    |> parse_parts(rest)
  end

  # 1.1.13 Tamper alarm
  # Note: Tamper Alarm active when door is closed and tamper switch is activated
  def parse_parts(result, <<history::1, 12::7, _::7, tamper_alarm::1, rest::binary>>) do
    result
    |> Map.merge(%{history: history, tamper_alarm: tamper_alarm})
    |> parse_parts(rest)
  end

  # 1.1.14 Flood sensor level report
  def parse_parts(result, <<history::1, 13::7, flood::8, rest::binary>>) do
    result
    |> Map.merge(%{history: history, flood: flood}) # percent
    |> parse_parts(rest)
  end

  # 1.1.15 Flood alarm
  def parse_parts(result, <<history::1, 14::7, _::7, flood_alarm::1, rest::binary>>) do
    result
    |> Map.merge(%{history: history, flood_alarm: flood_alarm})
    |> parse_parts(rest)
  end

  # 1.1.16 Foil alarm
  def parse_parts(result, <<history::1, 15::7, _::7, foil_alarm::1, rest::binary>>) do
    result
    |> Map.merge(%{history: history, foil_alarm: foil_alarm})
    |> parse_parts(rest)
  end

  # 1.1.17 Combined Temperature and Humidity Report
  def parse_parts(result, <<history::1, 80::7, temp::16, humidity::8, rest::binary>>) do
    result
    |> Map.merge(%{history: history, temperature: temp/10, humidity: humidity/2})
    |> parse_parts(rest)
  end

  # 1.1.18 Combined Average Temperature and Humidity Report
  def parse_parts(result, <<history::1, 81::7, temp::16, humidity::8, rest::binary>>) do
    result
    |> Map.merge(%{history: history, temperature_avg: temp/10, humidity_avg: humidity/2})
    |> parse_parts(rest)
  end

  # 1.1.19 Combined Temperature and Door Report
  def parse_parts(result, <<history::1, 82::7, temp::16, _::7, door::1, rest::binary>>) do
    result
    |> Map.merge(%{history: history, temperature_avg: temp/10, door_closed: door})
    |> parse_parts(rest)
  end

  # 1.1.20 Raw Capacitance Flood sensor report
  def parse_parts(result, <<history::1, 112::7, cap_val::16, rest::binary>>) do
    result
    |> Map.merge(%{history: history, flood_capacitance: cap_val}) # Raw value from capacitance sensor
    |> parse_parts(rest)
  end

  # 1.1.21 Raw Capacitance Pad sensor report
  def parse_parts(result, <<history::1, 113::7, cap_val::16, rest::binary>>) do
    result
    |> Map.merge(%{history: history, pad_capacitance: cap_val}) # Raw value from capacitance sensor
    |> parse_parts(rest)
  end

  # 1.1.22 Raw Capacitance End sensor report
  def parse_parts(result, <<history::1, 114::7, cap_val::16, rest::binary>>) do
    result
    |> Map.merge(%{history: history, end_capacitance: cap_val}) # Raw value from capacitance sensor
    |> parse_parts(rest)
  end

  # 1.1.23 Diagnostic sensor report
  def parse_parts(result, <<history::1, 16::7, diag::32, rest::binary>>) do
    result
    |> Map.merge(%{history: history, diagnostics_report: diag})
    |> parse_parts(rest)
  end

  def parse_parts(result, <<>>), do: result

  def parse_parts(result, unparsed) do
    Map.merge(result, %{error_unparsed: Base.encode16(unparsed)})
  end


  # Define fields with human readable name and a SI unit if available.
  def fields() do
    [
      %{
        field: "hist_seq_nr",
        display: "History Number",
      },
      %{
        field: "history",
        display: "History",
      },
      %{
        field: "empty_report",
        display: "Empty Report",
      },
      %{
        field: "battery",
        display: "Battery",
        unit: "%",
      },
      %{
        field: "battery",
        display: "Battery",
        unit: "%",
      },
      %{
        field: "temperature",
        display: "Temperature",
        unit: "°C",
      },
      %{
        field: "temperature_avg",
        display: "Temperature Avg.",
        unit: "°C",
      },
      %{
        field: "humidity",
        display: "Humidity",
        unit: "%",
      },
      %{
        field: "ambient_light",
        display: "Ambient Light",
        unit: "lux",
      },
      %{
        field: "ambient_light2",
        display: "Ambient Light2",
        unit: "lux",
      },
      %{
        field: "door_closed",
        display: "Door Closed",
      },
      %{
        field: "door_alarm",
        display: "Door Alarm",
      },
      %{
        field: "tamper",
        display: "Tamper",
      },
      %{
        field: "tamper_alarm",
        display: "Tamper Alarm",
      },
      %{
        field: "flood",
        display: "Flood",
        unit: "%",
      },
      %{
        field: "flood_alarm",
        display: "Flood Alarm",
      },
      %{
        field: "foil_alarm",
        display: "Foil Alarm",
      },
    ]
  end

  def tests() do
    [
      {:parse_hex, "00058200EC", %{meta: %{frame_port: 1}},  %{hist_seq_nr: 5, history: 1, temperature: 23.6}},
      {:parse_hex, "0004066C", %{meta: %{frame_port: 1}}, %{hist_seq_nr: 4, history: 0, humidity: 54.0}},
      {:parse_hex, "00048200F7", %{meta: %{frame_port: 1}}, %{hist_seq_nr: 4, history: 1, temperature: 24.7}},
      {:parse_hex, "00030664", %{meta: %{frame_port: 1}}, %{hist_seq_nr: 3, history: 0, humidity: 50.0}},
      {:parse_hex, "00038200EC", %{meta: %{frame_port: 1}}, %{hist_seq_nr: 3, history: 1, temperature: 23.6}},
      {:parse_hex, "00020653", %{meta: %{frame_port: 1}}, %{hist_seq_nr: 2, history: 0, humidity: 41.5}},
      {:parse_hex, "00028200F6", %{meta: %{frame_port: 1}}, %{hist_seq_nr: 2, history: 1, temperature: 24.6}},
      {:parse_hex, "00010654", %{meta: %{frame_port: 1}}, %{hist_seq_nr: 1, history: 0, humidity: 42.0}},
      {:parse_hex, "00018200EC", %{meta: %{frame_port: 1}}, %{hist_seq_nr: 1, history: 1, temperature: 23.6}},
      {:parse_hex, "00008200F6", %{meta: %{frame_port: 1}}, %{hist_seq_nr: 0, history: 1, temperature: 24.6}},
      {:parse_hex, "FFFF00", %{meta: %{frame_port: 1}}, %{empty_report: true, history: 0}},
      {:parse_hex, "FFFF0900", %{meta: %{frame_port: 1}}, %{door_closed: 0, history: 0}},
      {:parse_hex, "FFFF0200ED", %{meta: %{frame_port: 1}}, %{history: 0, temperature: 23.7}},
      {:parse_hex, "FFFF0652", %{meta: %{frame_port: 1}}, %{history: 0, humidity: 41.0}},
      {:parse_hex, "FFFF0B00", %{meta: %{frame_port: 1}}, %{history: 0, tamper: 0}},
    ]
  end
end
