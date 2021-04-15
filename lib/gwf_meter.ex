defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # ELEMENT IoT Parser for GWF LoRaWAN module for GWF metering units, according to documentation provided by GWF
  # Supporting Water and Gas.
  #
  #
  # Changelog
  #   2018-04-18 [as]: Initial version.
  #   2018-08-08 [jb]: Parsing battery and additional function.
  #   2019-05-16 [jb]: Removed/changed fields (meter_id, manufacturer_id, state). Added interpolation feature. Added obis codes.
  #   2019-07-04 [ab]: Added support for message type 0x02.
  #   2021-04-15 [jb]: Using new config() function.

  #----- Configuration
  def config() do
    %{
      # Flag if interpolated values for 0:00, 0:15, 0:30, 0:45, ... should be calculated
      # Default: false
      interpolate: false,

      # Minutes between interpolated values
      # Default: 15
      interpolate_minutes: 15,

      # Name of timezone.
      # Default: "Europe/Berlin"
      timezone: "Europe/Berlin"
    }
  end
  defp config(key, meta), do: get(meta, [:_config, key], Map.get(config(), key))


  # Parsing message wit protocol type 0x01
  def parse(<<
      0x01,
      manufacturer_id::integer-little-16,
      meter::binary-4,
      medium_code::8,
      state::binary-1,
      actuality_minutes::integer-little-16,
      vif::8,
      volume::integer-little-32,
      additional_functions::binary-1,
      battery::binary-1,
      _checksum::binary
    >>, meta) do

    with {:ok, medium} <- medium(medium_code),
         {:ok, obis} <- obis_code(medium),
         {:ok, vif_factor} <- vif_factor(vif) do

      %{
        protocol_type: 1,
        manufacturer_id: manufacturer_id,
        meter_id: meter_id(meter),
        medium: medium,
        obis: obis,
      }
      |> Map.merge(state_to_flags(state))
      |> Map.merge(battery(battery))
      |> Map.merge(additional_functions(additional_functions))
      |> case do
        %{error: 1} = reading ->
          # There was a error on the device, value is INVALID and not added.
          reading
        reading ->
          reading = Map.merge(reading, %{
            :volume => round_as_float(volume/vif_factor),
            obis => round_as_float(volume/vif_factor),
          })

          # Need to redate reading if it was recorded in the past.
          measured_at = Timex.shift(meta[:transceived_at], minutes: actuality_minutes * -1)

          [{reading, [measured_at: measured_at]}] ++ build_missing(reading, measured_at, meta)
      end

    else
      error ->
        Logger.error("Problem parsing: #{inspect error}")
        []
    end
  end

  # Parsing message with protocol type 0x02
  def parse(<<
      0x02,
      manufacturer_id::integer-little-16,
      meter::bytes-4,
      medium_code::8,
      state::bytes-1,
      actuality_minutes::integer-little-16,
      vif::8,
      volume::integer-little-32,
      additional_functions::bytes-1,
      battery::bytes-1,
      _checksum::bytes
    >>, meta) do

    with {:ok, medium} <- medium(medium_code),
         {:ok, obis} <- obis_code(medium),
         {:ok, vif_factor} <- vif_factor_type_2(vif) do

      %{
        protocol_type: 2,
        manufacturer_id: manufacturer_id,
        meter_id: meter_id(meter),
        medium: medium,
        obis: obis,
      }
      |> Map.merge(state_to_flags_type_2(state))
      |> Map.merge(battery(battery))
      |> Map.merge(additional_functions(additional_functions))
      |> case do
        %{error: 1} = reading ->
          # There was a error on the device, value is INVALID and not added.
          reading
        reading ->
          reading = Map.merge(reading, %{
            :volume => round_as_float(volume * vif_factor),
            obis => round_as_float(volume * vif_factor),
          })

          # Need to redate reading if it was recorded in the past.
          measured_at = Timex.shift(meta[:transceived_at], minutes: actuality_minutes * -1)
          [{reading, [measured_at: measured_at]}] ++ build_missing(reading, measured_at, meta)
      end

    else
      error ->
        Logger.error("Problem parsing: #{inspect error}")
        []
    end
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  # Reference: https://www.kbr.de/de/obis-kennzeichen/obis-kennzeichen
  defp obis_code(:gas), do: {:ok, "7-0:3.0.0"}
  defp obis_code(:warm_water), do: {:ok, "9-0:1.0.0"}
  defp obis_code(:water), do: {:ok, "8-0:1.0.0"}
  defp obis_code(_), do: {:error, :unkown_obis}


  defp medium(0x03), do: {:ok, :gas}
  defp medium(0x06), do: {:ok, :warm_water}
  defp medium(0x07), do: {:ok, :water}
  defp medium(_), do: {:error, :unkown_medium}

  defp vif_factor(0x16), do: {:ok, 1}
  defp vif_factor(0x15), do: {:ok, 10}
  defp vif_factor(0x14), do: {:ok, 100}
  defp vif_factor(0x13), do: {:ok, 1000}
  defp vif_factor(_), do: {:error, :unknown_vif}


  # Type 0x02 describes a range of (0x10 - 0x17) for the VIF(Value Information Field) factor
  # Provided documentation specifies values for range of (0x13 - 0x17)
  #
  # Ranges -> values:
  # 0x10 - 0x12 -> :unspecified_vif
  # 0x13 - 0x17 -> values according to documentation
  # 0x01 - 0x09 -> :out_of_range_vif
  # 0x18 - 0xFF -> :out_of_range_vif
  defp vif_factor_type_2(0x10), do: {:error, :unspecified_vif}
  defp vif_factor_type_2(0x11), do: {:error, :unspecified_vif}
  defp vif_factor_type_2(0x12), do: {:error, :unspecified_vif}
  defp vif_factor_type_2(0x13), do: {:ok, 0.001}
  defp vif_factor_type_2(0x14), do: {:ok, 0.01}
  defp vif_factor_type_2(0x15), do: {:ok, 0.1}
  defp vif_factor_type_2(0x16), do: {:ok, 1}
  defp vif_factor_type_2(0x17), do: {:ok, 10}
  defp vif_factor_type_2(_), do: {:error, :out_of_range_vif}


  # This function will reverse an 4 byte long binary, encodes it as a String, finally converted to an integer.
  #
  # E.g.: <<0x13, 0x07, 0x16, 0x20>> -> 20160713
  #
  # Be aware, that a non only numbered hex binary causes the String to integer conversion to fail with:
  # (ArgumentError) argument error
  #   :erlang.binary_to_integer
  #
  # ---
  # ICO refactoring
  # Decoding a hex binary from little endian to integer(value)
  # :binary.decode_unsigned(meter, :little)
  defp meter_id(<<a, b, c, d>>), do: <<d, c, b, a>> |> Base.encode16() |> String.to_integer

  defp state_to_flags(<<_::1, broken_comm::1, no_comm::1, error_flag::1, _::1, battery::1, _::1, _::1>>) do
    Map.merge(
      case error_flag do
        1 -> %{error: 1, error_message: "broken_communication:#{broken_comm} no_communication:#{no_comm}"}
        0 -> %{}
      end,
      case battery do
        1 -> %{battery_error: 1}
        0 -> %{}
      end
    )
  end

  # New states parsing according to type 0x02 specifications.
  #
  # First 2 bits will determine errors on application level:
  # 0b01 -> application_error -> error
  # 0b10 -> application_error -> error
  # 0b11 -> reserved          -> empty map
  # 0b00 -> no error          -> empty map
  #
  # Other 6 bits determine battery and communication states and are matched via hex, e.g. 0x04 -> battery_low
  #
  defp state_to_flags_type_2(<<0x00>>), do: %{} # no error
  defp state_to_flags_type_2(<<0x04>>), do: %{battery_low: 1}
  defp state_to_flags_type_2(<<0x30>>), do: %{communication_error_1: 1}
  defp state_to_flags_type_2(<<0x50>>), do: %{communication_error_2: 1}
  defp state_to_flags_type_2(<<0x90>>), do: %{communication_error_3: 1}
  defp state_to_flags_type_2(<<0x34>>), do: %{battery_low: 1, communication_error_1: 1}
  defp state_to_flags_type_2(<<0x54>>), do: %{battery_low: 1, communication_error_2: 1}
  defp state_to_flags_type_2(<<0x94>>), do: %{battery_low: 1, communication_error_3: 1}
  defp state_to_flags_type_2(<<_::6, application_errors::2>> = state) do
    case application_errors do
      0b01 -> %{error: 1, error_message: "application_error: application busy, state: #{inspect state}"}
      0b10 -> %{error: 1, error_message: "application_error: any application error, state: #{inspect state}"}
      _    -> %{} # 0b011: reserved, 0b00: no error
    end
  end


  defp battery(<<battery_lifetime_semester::5, _lorawan_link_check::1, _::2>>) do
    %{
      battery_lifetime_semester: battery_lifetime_semester,
      battery_percent: floor((battery_lifetime_semester / 31) * 100),
    }
  end

  defp additional_functions(<<no_usage::1, backflow::1, battery_low::1, _::1, broken_pipe::1, _::1, continous_flow::1, _::1>>) do
    %{
      continous_flow: continous_flow,
      broken_pipe: broken_pipe,
      battery_low: battery_low,
      backflow: backflow,
      no_usage: no_usage,
    }
  end


  defp build_missing(%{meter_id: meter_id, medium: medium, volume: current_value}, current_measured_at, meta) do

    if config(:interpolate, meta) do

      last_reading_query = [meter_id: meter_id, medium: medium, volume: :_]

      case get_last_reading(meta, last_reading_query) do
        %{data: %{:volume => last_value}, measured_at: last_measured_at} ->

           [
             {%{value: last_value}, [measured_at: last_measured_at]},
             {%{value: current_value}, [measured_at: current_measured_at]},
           ]
           |> TimeSeries.fill_gaps(
                fn datetime_a, datetime_b ->
                  # Calculate all tuples with x=nil between a and b where a value should be interpolated
                  interval = Timex.Interval.new(
                    from: datetime_a |> Timex.to_datetime(config(:timezone, meta)) |> datetime_add_to_multiple_of_minutes(config(:interpolate_minutes, meta)),
                    until: datetime_b,
                    left_open: false,
                    step: [minutes: config(:interpolate_minutes, meta)]
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
            value = round_as_float(value)
            {:ok, obis} = obis_code(medium)
            {
              %{
                :meter_id => meter_id,
                :medium => medium,
                :volume => value,
                :obis => obis,
                obis => value,
              },
              reading_meta
            }
           end)

        nil ->
          Logger.info("No result for get_last_reading(#{inspect last_reading_query})")
          []

        invalid_prev_reading ->
          Logger.warn("Could not build_missing() because of invalid previous reading: #{inspect invalid_prev_reading}")
          []
      end

    else
      []
    end
  end
  defp build_missing(_current_data, _current_measured_at, _meta) do
    Logger.warn("Could not build_missing() because of invalid current_data")
    []
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

  def fields do
    [
      %{
        "field" => "volume",
        "display" => "Volume",
        "unit" => "m³"
      }
    ]
  end

  def tests() do
    [
      {
        :parse_hex,
        String.replace("02 E61E 13071620 07 02 C801 17 F8030000 00 E8 7473", " ", ""),
        %{
          transceived_at: test_datetime("2019-01-01T12:34:56Z")
        },
            %{
              :backflow => 0,
              :battery_lifetime_semester => 29,
              :battery_low => 0,
              :battery_percent => 93,
              :broken_pipe => 0,
              :continous_flow => 0,
              :error => 1,
              :error_message => "application_error: any application error, state: <<2>>",
              :manufacturer_id => 7910,
              :medium => :water,
              :meter_id => 20160713,
              :no_usage => 0,
              :obis => "8-0:1.0.0",
              :protocol_type => 2
            }
      },{
        :parse_hex,
        String.replace("02 E61E 13071620 07 01 C801 17 F8030000 00 E8 7473", " ", ""),
        %{
          transceived_at: test_datetime("2019-01-01T12:34:56Z")
        },
            %{
              :backflow => 0,
              :battery_lifetime_semester => 29,
              :battery_low => 0,
              :battery_percent => 93,
              :broken_pipe => 0,
              :continous_flow => 0,
              :error => 1,
              :error_message => "application_error: application busy, state: <<1>>",
              :manufacturer_id => 7910,
              :medium => :water,
              :meter_id => 20160713,
              :no_usage => 0,
              :obis => "8-0:1.0.0",
              :protocol_type => 2
            }
      },{
        :parse_hex,
        String.replace("02 E61E 13071620 07 00 C801 AA F8030000 00 E8 7473", " ", ""),
        %{
          transceived_at: test_datetime("2019-01-01T12:34:56Z")
        },
        [] # [error] Problem parsing: {:error, :out_of_range_vif}
      },{
        :parse_hex,
        String.replace("02 E61E 13071620 07 00 C801 10 F8030000 00 E8 7473", " ", ""),
        %{
          transceived_at: test_datetime("2019-01-01T12:34:56Z")
        },
        [] # [error] Problem parsing: {:error, :unspecified_vif}
      },{
        :parse_hex,
        String.replace("02 E61E 13071620 07 00 C801 17 F8030000 00 E8 7473", " ", ""),
        %{
          transceived_at: test_datetime("2019-01-01T12:34:56Z")
        },
        [
          {
            %{
              :backflow => 0,
              :battery_lifetime_semester => 29,
              :battery_low => 0,
              :battery_percent => 93,
              :broken_pipe => 0,
              :continous_flow => 0,
              :manufacturer_id => 7910,
              :medium => :water,
              :meter_id => 20160713,
              :no_usage => 0,
              :obis => "8-0:1.0.0",
              :protocol_type => 2,
              :volume => 10160.0,
              "8-0:1.0.0" => 10160.0
            },
            [
              measured_at: test_datetime("2019-01-01 04:58:56Z"),
            ]
          }
        ]
      },{
        :parse_hex,
        String.replace("02 E61E 13071620 07 00 C801 14 F8030000 00 E8 7473", " ", ""),
        %{
          transceived_at: test_datetime("2019-01-01T12:34:56Z")
        },
        [
          {
            %{
              :backflow => 0,
              :battery_lifetime_semester => 29,
              :battery_low => 0,
              :battery_percent => 93,
              :broken_pipe => 0,
              :continous_flow => 0,
              :manufacturer_id => 7910,
              :medium => :water,
              :meter_id => 20160713,
              :no_usage => 0,
              :obis => "8-0:1.0.0",
              :protocol_type => 2,
              :volume => 10.16,
              "8-0:1.0.0" => 10.16
            },
            [
              measured_at: test_datetime("2019-01-01 04:58:56Z"),
            ]
          }
        ]
      },
      {
        :parse_hex,
        String.replace("02 E61E 13071620 07 00 C801 13 F8030000 00 E8 7473", " ", ""),
        %{
          transceived_at: test_datetime("2019-01-01T12:34:56Z")
        },
        [
          {
            %{
              :backflow => 0,
              :battery_lifetime_semester => 29,
              :battery_low => 0,
              :battery_percent => 93,
              :broken_pipe => 0,
              :continous_flow => 0,
              :manufacturer_id => 7910,
              :medium => :water,
              :meter_id => 20160713,
              :no_usage => 0,
              :obis => "8-0:1.0.0",
              :protocol_type => 2,
              :volume => 1.016,
              "8-0:1.0.0" => 1.016
            },
            [
              measured_at: test_datetime("2019-01-01 04:58:56Z"),
            ]
          }
        ]
      },
      {
        :parse_hex,
        String.replace("01 E61E 13071620 07 00 C801 13 F8030000 00 E8 7473", " ", ""),
        %{
          transceived_at: test_datetime("2019-01-01T12:34:56Z")
        },
        [
          {
            %{
              :backflow => 0,
              :battery_lifetime_semester => 29,
              :battery_low => 0,
              :battery_percent => 93,
              :broken_pipe => 0,
              :continous_flow => 0,
              :manufacturer_id => 7910,
              :medium => :water,
              :meter_id => 20160713,
              :no_usage => 0,
              :obis => "8-0:1.0.0",
              :protocol_type => 1,
              :volume => 1.016,
              "8-0:1.0.0" => 1.016
            },
            [
              measured_at: test_datetime("2019-01-01 04:58:56Z"),
            ]
          }
        ]
      },

      {
        :parse_hex,
        String.replace("01 E61E 13071620 07 00 C801 13 F8030000 00 E8 7473", " ", ""),
        %{
          transceived_at: test_datetime("2019-01-01T12:34:56Z"),
          _config: %{
            interpolate: true,
          },
          _last_reading_map: %{
            [meter_id: 20160713, medium: :water, volume: :_] => %{measured_at: test_datetime("2019-01-01T04:11:11Z"), data: %{volume: 0.45}},
          },
        },
        [
          {
            %{
              :backflow => 0,
              :battery_lifetime_semester => 29,
              :battery_low => 0,
              :battery_percent => 93,
              :broken_pipe => 0,
              :continous_flow => 0,
              :manufacturer_id => 7910,
              :medium => :water,
              :meter_id => 20160713,
              :no_usage => 0,
              :obis => "8-0:1.0.0",
              :protocol_type => 1,
              :volume => 1.016,
              "8-0:1.0.0" => 1.016
            },
            [
              measured_at: test_datetime("2019-01-01 04:58:56Z"),
            ]
          },
          {%{
            :medium => :water,
            :meter_id => 20160713,
            :obis => "8-0:1.0.0",
            :volume => 0.495,
            "8-0:1.0.0" => 0.495
          }, [measured_at: test_datetime("2019-01-01 04:15:00Z")]},
          {%{
            :medium => :water,
            :meter_id => 20160713,
            :obis => "8-0:1.0.0",
            :volume => 0.673,
            "8-0:1.0.0" => 0.673
          }, [measured_at: test_datetime("2019-01-01 04:30:00Z")]},
          {%{
            :medium => :water,
            :meter_id => 20160713,
            :obis => "8-0:1.0.0",
            :volume => 0.851,
            "8-0:1.0.0" => 0.851
          }, [measured_at: test_datetime("2019-01-01 04:45:00Z")]}
        ]
      },

      {
        :parse_hex,
        "01E61E1831062103000000141900000000D0982D",
        %{
          transceived_at: test_datetime("2019-01-01T12:34:56Z")
        },
        [
          {
            %{
              :backflow => 0,
              :battery_lifetime_semester => 26,
              :battery_low => 0,
              :battery_percent => 83,
              :broken_pipe => 0,
              :continous_flow => 0,
              :manufacturer_id => 7910,
              :medium => :gas,
              :meter_id => 21063118,
              :no_usage => 0,
              :obis => "7-0:3.0.0",
              :protocol_type => 1,
              :volume => 0.25,
              "7-0:3.0.0" => 0.25
            },
            [
              measured_at: test_datetime("2019-01-01 12:34:56Z"),
            ]
          }
        ]
      },

      {
        :parse_hex,
        "01E61E1831062103000000141900000000D0982D",
        %{
          transceived_at: test_datetime("2019-01-01T12:34:56Z"),
          _config: %{
            interpolate: true,
          },
          _last_reading_map: %{
            [meter_id: 21063118, medium: :gas, volume: :_] => %{measured_at: test_datetime("2019-01-01T12:11:11Z"), data: %{volume: 0.12}},
          },
        },
        [
          {
            %{
              :backflow => 0,
              :battery_lifetime_semester => 26,
              :battery_low => 0,
              :battery_percent => 83,
              :broken_pipe => 0,
              :continous_flow => 0,
              :manufacturer_id => 7910,
              :medium => :gas,
              :meter_id => 21063118,
              :no_usage => 0,
              :obis => "7-0:3.0.0",
              :protocol_type => 1,
              :volume => 0.25,
              "7-0:3.0.0" => 0.25
            }, [measured_at: test_datetime("2019-01-01 12:34:56Z")]},
            {%{
              :medium => :gas,
              :meter_id => 21063118,
              :obis => "7-0:3.0.0",
              :volume => 0.141,
              "7-0:3.0.0" => 0.141
            }, [measured_at: test_datetime("2019-01-01 12:15:00Z")]},
            {%{
              :medium => :gas,
              :meter_id => 21063118,
              :obis => "7-0:3.0.0",
              :volume => 0.223,
              "7-0:3.0.0" => 0.223
            }, [measured_at: test_datetime("2019-01-01 12:30:00Z")]}
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
