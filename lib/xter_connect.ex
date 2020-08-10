defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # Parser for device Xter Connect that will count people passing by.
  #
  # Changelog:
  #   2020-07-23 [jb]: Initial implementation according to "Payload spec command V203.pdf"
  #

  # this event message is sent on every reset/restart
  def parse(<<
    0x00,
    config_exists,
    hours, minutes,
    guard_time_day, guard_time_night,
    keep_alive_value,
    pio0_event_threshold_day, pio0_event_threshold_night,
    pio1_event_threshold_day, pio1_event_threshold_night,
    pio2_event_threshold_day, pio2_event_threshold_night,
    pio3_event_threshold_day, pio3_event_threshold_night,
    night_start_hours, night_start_minutes,
    day_start_hours, day_start_minutes,
    en_register,
    _rest::binary # if there is more to come
  >>, _meta) do
    %{
      type: :reset,
      config_exists: config_exists,
      hours: hours,
      minutes: minutes,
      guard_time_day: guard_time_day,
      guard_time_night: guard_time_night,
      keep_alive_value: keep_alive_value,
      pio0_event_threshold_day: pio0_event_threshold_day,
      pio0_event_threshold_night: pio0_event_threshold_night,
      pio1_event_threshold_day: pio1_event_threshold_day,
      pio1_event_threshold_night: pio1_event_threshold_night,
      pio2_event_threshold_day: pio2_event_threshold_day,
      pio2_event_threshold_night: pio2_event_threshold_night,
      pio3_event_threshold_day: pio3_event_threshold_day,
      pio3_event_threshold_night: pio3_event_threshold_night,
      night_start_hours: night_start_hours,
      night_start_minutes: night_start_minutes,
      day_start_hours: day_start_hours,
      day_start_minutes: day_start_minutes,
      en_register: en_register,
    }
  end
  # this message is sent every KeepAliveValue (minutes) of inactivity with KeepAlive message,
  # value of event counters (below threshold) are reported then cleared
  def parse(<<0x10, rest::binary>>, _meta) do
    %{
      type: :keep_alive,
    }
    |> Map.merge(parse_rest(rest))
  end
  # this event message is sent if guardtime (in minutes) is elapsed since the last event (Reset, Async or Delayed).
  # An event occure if any of the pioXEvent counter equal the pioXEvent Threshold.
  def parse(<<0x20, rest::binary>>, _meta) do
    %{
      type: :async,
    }
    |> Map.merge(parse_rest(rest))
  end
  # this event message is sent when an event has been detected during the guardtime period,
  # event counter’s are incremented and message is delayed until guartime is elapsed
  def parse(<<0x30, rest::binary>>, _meta) do
    %{
      type: :delayed,
    }
    |> Map.merge(parse_rest(rest))
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  defp parse_rest(<<hours, minutes, flags::binary-1, rest::binary>>) do
    <<
      pio0_present::1,
      pio1_present::1,
      pio2_present::1,
      pio3_present::1,
      int_temp_present::1,
      ext_temp_present::1,
      vbat_present::1,
      vext_present::1,
    >> = flags

    reading = %{
      hours: hours,
      minutes: minutes,
    }

    {rest, reading} = add_parse(reading, :uint8, pio0_present, rest, :pio0, 1)
    {rest, reading} = add_parse(reading, :uint8, pio1_present, rest, :pio1, 1)
    {rest, reading} = add_parse(reading, :uint12, pio2_present, rest, :pio2, 1)
    {rest, reading} = add_parse(reading, :uint12, pio3_present, rest, :pio3, 1)
    {rest, reading} = add_parse(reading, :int12, int_temp_present, rest, :temp_internal, 0.1)
    {rest, reading} = add_parse(reading, :int12, ext_temp_present, rest, :temp_external, 0.1)
    {rest, reading} = add_parse(reading, :uint12, vbat_present, rest, :battery_volt, 0.01) # signed int in docs
    {rest, reading} = add_parse(reading, :uint12, vext_present, rest, :external_volt, 0.01) # signed int in docs

    if rest != <<>> do
      Logger.warn("Too much payload: #{inspect rest}")
    end

    reading
  end
  defp parse_rest(rest) do
    Logger.warn("Invalid payload: #{inspect rest}")
    %{
      parse_error: :invalid_payload,
    }
  end

  defp add_parse(reading, _type, 0, rest, _key, _factor) do
    # Key is not enabled (0)
    {rest, reading}
  end
  defp add_parse(reading, :uint8, 1, <<value::8, rest::bits>>, key, factor) do
    {rest, Map.merge(reading, %{key => value*factor})}
  end
  defp add_parse(reading, :uint12, 1, <<value::12, rest::bits>>, key, factor) do
    {rest, Map.merge(reading, %{key => value*factor})}
  end
  defp add_parse(reading, :int12, 1, <<value::12-signed, rest::bits>>, key, factor) do
    {rest, Map.merge(reading, %{key => value*factor})}
  end
  defp add_parse(reading, type, 1, rest, key, _factor) do
    Logger.warn("Missing #{inspect type} value in payload for #{inspect key} with binary: #{inspect rest}")
    {rest, reading}
  end


  # Define fields with human readable name and a SI unit if available.
  def fields() do
    [
      # The first field should be a numeric value, so it can be used for graphs.
      %{
        field: "pio0",
        display: "pio0",
      },
      %{
        field: "pio1",
        display: "pio1",
      },
      %{
        field: "pio2",
        display: "pio2",
      },
      %{
        field: "pio3",
        display: "pio3",
      },

      %{
        field: "type",
        display: "Type",
      },

      %{
        field: "hours",
        display: "Hours",
        unit: "h",
      },
      %{
        field: "minutes",
        display: "Minutes",
        unit: "m",
      },

      %{
        field: "battery_volt",
        display: "Battery",
        unit: "V",
      },

      %{
        field: "external_volt",
        display: "External Power",
        unit: "V",
      },

      %{
        field: "temp_external",
        display: "Temp Ext.",
        unit: "°C",
      },
      %{
        field: "temp_internal",
        display: "Temp Int.",
        unit: "°C",
      },

    ]
  end

  def tests() do
    [

      # Real Payload
      {:parse_hex, "0001000F0A0A3C010101010000000000000C000C0009", %{meta: %{frame_port: 2}}, %{
        config_exists: 1,
        day_start_hours: 12,
        day_start_minutes: 0,
        en_register: 12,
        guard_time_day: 10,
        guard_time_night: 10,
        hours: 0,
        keep_alive_value: 60,
        minutes: 15,
        night_start_hours: 0,
        night_start_minutes: 0,
        pio0_event_threshold_day: 1,
        pio0_event_threshold_night: 1,
        pio1_event_threshold_day: 1,
        pio1_event_threshold_night: 1,
        pio2_event_threshold_day: 0,
        pio2_event_threshold_night: 0,
        pio3_event_threshold_day: 0,
        pio3_event_threshold_night: 0,
        type: :reset
      }},

      # 30 cmd
      # 00 hours = 0
      # 2D minutes = 45
      # 89 bits 1000 1001
      #   pio0_present 1
      #   pio1_present 0
      #   pio2_present 0
      #   pio3_present 0
      #   intTemp_present 1
      #   extTemp_present 0
      #   vbat_present 0
      #   vext_present 1
      # 02 pio0Event = 2
      # 1BA intTemp = 442
      # CE2 Vext = 3298

      # Real Payload
      {:parse_hex, "30002D89021BACE2", %{meta: %{frame_port: 2}}, %{
        external_volt: 32.980000000000004,
        hours: 0,
        minutes: 45,
        pio0: 2,
        temp_internal: 44.2,
        type: :delayed
      }},

      # ro real payload
      {:parse_hex, "101337FF1234567890112345678912", %{meta: %{frame_port: 1}}, %{
        battery_volt: 16.56,
        external_volt: 23.22,
        hours: 19,
        minutes: 55,
        pio0: 18,
        pio1: 52,
        pio2: 1383,
        pio3: 2192,
        temp_external: 83.7,
        temp_internal: 27.400000000000002,
        type: :keep_alive
      }},
      # ro real payload
      {:parse_hex, "201337F01234567890", %{meta: %{frame_port: 1}}, %{
        hours: 19,
        minutes: 55,
        pio0: 18,
        pio1: 52,
        pio2: 1383,
        pio3: 2192,
        type: :async
      }},
      # ro real payload
      {:parse_hex, "3013370F123456789012", %{meta: %{frame_port: 1}}, %{
        battery_volt: 19.29,
        external_volt: 0.18,
        hours: 19,
        minutes: 55,
        temp_external: 111.0,
        temp_internal: 29.1,
        type: :delayed
      }},
      # ro real payload
      {:parse_hex, "10133700", %{meta: %{frame_port: 1}}, %{
        hours: 19,
        minutes: 55,
        type: :keep_alive
      }},

      # ro real payload
      {:parse_hex, "0013370F12345678901234567890123456789012", %{meta: %{frame_port: 1}}, %{
        config_exists: 19,
        day_start_hours: 120,
        day_start_minutes: 144,
        en_register: 18,
        guard_time_day: 18,
        guard_time_night: 52,
        hours: 55,
        keep_alive_value: 86,
        minutes: 15,
        night_start_hours: 52,
        night_start_minutes: 86,
        pio0_event_threshold_day: 120,
        pio0_event_threshold_night: 144,
        pio1_event_threshold_day: 18,
        pio1_event_threshold_night: 52,
        pio2_event_threshold_day: 86,
        pio2_event_threshold_night: 120,
        pio3_event_threshold_day: 144,
        pio3_event_threshold_night: 18,
        type: :reset
      }},
    ]
  end
end
