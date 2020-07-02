defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # Parser for device Sensative Strips Comfort.
  # Link: https://sensative.com/strips/
  # Docs: https://sensative.com/sensors/strips-lora-sensors/sensative-strips-lora-resource-center/
  #
  # Changelog:
  #   2019-09-10 [jb]: Initial implementation according to "Sensative_LoRa-Strips-Manual-Alpha-2.pdf"
  #   2019-11-05 [jb]: Fixed order of temperature/humidity in 1.1.17, 1.1.18 and 1.1.19.
  #   2020-07-02 [jb]: Updated payload to Strips-MsLoRa-DataFrames-3.odt, ignoring frame_port=2 for now.
  #

  def parse(<<hist_seq_nr::16, rest::binary>>, %{meta: %{frame_port: 1}}) do
    hist_seq_nr
    |> case  do
      65535 -> %{}
      _ -> %{hist_seq_nr: hist_seq_nr}
    end
    |> parse_parts(rest)
  end
  def parse(_payload, %{meta: %{frame_port: 2}}) do
    %{skipping_history_report: 1}
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  # 1.1.1 Empty report
  def parse_parts(result, <<_history::1, 0::7, rest::binary>>) do
    result
    |> Map.merge(%{empty_report: true})
    |> parse_parts(rest)
  end

  # 1.1.2 Battery report
  def parse_parts(result, <<_history::1, 1::7, battery::8, rest::binary>>) do
    result
    |> Map.merge(%{battery: battery}) # Percent
    |> parse_parts(rest)
  end

  # 1.1.3 Temperature report
  def parse_parts(result, <<_history::1, 2::7, temp::signed-16, rest::binary>>) do
    result
    |> Map.merge(%{temperature: temp/10}) # Celsius
    |> parse_parts(rest)
  end

  # 1.1.4 Temperature level alarm
  def parse_parts(result, <<_history::1, 3::7, _spare::6, low_alarm::1, high_alarm::1, rest::binary>>) do
    result
    |> Map.merge(%{temperature_low_alarm: low_alarm, temperature_high_alarm: high_alarm})
    |> parse_parts(rest)
  end

  # 1.1.5 Average Temperature report
  def parse_parts(result, <<_history::1, 4::7, avg_temp::signed-16, rest::binary>>) do
    result
    |> Map.merge(%{temperature_avg: avg_temp})
    |> parse_parts(rest)
  end

  # 1.1.6 Average Temperature level alarm
  def parse_parts(result, <<_history::1, 5::7, _spare::6, low_alarm::1, high_alarm::1, rest::binary>>) do
    result
    |> Map.merge(%{temperature_avg_low_alarm: low_alarm, temperature_avg_high_alarm: high_alarm})
    |> parse_parts(rest)
  end

  # 1.1.7 Relative Humidity Report
  def parse_parts(result, <<_history::1, 6::7, humidity::8, rest::binary>>) do
    result
    |> Map.merge(%{humidity: humidity/2}) # %
    |> parse_parts(rest)
  end

  # 1.1.8 Ambient light report
  def parse_parts(result, <<_history::1, 7::7, ambient::16, rest::binary>>) do
    result
    |> Map.merge(%{ambient_light: ambient}) # Lux
    |> parse_parts(rest)
  end

  # 1.1.9 Second Ambient light report
  def parse_parts(result, <<_history::1, 8::7, ambient::16, rest::binary>>) do
    result
    |> Map.merge(%{ambient_light2: ambient})
    |> parse_parts(rest)
  end

  # 1.1.10 Door report
  def parse_parts(result, <<_history::1, 9::7, _::7, door_closed::1, rest::binary>>) do
    result
    |> Map.merge(%{door_closed: door_closed})
    |> parse_parts(rest)
  end

  # 1.1.11 Door alarm
  def parse_parts(result, <<_history::1, 10::7, _::7, door_alarm::1, rest::binary>>) do
    result
    |> Map.merge(%{door_alarm: door_alarm})
    |> parse_parts(rest)
  end

  # 1.1.12 Tamper switch report
  def parse_parts(result, <<_history::1, 11::7, _::7, tamper::1, rest::binary>>) do
    result
    |> Map.merge(%{tamper: tamper})
    |> parse_parts(rest)
  end

  # 1.1.13 Tamper alarm
  # Note: Tamper Alarm active when door is closed and tamper switch is activated
  def parse_parts(result, <<_history::1, 12::7, _::7, tamper_alarm::1, rest::binary>>) do
    result
    |> Map.merge(%{tamper_alarm: tamper_alarm})
    |> parse_parts(rest)
  end

  # 1.1.14 Flood sensor level report
  def parse_parts(result, <<_history::1, 13::7, flood::8, rest::binary>>) do
    result
    |> Map.merge(%{flood: flood}) # percent
    |> parse_parts(rest)
  end

  # 1.1.15 Flood alarm
  def parse_parts(result, <<_history::1, 14::7, _::7, flood_alarm::1, rest::binary>>) do
    result
    |> Map.merge(%{flood_alarm: flood_alarm})
    |> parse_parts(rest)
  end

  # 1.1.16 Foil alarm
  def parse_parts(result, <<_history::1, 15::7, _::7, foil_alarm::1, rest::binary>>) do
    result
    |> Map.merge(%{foil_alarm: foil_alarm})
    |> parse_parts(rest)
  end

  # UserSwitch1Alarm, 1 byte digital
  def parse_parts(result, <<_history::1, 16::7, _::7, alarm::1, rest::binary>>) do
    result
    |> Map.merge(%{user_switch_alarm1: alarm})
    |> parse_parts(rest)
  end

  # DoorCountReport, 2 byte analog
  def parse_parts(result, <<_history::1, 17::7, count::16, rest::binary>>) do
    result
    |> Map.merge(%{door_count: count})
    |> parse_parts(rest)
  end

  # PresenceReport, 1 byte digital
  def parse_parts(result, <<_history::1, 18::7, _::7, presence::1, rest::binary>>) do
    result
    |> Map.merge(%{presence: presence})
    |> parse_parts(rest)
  end

  # IRProximityReport
  def parse_parts(result, <<_history::1, 19::7, proximity::16, rest::binary>>) do
    result
    |> Map.merge(%{ir_proximity: proximity, ir_power: :high}) # dont know
    |> parse_parts(rest)
  end

  # IRProximityReport, low power
  def parse_parts(result, <<_history::1, 20::7, proximity::16, rest::binary>>) do
    result
    |> Map.merge(%{ir_proximity: proximity, ir_power: :low}) # dont know
    |> parse_parts(rest)
  end

  # IRCloseProximityReport, something very close to presence sensor
  def parse_parts(result, <<_history::1, 21::7, _::7, presence::1, rest::binary>>) do
    result
    |> Map.merge(%{ir_proximity_close: presence})
    |> parse_parts(rest)
  end

  # DisinfectAlarm
  def parse_parts(result, <<_history::1, 22::7, state::8, rest::binary>>) do
    state_name = case state do
      0 -> :dirty
      1 -> :occupied
      2 -> :cleaning
      3 -> :clean
      _ -> "unknown_#{state}"
    end
    result
    |> Map.merge(%{disinfect_state: state_name})
    |> parse_parts(rest)
  end


  #		case 22: // DisinfectAlarm
  #		  target.disinfectAlarm = {};
  #		  target.disinfectAlarm.value = bytes[pos++];
  #		  if (target.disinfectAlarm.value == 0) target.disinfectAlarm.state='dirty';
  #		  if (target.disinfectAlarm.value == 1) target.disinfectAlarm.state='occupied';
  #		  if (target.disinfectAlarm.value == 2) target.disinfectAlarm.state='cleaning';
  #		  if (target.disinfectAlarm.value == 3) target.disinfectAlarm.state='clean';
  #		  break;


  # 1.1.17 Combined Temperature and Humidity Report
  def parse_parts(result, <<_history::1, 80::7, humidity::8, temp::16, rest::binary>>) do
    result
    |> Map.merge(%{temperature: temp/10, humidity: humidity/2})
    |> parse_parts(rest)
  end

  # 1.1.18 Combined Average Temperature and Humidity Report
  def parse_parts(result, <<_history::1, 81::7, humidity::8, temp::16, rest::binary>>) do
    result
    |> Map.merge(%{temperature_avg: temp/10, humidity_avg: humidity/2})
    |> parse_parts(rest)
  end

  # 1.1.19 Combined Temperature and Door Report
  def parse_parts(result, <<_history::1, 82::7, _::7, door::1, temp::16, rest::binary>>) do
    result
    |> Map.merge(%{temperature_avg: temp/10, door_closed: door})
    |> parse_parts(rest)
  end

  # Status report
  def parse_parts(result, <<_history::1, 110::7, build_mod::1, build_id::31, status_info::32, rest::binary>>) do
    result
    |> Map.merge(%{
      build_id_modified: build_mod,
      build_id: build_id,
      status_info: status_info,
    })
    |> parse_parts(rest)
  end

  # 1.1.20 Raw Capacitance Flood sensor report
  def parse_parts(result, <<_history::1, 112::7, cap_val::16, rest::binary>>) do
    result
    |> Map.merge(%{flood_capacitance: cap_val}) # Raw value from capacitance sensor
    |> parse_parts(rest)
  end

  # 1.1.21 Raw Capacitance Pad sensor report
  def parse_parts(result, <<_history::1, 113::7, cap_val::16, rest::binary>>) do
    result
    |> Map.merge(%{pad_capacitance: cap_val}) # Raw value from capacitance sensor
    |> parse_parts(rest)
  end

  # 1.1.22 Raw Capacitance End sensor report
  def parse_parts(result, <<_history::1, 114::7, cap_val::16, rest::binary>>) do
    result
    |> Map.merge(%{end_capacitance: cap_val}) # Raw value from capacitance sensor
    |> parse_parts(rest)
  end

