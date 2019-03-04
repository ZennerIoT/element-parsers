defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Comtac KLAX device.

  # Changelog
  #   2019-02-13 [nk]: Initial Version by Niklas, registers and interval fixed.
  #   2019-03-04 [jb]: Skipping invalid backdated values when value==0.0; Added mode "Logarex"


  #----- Configuration

  # Needs to be 4 distinct values!
  # Needs to be as configured on devices!
  # Default configuration: ["1_8_0", "2_8_0", "1_29_0", "2_29_0"]
  def registers(), do: ["1_8_0", "2_8_0", "1_29_0", "2_29_0"]

  # Default configuration: 15 Minutes
  # Needs to be as configured on devices!
  # Minimum 1 Minute
  # Maximum 50000 minutes
  def interval_minutes(), do: 15


  #----- Implementation

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

  def parse(<<version::8, connection_test::1, registers_configured::1, mode::2, battery::4, message_index::8, message_num::4, message_of::4, registers::binary>>, %{meta: %{frame_port: 103}} = _meta) do
    mode = _mode(mode)

    (for <<x::8, y::8, z::8 <- registers >>, do: "#{x}.#{y}.#{z}")
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

    (for <<x::8, y::8, z::8 <- registers >>, do: "#{x}.#{y}.#{z}")
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

    <<pos_1_now::32, pos_1_minus_1::32,  pos_1_minus_2::32,  pos_1_minus_3::32, pos_2_now::32, pos_2_minus_1::32,  pos_2_minus_2::32,  pos_2_minus_3::32,>> = content

    registers = registers() # TODO get from Frameport 104
    interval = interval_minutes()

    {unit_1, scaler_1} = _map_unit(unit_1)

    {unit_2, scaler_2} = _map_unit(unit_2)

    list = if pos_1_active == 1 && pos_1_valid == 1 do
             [
               # Always adding the first value, because the _valid flag is set for it.
               {
                 %{
                   Enum.at(registers, pos_1_selector) => pos_1_now * scaler_1,
                   "unit" => unit_1
                 },
                 [measured_at: meta[:transceived_at]]
               },
             ]
             |> _add_valid_reading(
                  Enum.at(registers, pos_1_selector),
                  pos_1_minus_1 * scaler_1,
                  unit_1,
                  Timex.shift(meta[:transceived_at], minutes: -1 * interval)
                )
             |> _add_valid_reading(
                  Enum.at(registers, pos_1_selector),
                  pos_1_minus_2 * scaler_1,
                  unit_1,
                  Timex.shift(meta[:transceived_at], minutes: -1 * interval * 2)
                )
             |> _add_valid_reading(
                  Enum.at(registers, pos_1_selector),
                  pos_1_minus_3 * scaler_1,
                  unit_1,
                  Timex.shift(meta[:transceived_at], minutes: -1 * interval * 3)
                )
           else
             []
           end
    ++
           if pos_2_active == 1 && pos_2_valid == 1 do
             [
               # Always adding the first value, because the _valid flag is set for it.
               {
                 %{
                   Enum.at(registers, pos_2_selector) => pos_2_now * scaler_2,
                   "unit" => unit_2
                 },
                 [measured_at: meta[:transceived_at]]
               },
             ]
             |> _add_valid_reading(
                  Enum.at(registers, pos_2_selector),
                  pos_2_minus_1 * scaler_2,
                  unit_2,
                  Timex.shift(meta[:transceived_at], minutes: -1 * interval)
                )
             |> _add_valid_reading(
                  Enum.at(registers, pos_2_selector),
                  pos_2_minus_2 * scaler_2,
                  unit_2,
                  Timex.shift(meta[:transceived_at], minutes: -1 * interval * 2)
                )
             |> _add_valid_reading(
                  Enum.at(registers, pos_2_selector),
                  pos_2_minus_3 * scaler_2,
                  unit_2,
                  Timex.shift(meta[:transceived_at], minutes: -1 * interval * 3)
                )
           else
             []
           end

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


  # Will add a reading to list when value is not zero, or skip that reading
  defp _add_valid_reading(list, _field, 0.0, _unit, _measured_at), do: list
  defp _add_valid_reading(list, _field, 0, _unit, _measured_at), do: list
  defp _add_valid_reading(list, field, value, unit, measured_at) do
    list ++ [
      {
        %{
          field => value,
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
          "register_1" => "1.8.0",
          "register_2" => "2.8.0",
          "register_3" => "1.29.0",
          "register_4" => "2.29.0"
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
          "register_1" => "1.8.0",
          "register_2" => "2.8.0"
        },
      },


      # Regelmäßige Nachricht
      {
        :parse_hex,
        "00493511030A01495452000346848001B911000105B8000105B8000105B8000105B8000007D0000007D0000007D0000007D00175000000000000000000000000000000000000000000000000000000000000000000",
        %{meta: %{frame_port: 3}, transceived_at: test_datetime("2019-01-01T12:00:00Z")},
        [
          {%{"1_8_0" => 67.0, "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01T12:00:00Z")]},
          {%{"1_8_0" => 67.0, "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01T11:45:00Z")]},
          {%{"1_8_0" => 67.0, "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01T11:30:00Z")]},
          {%{"1_8_0" => 67.0, "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01T11:15:00Z")]},
          {%{"2_8_0" => 2.0, "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01T12:00:00Z")]},
          {%{"2_8_0" => 2.0, "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01T11:45:00Z")]},
          {%{"2_8_0" => 2.0, "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01T11:30:00Z")]},
          {%{"2_8_0" => 2.0, "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01T11:15:00Z")]},
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
          {%{"1_8_0" => 2671.794, "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01T12:00:00Z")]},
          {%{"1_8_0" => 2671.7490000000003, "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01T11:45:00Z")]},
          {%{"1_8_0" => 2671.713, "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01T11:30:00Z")]},
          # This value is omitted, because its faulty. {%{"1_8_0" => 0.0, "unit" => "kWh"}, [measured_at: test_datetime("2019-01-01T11:15:00Z")]},
          {%{server_id: "090149534B00041A1C26"}, [measured_at: test_datetime("2019-01-01T12:00:00Z")]},
          {%{battery: 100}, [measured_at: test_datetime("2019-01-01T12:00:00Z")]}
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
