defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Comtac KLAX device.

  # Changelog
  #   2019-02-13 [nk]: Initial Version by Niklas, registers and interval fixed.
  #   2019-03-04 [jb]: Skipping invalid backdated values when value==0.0; Added mode "Logarex"
  #   2019-03-05 [jb]: Register values now signed. Added fields().
  #   2019-03-27 [jb]: Logging unknown binaries in _parse_payload/2.
  #   2019-05-13 [jb]: Added interpolation feature. Added registers with full OBIS codes.
  #   2019-05-14 [jb]: Rounding all values as float to a precision of 3 decimals.


  #----- Configuration

  # Needs to be 4 distinct values!
  # Needs to be as configured on devices!
  # Previous configuration: ["1_8_0", "2_8_0", "1_29_0", "2_29_0"]
  def registers(), do: ["1_8_0", "2_8_0", "1_29_0", "2_29_0"]
  # When full obis for registers is needed
  def registers(:full_obis), do: ["1-0:1.8.0", "1-0:2.8.0", "1-0:1.29.0", "1-0:2.29.0"]

  # Default configuration: 15 Minutes
  # Needs to be as configured on devices!
  # Minimum 1 Minute
  # Maximum 50000 minutes
  def interval_minutes(), do: 15

  # Flag if interpolated values for 0:00, 0:15, 0:30, 0:45, ... should be calculated
  # Default: true
  def interpolate?(), do: true
  # Minutes between interpolated values
  # Default: 15
  def interpolate_minutes(), do: 15

  # Name of timezone.
  # Default: "Europe/Berlin"
  def timezone(), do: "Europe/Berlin"


  #----- Implementation

  # Startup Message on Port 100
  def parse(<<version::8, connection_test::1, registers_configured::1, mode::2, battery::4, interval::16>>, %{meta: %{frame_port: 100}} = _meta) do
    mode = _mode(mode)
    %{
      version: version,
      connection_test: connection_test == 1,
      registers_configured: registers_configured == 1,
      mode: mode,
      battery: battery * 10,
      interval: interval
    }
  end

  # Startup Message on Port 101
  def parse(<<version::8, connection_test::1, registers_configured::1, mode::2, battery::4, main::8, minor::8>>, %{meta: %{frame_port: 101}} = _meta) do
    mode = _mode(mode)
    %{
      version: version,
      connection_test: connection_test == 1,
      registers_configured: registers_configured == 1,
      mode: mode,
      battery: battery * 10,
      app_version: "#{main}.#{minor}"
    }
  end

  # Periodic message containing four measurement of two registers.
  def parse(<<version::8, connection_test::1, registers_configured::1, mode::2, battery::4, message_index::8, message_num::4, message_of::4, registers::binary>>, %{meta: %{frame_port: 103}} = _meta) do
    mode = _mode(mode)

    (for <<x::8, y::8, z::8 <- registers >>, do: "1-0:#{x}.#{y}.#{z}")
    |> Enum.with_index(1)
    |> Enum.map(fn {name, index} -> {"register_#{index}", name} end) # TODO if message_of > 1, index must be offseted
    |> Map.new
    |> Map.merge(
         %{
           version: version,
           connection_test: connection_test == 1,
           registers_configured: registers_configured == 1,
           mode: mode,
           battery: battery * 10,
           message_num: message_num,
           message_of: message_of,
           message_index: message_index
         }
       )
  end

  def parse(<<version::8, connection_test::1, registers_configured::1, mode::2, battery::4, active_filters::binary-1, registers::binary>>, %{meta: %{frame_port: 104}} = _meta) do
    mode = _mode(mode)

    <<_::4, reg_4::1, reg_3::1, reg_2::1, reg_1::1>> = active_filters

    (for <<x::8, y::8, z::8 <- registers >>, do: "1-0:#{x}.#{y}.#{z}")
    |> Enum.with_index(1)
    |> Enum.map(fn {name, index} -> {"register_#{index}", name} end)
    |> Map.new
    |> Map.merge(
         %{
           version: version,
           connection_test: connection_test == 1,
           registers_configured: registers_configured == 1,
           mode: mode,
           battery: battery * 10,
           register_1_set: reg_1 == 1,
           register_2_set: reg_2 == 1,
           register_3_set: reg_3 == 1,
           register_4_set: reg_4 == 1,
         }
       )
  end

  def parse(<<_version::8, _connection_test::1, _registers_configured::1, _mode::2, battery::4, _message_index::8, _message_num::4, _message_of::4, payload::binary>>, %{meta: %{frame_port: 3}} = meta) do
    _parse_payload(payload, meta)
    ++
    [
      {
        %{battery: battery * 10},
        [measured_at: meta[:transceived_at]]
      }
    ]
  end

  def parse(payload, meta) do
    Logger.info("Unhandled meta.frame_port: #{inspect get_in(meta, [:meta, :frame_port])} with payload #{inspect payload}")
    []
  end

  defp _parse_payload(<<1, data::binary-34, rest::binary>>, meta) do
    <<pos_2_valid::1, pos_2_selector::2, pos_2_active::1, pos_1_valid::1, pos_1_selector::2, pos_1_active::1, unit_2::4, unit_1::4, content::binary>> = data

    <<
      pos_1_now::signed-32,
      pos_1_minus_1::signed-32,
      pos_1_minus_2::signed-32,
      pos_1_minus_3::signed-32,
      pos_2_now::signed-32,
      pos_2_minus_1::signed-32,
      pos_2_minus_2::signed-32,
      pos_2_minus_3::signed-32,
    >> = content

    list_pos1 = if pos_1_active == 1 && pos_1_valid == 1 do # TODO: Warn if not valid
       {unit, scaler} = _map_unit(unit_1)
       obis = Enum.at(registers(), pos_1_selector)
       obis_full = Enum.at(registers(:full_obis), pos_1_selector)
       [
         # Always adding the first value, because the _valid flag is set for it.
         {
           %{
             "obis" => obis_full,
             obis => round_as_float(pos_1_now * scaler),
             obis_full => round_as_float(pos_1_now * scaler),
             "unit" => unit
           },
           [measured_at: meta[:transceived_at]]
         },
       ]
       |> _add_valid_reading(
            [obis_full, obis],
            pos_1_minus_1 * scaler,
            unit,
            Timex.shift(meta[:transceived_at], minutes: -1 * interval_minutes())
          )
       |> _add_valid_reading(
            [obis_full, obis],
            pos_1_minus_2 * scaler,
            unit,
            Timex.shift(meta[:transceived_at], minutes: -1 * interval_minutes() * 2)
          )
       |> _add_valid_reading(
            [obis_full, obis],
            pos_1_minus_3 * scaler,
            unit,
            Timex.shift(meta[:transceived_at], minutes: -1 * interval_minutes() * 3)
          )
       |> build_missing(meta)
    else
      []
    end

    list_pos2 = if pos_2_active == 1 && pos_2_valid == 1 do # TODO: Warn if not valid
      {unit, scaler} = _map_unit(unit_2)
      obis = Enum.at(registers(), pos_2_selector)
      obis_full = Enum.at(registers(:full_obis), pos_2_selector)
      [
       # Always adding the first value, because the _valid flag is set for it.
       {
         %{
           "obis" => obis_full,
           obis => round_as_float(pos_2_now * scaler),
           obis_full => round_as_float(pos_2_now * scaler),
           "unit" => unit
         },
         [measured_at: meta[:transceived_at]]
       },
      ]
      |> _add_valid_reading(
          [obis_full, obis],
          pos_2_minus_1 * scaler,
          unit,
          Timex.shift(meta[:transceived_at], minutes: -1 * interval_minutes())
        )
      |> _add_valid_reading(
          [obis_full, obis],
          pos_2_minus_2 * scaler,
          unit,
          Timex.shift(meta[:transceived_at], minutes: -1 * interval_minutes() * 2)
        )
      |> _add_valid_reading(
          [obis_full, obis],
          pos_2_minus_3 * scaler,
          unit,
          Timex.shift(meta[:transceived_at], minutes: -1 * interval_minutes() * 3)
        )
      |> build_missing(meta)
    else
      []
    end

    list = list_pos1 ++ list_pos2

    case rest do
      <<>> -> list
      _ -> _parse_payload(rest, meta) ++ list
    end
  end

  defp _parse_payload(<<2, _data::binary-19, rest::binary>>, meta) do
    case rest do
      <<>> -> []
      _ -> _parse_payload(rest, meta)
    end
  end

  defp _parse_payload(<<3, server_id::binary-10, rest::binary>>, meta) do
    list =
      [ {
        %{
          server_id: Base.encode16(server_id)
        },
        [measured_at: meta[:transceived_at]]
      }
      ]
    case rest do
      <<>> -> list
      _ -> _parse_payload(rest, meta) ++ list
    end
  end
  defp _parse_payload(unknown_binary, _meta) do
    Logger.info("Unhandled payload binary part: #{inspect unknown_binary}")
    []
  end


  defp build_missing([{%{"obis" => obis, "unit" => unit} = current_data, current_meta} | _] = current_readings, meta) do
    if interpolate?() do

      current_value = Map.fetch!(current_data, obis)
      current_measured_at = Keyword.fetch!(current_meta, :measured_at)

      case get_last_reading(meta, [obis: obis, unit: unit]) do
        %{data: %{"obis" => ^obis} = last_data, measured_at: last_measured_at} ->
          last_value = Map.fetch!(last_data, obis)

          missing_readings = [
            {%{value: last_value}, [measured_at: last_measured_at]},
            {%{value: current_value}, [measured_at: current_measured_at]},
          ]
          |> TimeSeries.fill_gaps(
            fn datetime_a, datetime_b ->
              # Calculate all tuples with x=nil between a and b where a value should be interpolated
              interval = Timex.Interval.new(
                from: datetime_a |> Timex.to_datetime(timezone()) |> datetime_add_to_multiple_of_minutes(interpolate_minutes()),
                until: datetime_b,
                left_open: false,
                step: [minutes: interpolate_minutes()]
              )
              Enum.map(interval, &({nil, [measured_at: &1]}))
            end,
            :linear,
            x_access_path: [Access.elem(1), :measured_at],
            y_access_path: [Access.elem(0)],
            x_pre_calc_fun: &Timex.to_unix/1,
            x_post_calc_fun: &Timex.to_datetime/1,
            y_pre_calc_fun: fn %{value: value} -> value end,
            y_post_calc_fun: &(%{value: &1, _interpolated: true})
          )
          |> Enum.filter(fn ({data, _meta}) -> Map.get(data, :_interpolated, false) end)
          |> Enum.map(fn {%{value: value}, reading_meta} ->
            {
              %{
                "obis" => obis,
                obis => round_as_float(value),
                "unit" => unit,
              },
              reading_meta
            }
          end)

          current_readings ++ missing_readings

        nil ->
          current_readings

        invalid_prev_reading ->
          Logger.warn("Could not build_missing() because of invalid previous reading: #{inspect invalid_prev_reading}")
          current_readings
      end

    else
      current_readings
    end
  end
  defp build_missing(current_readings, _last_reading_query) do
    Logger.warn("Could not build_missing() because of invalid current_readings")
    current_readings
  end


  # Will add a reading to list when value is not zero, or skip that reading
  defp _add_valid_reading(list, _obis, 0.0, _unit, _measured_at), do: list
  defp _add_valid_reading(list, _obis, 0, _unit, _measured_at), do: list
  defp _add_valid_reading(list, [obis_full, obis], value, unit, measured_at) do
    list ++ [
      {
        %{
          "obis" => obis_full,
          obis => round_as_float(value),
          obis_full => round_as_float(value),
          "unit" => unit,
        },
        [measured_at: measured_at]
      }
    ]
  end

  defp _map_unit(0), do: {"NDEF", 1}
  defp _map_unit(1), do: {"kWh", 0.001}
  defp _map_unit(2), do: {"kW", 0.001}
  defp _map_unit(3), do: {"V", 1}
  defp _map_unit(4), do: {"A", 1}
  defp _map_unit(5), do: {"Hz", 1}

  defp _mode(mode) do
    case mode do
      0 -> "SML"
      1 -> "IEC 62056-21 Mode B"
      2 -> "IEC 62056-21 Mode C"
      3 -> "Logarex"
      _ -> "unknown mode: #{inspect mode}"
    end
  end

  # Will shift 2019-04-20 12:34:56 to   2019-04-20 12:45:00
  defp datetime_add_to_multiple_of_minutes(%DateTime{} = dt, minutes) do
    minute_seconds = minutes * 60
    rem = rem(DateTime.to_unix(dt), minute_seconds)
    Timex.shift(dt, seconds: (minute_seconds - rem))
  end

  defp round_as_float(value) do
    Float.round(value / 1, 3)
  end

  def fields() do
    [
      %{
        "field" => "battery",
        "display" => "Battery",
        "unit" => "%",
      },
      %{
        "field" => "connection_test",
        "display" => "ConnectionTest",
      },
      %{
        "field" => "interval",
        "display" => "Interval",
        "unit" => "minutes",
      },
      %{
        "field" => "mode",
        "display" => "Mode",
      },
      %{
        "field" => "registers_configured",
        "display" => "Registers Configured",
      },
      %{
        "field" => "version",
        "display" => "Version",
      },
      %{
        "field" => "app_version",
        "display" => "App Version",
      },
    ] ++ Enum.map(registers(), fn(register) ->
      %{
        "field" => "#{register}",
        "display" => "OBIS #{register}",
      }
    end)
  end


  #--------- Tests


  def tests() do
    [
      # beim start, config
      {
        :parse_hex,
        "00490001",
        %{meta: %{frame_port: 100}},
        %{
          battery: 90,
          connection_test: false,
          interval: 1,
          mode: "SML",
          registers_configured: true,
          version: 0
        },
      },


      # beim start, info
      {
        :parse_hex,
        "00490002",
        %{meta: %{frame_port: 101}},
        %{
          app_version: "0.2",
          battery: 90,
          connection_test: false,
          mode: "SML",
          registers_configured: true,
          version: 0
        },
      },

      # bei start, register search
      {
        :parse_hex,
        "00490F010800020800011D00021D00",
        %{meta: %{frame_port: 104}},
        %{
          :battery => 90,
          :connection_test => false,
          :mode => "SML",
          :register_1_set => true,
          :register_2_set => true,
          :register_3_set => true,
          :register_4_set => true,
          :registers_configured => true,
          :version => 0,
          "register_1" => "1-0:1.8.0",
          "register_2" => "1-0:2.8.0",
          "register_3" => "1-0:1.29.0",
          "register_4" => "1-0:2.29.0"
        },
      },


      # bei start, register set antwort auf DOWN
      {
        :parse_hex,
        "00490711010800020800",
        %{meta: %{frame_port: 103}},
        %{
          :battery => 90,
          :connection_test => false,
          :message_index => 7,
          :message_num => 1,
          :message_of => 1,
          :mode => "SML",
          :registers_configured => true,
          :version => 0,
          "register_1" => "1-0:1.8.0",
          "register_2" => "1-0:2.8.0"
        },
      },


      # Regelmäßige Nachricht
      {
        :parse_hex,
        "00493511030A01495452000346848001B911000105B8000105B8000105B8000105B8000007D0000007D0000007D0000007D00175000000000000000000000000000000000000000000000000000000000000000000",
        %{meta: %{frame_port: 3}, transceived_at: test_datetime("2019-01-01T12:00:00Z")},
        [
          {%{"obis" => "1-0:1.8.0", "1-0:1.8.0" => 67.0, "unit" => "kWh", "1_8_0" => 67.0}, [measured_at: test_datetime("2019-01-01T12:00:00Z")]},
          {%{"obis" => "1-0:1.8.0", "1-0:1.8.0" => 67.0, "unit" => "kWh", "1_8_0" => 67.0}, [measured_at: test_datetime("2019-01-01T11:45:00Z")]},
          {%{"obis" => "1-0:1.8.0", "1-0:1.8.0" => 67.0, "unit" => "kWh", "1_8_0" => 67.0}, [measured_at: test_datetime("2019-01-01T11:30:00Z")]},
          {%{"obis" => "1-0:1.8.0", "1-0:1.8.0" => 67.0, "unit" => "kWh", "1_8_0" => 67.0}, [measured_at: test_datetime("2019-01-01T11:15:00Z")]},
          {%{"obis" => "1-0:2.8.0", "1-0:2.8.0" => 2.0, "unit" => "kWh", "2_8_0" => 2.0}, [measured_at: test_datetime("2019-01-01T12:00:00Z")]},
          {%{"obis" => "1-0:2.8.0", "1-0:2.8.0" => 2.0, "unit" => "kWh", "2_8_0" => 2.0}, [measured_at: test_datetime("2019-01-01T11:45:00Z")]},
          {%{"obis" => "1-0:2.8.0", "1-0:2.8.0" => 2.0, "unit" => "kWh", "2_8_0" => 2.0}, [measured_at: test_datetime("2019-01-01T11:30:00Z")]},
          {%{"obis" => "1-0:2.8.0", "1-0:2.8.0" => 2.0, "unit" => "kWh", "2_8_0" => 2.0}, [measured_at: test_datetime("2019-01-01T11:15:00Z")]},
          {%{server_id: "0A014954520003468480"}, [measured_at: test_datetime("2019-01-01T12:00:00Z")]},
          {%{battery: 90}, [measured_at: test_datetime("2019-01-01T12:00:00Z")]}
        ],
      },

      # Nachricht mit Fehler beim vierten 1.8.0 Messwert
      {
        :parse_hex,
        "004AE41103090149534B00041A1C260109010028C4B20028C4850028C4610000000000000000000000000000000000000000",
        %{meta: %{frame_port: 3}, transceived_at: test_datetime("2019-01-01T12:00:00Z")},
        [
          {%{"obis" => "1-0:1.8.0", "1-0:1.8.0" => 2671.794, "unit" => "kWh", "1_8_0" => 2671.794}, [measured_at: test_datetime("2019-01-01T12:00:00Z")]},
          {%{"obis" => "1-0:1.8.0", "1-0:1.8.0" => 2671.749, "unit" => "kWh", "1_8_0" => 2671.749}, [measured_at: test_datetime("2019-01-01T11:45:00Z")]},
          {%{"obis" => "1-0:1.8.0", "1-0:1.8.0" => 2671.713, "unit" => "kWh", "1_8_0" => 2671.713}, [measured_at: test_datetime("2019-01-01T11:30:00Z")]},
          # This value is omitted, because its faulty. {%{"1_8_0" => 0.0, "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01T11:15:00Z")]},
          {%{server_id: "090149534B00041A1C26"}, [measured_at: test_datetime("2019-01-01T12:00:00Z")]},
          {%{battery: 100}, [measured_at: test_datetime("2019-01-01T12:00:00Z")]}
        ]
      },

      # Unhandled payload binary part
      {
        :parse_hex,
        "004A71110306454D48010E15C1E250013901001A9FE4001A9FE40000000000000000000000000000000000000000000000000175001337",
        %{meta: %{frame_port: 3}, transceived_at: test_datetime("2019-01-01T12:00:00Z")},
        [
          {%{"obis" => "1-0:1.8.0", "1-0:1.8.0" => 1744.868, "unit" => "kWh", "1_8_0" => 1744.868}, [measured_at: test_datetime("2019-01-01T12:00:00Z")]},
          {%{"obis" => "1-0:1.8.0", "1-0:1.8.0" => 1744.868, "unit" => "kWh", "1_8_0" => 1744.868}, [measured_at: test_datetime("2019-01-01T11:45:00Z")]},
          {%{server_id: "06454D48010E15C1E250"}, [measured_at: test_datetime("2019-01-01 12:00:00Z")]},
          {%{battery: 100}, [measured_at: test_datetime("2019-01-01T12:00:00Z")]}
        ]
      },


      # Regelmäßige Nachricht mit Interpolation auf 15 Minuten seit dem letzten Messwert
      {
        :parse_hex,
        "00493511030A01495452000346848001B911000105B8000105B8000105B8000105B8000007D0000007D0000007D0000007D00175000000000000000000000000000000000000000000000000000000000000000000",
        %{
          meta: %{frame_port: 3},
          transceived_at: test_datetime("2019-01-01T12:34:56Z"),
          _last_reading_map: %{
            [obis: "1-0:1.8.0", unit: "kWh"] =>
              %{measured_at: test_datetime("2019-01-01T11:34:56Z"), data: %{"obis" => "1-0:1.8.0", "1-0:1.8.0" => 65.0, "unit" => "kWh"}},
            [obis: "1-0:2.8.0", unit: "kWh"] =>
             %{measured_at: test_datetime("2019-01-01T11:34:56Z"), data: %{"obis" => "1-0:2.8.0", "1-0:2.8.0" => 0.0, "unit" => "kWh"}},
          },
        },
        [
          # Current 1.8.0
          {%{"1-0:1.8.0" => 67.0, "obis" => "1-0:1.8.0", "unit" => "kWh", "1_8_0" => 67.0}, [measured_at: test_datetime("2019-01-01 12:34:56Z")]},
          {%{"1-0:1.8.0" => 67.0, "obis" => "1-0:1.8.0", "unit" => "kWh", "1_8_0" => 67.0}, [measured_at: test_datetime("2019-01-01 12:19:56Z")]},
          {%{"1-0:1.8.0" => 67.0, "obis" => "1-0:1.8.0", "unit" => "kWh", "1_8_0" => 67.0}, [measured_at: test_datetime("2019-01-01 12:04:56Z")]},
          {%{"1-0:1.8.0" => 67.0, "obis" => "1-0:1.8.0", "unit" => "kWh", "1_8_0" => 67.0}, [measured_at: test_datetime("2019-01-01 11:49:56Z")]},

          # Calculated 1.8.0
          {%{"1-0:1.8.0" => 65.336, "obis" => "1-0:1.8.0", "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01 11:45:00Z")]},
          {%{"1-0:1.8.0" => 65.836, "obis" => "1-0:1.8.0", "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01 12:00:00Z")]},
          {%{"1-0:1.8.0" => 66.336, "obis" => "1-0:1.8.0", "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01 12:15:00Z")]},
          {%{"1-0:1.8.0" => 66.836, "obis" => "1-0:1.8.0", "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01 12:30:00Z")]},

          # Current 2.8.0
          {%{"1-0:2.8.0" => 2.0, "obis" => "1-0:2.8.0", "unit" => "kWh", "2_8_0" => 2.0}, [measured_at: test_datetime("2019-01-01 12:34:56Z")]},
          {%{"1-0:2.8.0" => 2.0, "obis" => "1-0:2.8.0", "unit" => "kWh", "2_8_0" => 2.0}, [measured_at: test_datetime("2019-01-01 12:19:56Z")]},
          {%{"1-0:2.8.0" => 2.0, "obis" => "1-0:2.8.0", "unit" => "kWh", "2_8_0" => 2.0}, [measured_at: test_datetime("2019-01-01 12:04:56Z")]},
          {%{"1-0:2.8.0" => 2.0, "obis" => "1-0:2.8.0", "unit" => "kWh", "2_8_0" => 2.0}, [measured_at: test_datetime("2019-01-01 11:49:56Z")]},

          # Calculated 2.8.0
          {%{"1-0:2.8.0" => 0.336, "obis" => "1-0:2.8.0", "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01 11:45:00Z")]},
          {%{"1-0:2.8.0" => 0.836, "obis" => "1-0:2.8.0", "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01 12:00:00Z")]},
          {%{"1-0:2.8.0" => 1.336, "obis" => "1-0:2.8.0", "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01 12:15:00Z")]},
          {%{"1-0:2.8.0" => 1.836, "obis" => "1-0:2.8.0", "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01 12:30:00Z")]},

          {%{server_id: "0A014954520003468480"}, [measured_at: test_datetime("2019-01-01 12:34:56Z")]},
          {%{battery: 90}, [measured_at: test_datetime("2019-01-01 12:34:56Z")]}
        ]
      },
    ]
  end

  # Helper for testing
  defp test_datetime(iso8601) do
    {:ok, datetime, _} = DateTime.from_iso8601(iso8601)
    datetime
  end

end