#  # 1.1.23 Diagnostic sensor report
#  def parse_parts(result, <<_history::1, 16::7, diag::32, rest::binary>>) do
#    result
#    |> Map.merge(%{diagnostics_report: diag})
#    |> parse_parts(rest)
#  end

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
      {:parse_hex, "00058200EC", %{meta: %{frame_port: 1}},  %{hist_seq_nr: 5, temperature: 23.6}},
      {:parse_hex, "0004066C", %{meta: %{frame_port: 1}}, %{hist_seq_nr: 4, humidity: 54.0}},
      {:parse_hex, "00048200F7", %{meta: %{frame_port: 1}}, %{hist_seq_nr: 4, temperature: 24.7}},
      {:parse_hex, "00030664", %{meta: %{frame_port: 1}}, %{hist_seq_nr: 3, humidity: 50.0}},
      {:parse_hex, "00038200EC", %{meta: %{frame_port: 1}}, %{hist_seq_nr: 3, temperature: 23.6}},
      {:parse_hex, "00020653", %{meta: %{frame_port: 1}}, %{hist_seq_nr: 2, humidity: 41.5}},
      {:parse_hex, "00028200F6", %{meta: %{frame_port: 1}}, %{hist_seq_nr: 2, temperature: 24.6}},
      {:parse_hex, "00010654", %{meta: %{frame_port: 1}}, %{hist_seq_nr: 1, humidity: 42.0}},
      {:parse_hex, "00018200EC", %{meta: %{frame_port: 1}}, %{hist_seq_nr: 1, temperature: 23.6}},
      {:parse_hex, "00008200F6", %{meta: %{frame_port: 1}}, %{hist_seq_nr: 0, temperature: 24.6}},
      {:parse_hex, "FFFF00", %{meta: %{frame_port: 1}}, %{empty_report: true}},
      {:parse_hex, "FFFF0900", %{meta: %{frame_port: 1}}, %{door_closed: 0}},
      {:parse_hex, "FFFF0200ED", %{meta: %{frame_port: 1}}, %{temperature: 23.7}},
      {:parse_hex, "FFFF0652", %{meta: %{frame_port: 1}}, %{humidity: 41.0}},
      {:parse_hex, "FFFF0B00", %{meta: %{frame_port: 1}}, %{tamper: 0}},
      {:parse_hex, "FFFF0163070000516500C1", %{meta: %{frame_port: 1}}, %{
        ambient_light: 0,
        battery: 99,
        humidity_avg: 50.5,
        temperature_avg: 19.3
      }},

      # Real payloads
      {:parse_hex, "FFFF 0B01", %{meta: %{frame_port: 1}}, %{tamper: 1}}, # door closed
      {:parse_hex, "FFFF 0B00", %{meta: %{frame_port: 1}}, %{tamper: 0}}, # door open
      {:parse_hex, "FFFF 0901", %{meta: %{frame_port: 1}}, %{door_closed: 1}}, # door closed
      {:parse_hex, "FFFF 0900", %{meta: %{frame_port: 1}}, %{door_closed: 0}}, # door open

      # Unparsed
      {:parse_hex, "FFFF 6E 051D0F2604000000", %{meta: %{frame_port: 1}}, %{
        build_id: 85790502,
        build_id_modified: 0,
        status_info: 67108864
      }},
    ]
  end
end
