defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Adeunis Temperature Sensors
  #  - ARF8180BA
  #  - ARF8180BCA (1 Sensor)
  #  - ARF8180BCB (2 Sensors)

  # According to documentation provided by Adeunis
  # Link: https://www.adeunis.com/en/produit/temp/
  # Documentation v2: https://www.adeunis.com/wp-content/uploads/2017/08/TEMP_LoRaWAN_UG_V2.0.0_FR_EN.pdf
  # Documentation v3: https://www.adeunis.com/wp-content/uploads/2020/07/Technical_Reference_Manual_TEMP3_APP_2.0_072020.pdf
  # Documentation v4: https://www.adeunis.com/wp-content/uploads/2019/09/TEMP_V4-Technical_Reference_Manual_APP_2.1-25.11.2020.pdf
  #
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #   2020-08-26 [jb]: Support for v3 payloads.
  #   2020-08-27 [jb]: Added alerts for v3 payloads.
  #   2021-02-02 [jb]: Support for v4 payloads.
  #   2021-02-04 [jb]: Supporting payloads with timestamp.
  #

  def default_sampling_period_seconds(), do: 3600

  # Version 2 of sensor
  def parse(<<0x43, _status::8, internal_identifier::8, internal_value::signed-16, external_identifier::8, external_value::signed-16>>, _meta) do
    <<_internal_register::4, internal_status::4>> = <<internal_identifier::8>>
    <<_external_register::4, external_status::4>> = <<external_identifier::8>>

    internal_sensor = case internal_status do
      0 -> "error"
      1 -> "B57863S0303F040"
      _ -> "unknown"
    end
    external_sensor = case external_status do
      0 -> "error"
      1 -> "E-NTC-APP-1.5P7"
      2 -> "FANB57863-400-1"
      _ -> "unknown"
    end

    %{
      version: 2,
      internal_sensor: internal_sensor,
      internal_temp: internal_value/10,
      external_sensor: external_sensor,
      external_temp: external_value/10,
    }
  end
  # Version 3 of sensor
  def parse(<<code::8, status::binary-1, payload::binary>>, meta) do
    {row, new_payload} = %{version: 3}
      |> parse_status(status)
      |> parse_timestamp(code, payload)

    row
    |> parse_body(code, new_payload, meta)
    |> handle_measured_at()
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  # If there is a timestamp_at in row, use it as new measured_at
  defp handle_measured_at(rows) when is_list(rows) do
    Enum.map(rows, &handle_measured_at(&1))
  end
  defp handle_measured_at(%{timestamp_at: timestamp} = row) do
    {row, [measured_at: timestamp]}
  end
  defp handle_measured_at(row) do
    row
  end

  # There are some payloads with a suffix timestamp that needs to be removed.
  defp parse_timestamp(%{timestamp: 1} = row, code, payload) when code in [
    0x30, # keep alive
    0x57, # periodic data
    0x58, # alarm
  ] do
    start_len = byte_size(payload)-4
    case payload do
      <<prefix::binary-size(start_len), timestamp::32>> ->
        row = Map.merge(row, %{
          timestamp_at: timestamp_epoch2013(timestamp),
        })
        {row, prefix}
      _ ->
        {row, payload}
    end
  end
  defp parse_timestamp(row, _code, payload) do
    {row, payload}
  end

  defp timestamp_epoch2013(timestamp) do
    timestamp
    |> Kernel.+((2013 - 1970) * 365 * 24 * 60 * 60)
    |> Timex.from_unix(:second)
  end

  #----------------------------

  defp parse_status(row, <<frame_counter::3, channels::1, configuration_problem::1, timestamp::1, low_bat::1, config::1>>) do
    %{
      configuration_problem: configuration_problem,
      low_battery: low_bat,
      configuration_done: config
    }
    |> Enum.filter(fn ({_key, value}) -> value == 1 end)
    |> Enum.into(%{
      frame_counter: frame_counter,
      channels: channels + 1, # 0 => 1 channel, 1 => 2 channels
      timestamp: timestamp, # If 1, a timestamp is appended to some payloads
    })
    |> Map.merge(row)
  end

  defp parse_body(row, 0x10, <<s300::16, s301::16, s320::16, s321::16, s323::8>>, _meta) do
    Map.merge(row, %{
      frame_type: :configuration,

      transmission_period_keepalive: (s300*10), # Seconds between keepalive packets
      transmission_period_data: s301, # Number of backups (history logs) to be done before sending a frame (thus defining the sending period). The value 0 is equivalent to disabling the periodic mode.

      history_period: s320, # Number of readings to be performed before saving in the history logs. The value 1 is equivalent to 1 backup per reading
      sampling_period: (s321*2), # Seconds between measuring temperature

      redundancy: s323, # Number of samples to be repeated in the next frame (0..23)
    })
  end

  defp parse_body(row, 0x20, <<_rfu1::2, class_t::1, _rfu2::2, dc::1, _rfu3::1, adr::1, _rfu4::7, act::1>>, _meta) do
    activation = case act do
      0 -> :abp
      1 -> :otaa
    end
    class = case class_t do
      0 -> :a
      1 -> :c
    end
    Map.merge(row, %{
      frame_type: :network_config,
      class: class,
      duty_cycle: dc,
      adr: adr,
      activation: activation
    })
  end

  defp parse_body(row, 0x2F, <<downlink, request_status>>, _meta) do
    request_status = case request_status do
      0x00 -> :not_available
      0x01 -> :success
      0x02 -> :error_generic
      0x03 -> :error_wrong_state
      0x04 -> :error_invalid_request
      other -> "rfu_#{other}"
    end
    Map.merge(row, %{
      frame_type: :acknowledgement,
      downlink_framcode: downlink,
      request_status: request_status,
    })
  end

  defp parse_body(%{channels: 1} = row, 0x30, <<t1::binary-2>>, _meta) do
    row
    |> Map.merge(%{frame_type: :keepalive})
    |> add_valid_temp(t1, :temp_ch1)
  end
  defp parse_body(%{channels: 2} = row, 0x30, <<t1::binary-2, t2::binary-2>>, _meta) do
    row
    |> Map.merge(%{frame_type: :keepalive})
    |> add_valid_temp(t1, :temp_ch1)
    |> add_valid_temp(t2, :temp_ch2)
  end

  defp parse_body(row, 0x31, <<>>, _meta) do
    Map.merge(row, %{
      frame_type: :get_register_response,
      error: :empty_response
    })
  end
  defp parse_body(row, 0x31, <<value::binary>>, _meta) do
    Map.merge(row, %{
      frame_type: :get_register_response,
      values: Base.encode16(value),
    })
  end

  defp parse_body(row, 0x33, <<request_status, register_id::16>>, _meta) do
    request_status = case request_status do
      0x00 -> :not_available
      0x01 -> :success
      0x02 -> :success_no_update
      0x03 -> :error_coherency
      0x04 -> :error_invalid_register
      0x05 -> :error_invalid_value
      0x06 -> :error_truncated_value
      0x07 -> :error_access_not_allowed
      0x08 -> :error_other_reason
      other -> "undefined_#{other}"
    end
    Map.merge(row, %{
      frame_type: :set_register_response,
      request_status: request_status,
      register_id: register_id,
    })
  end

  defp parse_body(row, 0x37, <<app1, app2, app3, rtu1, rtu2, rtu3>>, _meta) do
    row
    |> Map.merge(%{
      frame_type: :software_version,
      app_version: "#{app1}.#{app2}.#{app3}",
      rtu_version: "#{rtu1}.#{rtu2}.#{rtu3}",
    })
  end

  # Periodic data, 1 channel
  defp parse_body(%{channels: 1} = row, 0x57, <<t1::binary-2, _::binary>> = body, %{transceived_at: transceived_at} = meta) do
     row = Map.merge(row, %{frame_type: :data})
     with {:ok, %{sampling_period: sampling_period}} <- get_last_configuration(meta) do
       (for <<t::binary-2 <- body>>, do: t)
       |> Enum.with_index()
       |> times_to_readings(row, transceived_at, sampling_period)
     else
       _error ->
         times_to_readings([{t1, 0}], row, transceived_at, 0)
     end
  end
  # Periodic data, 2 channel
  defp parse_body(%{channels: 2} = row, 0x57, <<t1::binary-2, t2::binary-2, _::binary>> = body, %{transceived_at: transceived_at} = meta) do
    row = Map.merge(row, %{frame_type: :data})
    with {:ok, %{sampling_period: sampling_period}} <- get_last_configuration(meta) do
      (for <<t1::binary-2, t2::binary-2 <- body>>, do: {t1, t2})
      |> Enum.with_index()
      |> times_to_readings(row, transceived_at, sampling_period)
    else
      _error ->
        times_to_readings([{{t1, t2}, 0}], row, transceived_at, 0)
    end
  end

  # Periodic data, 2 channel
  defp parse_body(%{channels: 1} = row, 0x58, <<alarm1, temp1::binary-2>>, _meta) do
    row
    |> Map.merge(%{
      frame_type: :alarm,
      alarm_ch1: alarm_status(alarm1),
    })
    |> add_valid_temp(temp1, :temp_ch1)
  end
  defp parse_body(%{channels: 2} = row, 0x58, <<alarm1, temp1::binary-2, alarm2, temp2::binary-2>>, _meta) do
    row
    |> Map.merge(%{
      frame_type: :alarm,
      alarm_ch1: alarm_status(alarm1),
      alarm_ch2: alarm_status(alarm2),
    })
    |> add_valid_temp(temp1, :temp_ch1)
    |> add_valid_temp(temp2, :temp_ch2)
  end

  defp parse_body(row, 0x36, <<alert>>, _meta) do
    row
    |> Map.merge(%{
      frame_type: :alert,
      alert: Map.get(%{
        0 => :normal_state,
        1 => :powersupply_disconnected,
      }, alert, :unknown)
    })
  end

  defp parse_body(row, code, payload, _meta) do
    Map.merge(row, %{
      frame_type: :unknown_body,
      unknown_code: code,
      unknown_payload: inspect(payload),
    })
  end

  defp alarm_status(0), do: :no_alarm
  defp alarm_status(1), do: :high_threshold
  defp alarm_status(2), do: :low_threshold
  defp alarm_status(_), do: :unknown

  defp times_to_readings(times, reading_template, transceived_at, sampling_period) do

    # Using timestamp from payload if available
    timestamp = case reading_template do
      %{timestamp_at: time} -> time
      _ -> transceived_at
    end

    Enum.map(times, fn ({time, index}) ->
      row = case time do
        {time1, time2} ->
          reading_template |> add_valid_temp(time1, :temp_ch1) |> add_valid_temp(time2, :temp_ch2)
        time1 ->
          reading_template |> add_valid_temp(time1, :temp_ch1)
      end
      {row, [measured_at: Timex.shift(timestamp, seconds: -1 * (sampling_period * index))]}
    end)
  end

  # Will parse, validate and add a reading with given key.
  defp add_valid_temp(row, <<temp::signed-16>>, key) do
    case temp do
      temp when temp == -32768 ->
        Map.merge(row, %{"#{key}_invalid" => 1})
      temp ->
        Map.merge(row, %{key => temp/10})
    end
  end

  # Fetching last "configuration" reading to get sampling_period or return error.
  defp get_last_configuration(meta) do
    case get_last_reading(meta, [frame_type: "configuration"]) do
      %{data: %{"frame_type" => "configuration", "sampling_period" => sampling_period}} ->
        {:ok, %{
          sampling_period: sampling_period,
        }}
      _ ->
        {:ok, %{
          sampling_period: default_sampling_period_seconds(),
        }}
    end
  end


  # defining fields for visualisation
  def fields do
    [
      # v2
      %{
        "field" => "internal_temp",
        "display" => "Internal Temperature",
        "unit" => "°C"
      },
      %{
        "field" => "external_temp",
        "display" => "External Temperature",
        "unit" => "°C"
      },

      # v3
      %{
        "field" => "temp_ch1",
        "display" => "Temperature Channel1",
        "unit" => "°C"
      },
      %{
        "field" => "temp_ch2",
        "display" => "Temperature Channel2",
        "unit" => "°C"
      },
      %{
        "field" => "version",
        "display" => "Payload Version"
      },
      %{
        "field" => "channels",
        "display" => "Channels"
      },
      %{
        "field" => "frame_type",
        "display" => "Frame Type"
      },
      %{
        "field" => "low_battery",
        "display" => "Low Battery"
      },
    ]
  end

  # Test case and data for automatic testing
  def tests() do

    #status_1ch = Base.encode16(<<0b010_00_000>>)
    #status_2ch = Base.encode16(<<0b010_10_000>>)
    status_1ch_timestamp = Base.encode16(<<0b010_00_100>>)
    status_2ch_timestamp = Base.encode16(<<0b010_10_100>>)

    [
      # v2 example
      {
        :parse_hex,
        "43800100EC0200EC",
        %{},
        %{
          external_sensor: "FANB57863-400-1",
          external_temp: 23.6,
          internal_sensor: "B57863S0303F040",
          internal_temp: 23.6,
          version: 2
        }
      },

      # v3 docs example
      # 1.7.1 Product configuration (0x10)
      {
        :parse_hex,
        "10 10 21C0 0001 0001 0708 00",
        %{},
        %{
          version: 3,
          channels: 2,
          frame_counter: 0,
          frame_type: :configuration,
          history_period: 1,
          redundancy: 0,
          timestamp: 0,
          sampling_period: 3600,
          transmission_period_data: 1,
          transmission_period_keepalive: 86400
        }
      },

      # v3 docs example
      # 1.7.2 Network configuration (0x20)
      {
        :parse_hex,
        "20 30 05 01",
        %{},
        %{
          version: 3,
          activation: :otaa,
          adr: 1,
          channels: 2,
          class: :a,
          duty_cycle: 1,
          frame_counter: 1,
          timestamp: 0,
          frame_type: :network_config
        }
      },

      # v3 docs example
      # 1.7.3 Keep alive frame (0x30)
      {
        :parse_hex,
        "30 E2 01B3",
        %{},
        %{
          version: 3,
          channels: 1,
          frame_counter: 7,
          frame_type: :keepalive,
          low_battery: 1,
          timestamp: 0,
          temp_ch1: 43.5
        }
      },
      {
        :parse_hex,
        "30 #{status_1ch_timestamp} 01B3 14ABA3E9",
        %{
          _comment: "keep alive ch1 with timestamp",
        },
        {%{
          channels: 1,
          frame_counter: 2,
          frame_type: :keepalive,
          temp_ch1: 43.5,
          timestamp: 1,
          timestamp_at: ~U[2023-12-17 19:22:17Z],
          version: 3
        }, [measured_at: ~U[2023-12-17 19:22:17Z]]}
      },
      {
        :parse_hex,
        "30 F2 01B3 FF9C",
        %{},
        %{
          version: 3,
          channels: 2,
          frame_counter: 7,
          frame_type: :keepalive,
          low_battery: 1,
          timestamp: 0,
          temp_ch1: 43.5,
          temp_ch2: -10.0
        }
      },

      # v3 docs example
      # 1.7.4 Periodic data frame (0x57)
      {
        :parse_hex,
        "57 80 01B3 8000",
        %{
          transceived_at: test_datetime("2019-01-01 12:00:00Z"),
          _comment: "With missing configuration last reading, using default sampling value",
        },
        [
          {%{
            channels: 1,
            frame_counter: 4,
            frame_type: :data,
            temp_ch1: 43.5,
            timestamp: 0,
            version: 3
          }, [measured_at: ~U[2019-01-01 12:00:00Z]]},
          {%{
            :channels => 1,
            :frame_counter => 4,
            :frame_type => :data,
            :timestamp => 0,
            :version => 3,
            "temp_ch1_invalid" => 1
          }, [measured_at: ~U[2019-01-01 11:00:00Z]]}
        ]
      },
      {
        :parse_hex,
        "57 80 01B3 8000 01B3",
        %{
          transceived_at: test_datetime("2019-01-01 12:00:00Z"),
          _last_reading: %{
            data: %{
              "frame_type" => "configuration",
              "sampling_period" => 3600,
            },
          },
        },
        [
          {%{
            channels: 1,
            frame_counter: 4,
            frame_type: :data,
            temp_ch1: 43.5,
            timestamp: 0,
            version: 3
          }, [measured_at: ~U[2019-01-01 12:00:00Z]]},
          {%{
            :channels => 1,
            :frame_counter => 4,
            :frame_type => :data,
            :timestamp => 0,
            :version => 3,
            "temp_ch1_invalid" => 1
          }, [measured_at: ~U[2019-01-01 11:00:00Z]]},
          {%{
            channels: 1,
            frame_counter: 4,
            frame_type: :data,
            temp_ch1: 43.5,
            timestamp: 0,
            version: 3
          }, [measured_at: ~U[2019-01-01 10:00:00Z]]}
        ]
      },
      {
        :parse_hex,
        "57 92 01B3 FF9C 01F4 FFFF",
        %{
          transceived_at: test_datetime("2019-01-01 12:00:00Z"),
          _last_reading: %{
            data: %{
              "frame_type" => "configuration",
              "sampling_period" => 3600,
            },
          },
        },
        [
          {%{
            version: 3,
            channels: 2,
            frame_counter: 4,
            frame_type: :data,
            timestamp: 0,
            low_battery: 1,
            temp_ch1: 43.5,
            temp_ch2: -10.0
          }, [measured_at: ~U[2019-01-01 12:00:00Z]]},
          {%{
            version: 3,
            channels: 2,
            frame_counter: 4,
            frame_type: :data,
            timestamp: 0,
            low_battery: 1,
            temp_ch1: 50.0,
            temp_ch2: -0.1
          }, [measured_at: ~U[2019-01-01 11:00:00Z]]}
        ]
      },

      {
        :parse_hex,
        "57 #{status_2ch_timestamp} 01B3 FF9C 01F4 FFFF 14ABA3E9",
        %{
          _comment: "with timestamp",
          transceived_at: test_datetime("2019-01-01 12:00:00Z"),
          _last_reading: %{
            data: %{
              "frame_type" => "configuration",
              "sampling_period" => 3600,
            },
          },
        },
        [
          {%{
            channels: 2,
            frame_counter: 2,
            frame_type: :data,
            temp_ch1: 43.5,
            temp_ch2: -10.0,
            timestamp: 1,
            timestamp_at: ~U[2023-12-17 19:22:17Z],
            version: 3
          }, [measured_at: ~U[2023-12-17 19:22:17Z]]},
          {%{
            channels: 2,
            frame_counter: 2,
            frame_type: :data,
            temp_ch1: 50.0,
            temp_ch2: -0.1,
            timestamp: 1,
            timestamp_at: ~U[2023-12-17 19:22:17Z],
            version: 3
          }, [measured_at: ~U[2023-12-17 18:22:17Z]]}
        ]
      },

      # Realworld v3 device
      {
        :parse_hex,
        "578001B38000",
        %{
          transceived_at: test_datetime("2019-01-01 12:00:00Z"),
          _last_reading: %{
            data: %{
              "frame_type" => "configuration",
              "sampling_period" => 3600,
            },
          },
        },
        [
          {%{
            channels: 1,
            frame_counter: 4,
            frame_type: :data,
            temp_ch1: 43.5,
            timestamp: 0,
            version: 3
          }, [measured_at: ~U[2019-01-01 12:00:00Z]]},
          {%{
            :channels => 1,
            :frame_counter => 4,
            :frame_type => :data,
            :timestamp => 0,
            :version => 3,
            "temp_ch1_invalid" => 1
          }, [measured_at: ~U[2019-01-01 11:00:00Z]]}
        ]
      },
      {
        :parse_hex,
        "579201B3FF9C01F4FFFF",
        %{
          transceived_at: test_datetime("2019-01-01 12:00:00Z"),
          _last_reading: %{
            data: %{
              "frame_type" => "configuration",
              "sampling_period" => 3600,
            },
          },
        },
        [
          {%{
            version: 3,
            channels: 2,
            frame_counter: 4,
            frame_type: :data,
            timestamp: 0,
            low_battery: 1,
            temp_ch1: 43.5,
            temp_ch2: -10.0
          }, [measured_at: ~U[2019-01-01 12:00:00Z]]},
          {%{
            version: 3,
            channels: 2,
            frame_counter: 4,
            frame_type: :data,
            timestamp: 0,
            low_battery: 1,
            temp_ch1: 50.0,
            temp_ch2: -0.1
          }, [measured_at: ~U[2019-01-01 11:00:00Z]]}
        ]
      },
      {
        :parse_hex,
        "579000EA014D",
        %{
          transceived_at: test_datetime("2019-01-01 12:00:00Z"),
          _last_reading: %{
            data: %{
              "frame_type" => "configuration",
              "sampling_period" => 3600,
            },
          },
        },
        [
          {%{
            channels: 2,
            frame_counter: 4,
            frame_type: :data,
            timestamp: 0,
            temp_ch1: 23.4,
            temp_ch2: 33.3,
            version: 3
          }, [measured_at: ~U[2019-01-01 12:00:00Z]]}
        ]
      },
      {
        :parse_hex,
        "58B00000E7000123",
        %{
          transceived_at: test_datetime("2019-01-01 12:00:00Z"),
          _last_reading: %{
            data: %{
              "frame_type" => "configuration",
              "sampling_period" => 3600,
            },
          },
        },
        %{
          alarm_ch1: :no_alarm,
          alarm_ch2: :no_alarm,
          channels: 2,
          frame_counter: 5,
          frame_type: :alarm,
          timestamp: 0,
          temp_ch1: 23.1,
          temp_ch2: 29.1,
          version: 3
        }
      },
      {
        :parse_hex,
        "36 80 01",
        %{
          transceived_at: test_datetime("2019-01-01 12:00:00Z"),
          _last_reading: %{
            data: %{
              "frame_type" => "configuration",
              "sampling_period" => 3600,
            },
          },
        },
        %{
          alert: :powersupply_disconnected,
          channels: 1,
          frame_counter: 4,
          frame_type: :alert,
          timestamp: 0,
          version: 3
        }
      },
      {
        :parse_hex,
        "101021C00001000101C200",
        %{
          _comment: "Payload v4 from device"
        },
        %{
          channels: 2,
          frame_counter: 0,
          frame_type: :configuration,
          history_period: 1,
          redundancy: 0,
                        timestamp: 0,
          sampling_period: 900,
          transmission_period_data: 1,
          transmission_period_keepalive: 86400,
          version: 3
        }
      },
      {
        :parse_hex,
        "20300501",
        %{
          _comment: "Payload v4 from device"
        },
        %{
          activation: :otaa,
          adr: 1,
          channels: 2,
          class: :a,
          duty_cycle: 1,
          frame_counter: 1,
          frame_type: :network_config,timestamp: 0,
          version: 3
        }
      },
      {
        :parse_hex,
        "575400ED00EF0F35A324",
        %{
          transceived_at: test_datetime("2019-01-01 12:00:00Z"),
          _comment: "Payload v4 from device"
        },
        [
          {%{
            channels: 2,
            frame_counter: 2,
            frame_type: :data,
            temp_ch1: 23.7,
            temp_ch2: 23.9,
            timestamp: 1,
            timestamp_at: ~U[2021-01-21 09:30:12Z],
            version: 3
          }, [measured_at: ~U[2021-01-21 09:30:12Z]]}
        ]
      },
      {
        :parse_hex,
        "10 10 21C0 0001 0001 0708 00",
        %{
          _comment: "Payload v4 from docs",
        },
        %{
          channels: 2,
          frame_counter: 0,
          frame_type: :configuration,
          history_period: 1,
          redundancy: 0,
          sampling_period: 3600,
          timestamp: 0,
          transmission_period_data: 1,
          transmission_period_keepalive: 86400,
          version: 3
        }
      },
      {
        :parse_hex,
        "20 30 05 01",
        %{
          _comment: "Payload v4 from docs",
        },
        %{
          activation: :otaa,
          adr: 1,
          channels: 2,
          class: :a,
          duty_cycle: 1,
          frame_counter: 1,
          frame_type: :network_config,
          timestamp: 0,
          version: 3
        }
      },
      {
        :parse_hex,
        "37 20 020100 020001",
        %{
          _comment: "Payload v4 from docs",
        },
        %{
          app_version: "2.1.0",
          channels: 1,
          frame_counter: 1,
          frame_type: :software_version,
          rtu_version: "2.0.1",
          timestamp: 0,
          version: 3
        }
      },

      {
        :parse_hex,
        "58 80 01 0032",
        %{
          _comment: "Payload v4 from docs",
        },
        %{
          alarm_ch1: :high_threshold,
          channels: 1,
          frame_counter: 4,
          frame_type: :alarm,
          temp_ch1: 5.0,
          timestamp: 0,
          version: 3
        }
      },

      {
        :parse_hex,
        "58 #{status_2ch_timestamp} 01 0032 00 0032 14ABA3E9",
        %{
          _comment: "Payload v4 from docs with timestamp epoch 2013",
        },
        {%{
          alarm_ch1: :high_threshold,
          alarm_ch2: :no_alarm,
          channels: 2,
          frame_counter: 2,
          frame_type: :alarm,
          temp_ch1: 5.0,
          temp_ch2: 5.0,
          timestamp: 1,
          timestamp_at: ~U[2023-12-17 19:22:17Z],
          version: 3
        }, [measured_at: ~U[2023-12-17 19:22:17Z]]}
      },

      {
        :parse_hex,
        "2F 20 49 01",
        %{
          _comment: "Payload v4 from docs",
        },
        %{
          channels: 1,
          downlink_framcode: 73,
          frame_counter: 1,
          frame_type: :acknowledgement,
          request_status: :success,
          timestamp: 0,
          version: 3
        }
      },

      {
        :parse_hex,
        "31 80",
        %{
          _comment: "Payload v4 from docs with error",
        },
        %{
          channels: 1,
          error: :empty_response,
          frame_counter: 4,
          frame_type: :get_register_response,
          timestamp: 0,
          version: 3
        }
      },
      {
        :parse_hex,
        "31 80 1234 FF 00000000",
        %{
          _comment: "Payload v4 from docs",
        },
        %{
          channels: 1,
          frame_counter: 4,
          frame_type: :get_register_response,
          timestamp: 0,
          values: "1234FF00000000",
          version: 3
        }
      },
      {
        :parse_hex,
        "33 80 04 0140",
        %{
          _comment: "Payload v4 from docs",
        },
        %{
          channels: 1,
          frame_counter: 4,
          frame_type: :set_register_response,
          register_id: 320,
          request_status: :error_invalid_register,
          timestamp: 0,
          version: 3
        }
      },
    ]
  end

  # Helper for testing
  defp test_datetime(iso8601) do
    {:ok, datetime, _} = DateTime.from_iso8601(iso8601)
    datetime
  end

end
