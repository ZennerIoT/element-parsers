defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Adeunis Temperature Sensor ARF8180BA FW v2.0
  # According to documentation provided by Adeunis
  # Link: https://www.adeunis.com/en/produit/temp/
  # Documentation v2: https://www.adeunis.com/wp-content/uploads/2017/08/TEMP_LoRaWAN_UG_V2.0.0_FR_EN.pdf
  # Documentation v3: https://www.adeunis.com/wp-content/uploads/2020/07/Technical_Reference_Manual_TEMP3_APP_2.0_072020.pdf
  #
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #   2020-08-26 [jb]: Support for v3 payloads.
  #   2020-08-27 [jb]: Added alerts for v3 payloads.
  #

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
    status
    |> parse_status
    |> Map.merge(%{version: 3})
    |> parse_body(code, payload, meta)
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  #----------------------------

  defp parse_status(<<frame_counter::3, channels::1, configuration_problem::1, hw::1, low_bat::1, config::1>>) do
    %{
      configuration_problem: configuration_problem,
      hardware_error: hw,
      low_battery: low_bat,
      configuration_done: config
    }
    |> Enum.filter(fn ({_key, value}) -> value == 1 end)
    |> Enum.into(%{
      frame_counter: frame_counter,
      channels: channels + 1, # 0 => 1 channel, 1 => 2 channels
    })
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
    Enum.map(times, fn ({time, index}) ->
      row = case time do
        {time1, time2} ->
          reading_template |> add_valid_temp(time1, :temp_ch1) |> add_valid_temp(time2, :temp_ch2)
        time1 ->
          reading_template |> add_valid_temp(time1, :temp_ch1)
      end
      {row, [measured_at: Timex.shift(transceived_at, seconds: -1 * (sampling_period * index))]}
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
        {:error, :no_config_available}
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
        "display" => "Temperature Channel1",
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
          temp_ch1: 43.5
        }
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
        },
        [
          {%{version: 3, channels: 1, frame_counter: 4, frame_type: :data, temp_ch1: 43.5},
            [measured_at: ~U[2019-01-01 12:00:00Z]]}
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
          {%{version: 3, channels: 1, frame_counter: 4, frame_type: :data, temp_ch1: 43.5},
            [measured_at: ~U[2019-01-01 12:00:00Z]]},
          {%{
            :version => 3,
            :channels => 1,
            :frame_counter => 4,
            :frame_type => :data,
            "temp_ch1_invalid" => 1
          }, [measured_at: ~U[2019-01-01 11:00:00Z]]},
          {%{version: 3, channels: 1, frame_counter: 4, frame_type: :data, temp_ch1: 43.5},
            [measured_at: ~U[2019-01-01 10:00:00Z]]}
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
            low_battery: 1,
            temp_ch1: 43.5,
            temp_ch2: -10.0
          }, [measured_at: ~U[2019-01-01 12:00:00Z]]},
          {%{
            version: 3,
            channels: 2,
            frame_counter: 4,
            frame_type: :data,
            low_battery: 1,
            temp_ch1: 50.0,
            temp_ch2: -0.1
          }, [measured_at: ~U[2019-01-01 11:00:00Z]]}
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
          {%{version: 3, channels: 1, frame_counter: 4, frame_type: :data, temp_ch1: 43.5},
            [measured_at: ~U[2019-01-01 12:00:00Z]]},
          {%{
            :version => 3,
            :channels => 1,
            :frame_counter => 4,
            :frame_type => :data,
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
            low_battery: 1,
            temp_ch1: 43.5,
            temp_ch2: -10.0
          }, [measured_at: ~U[2019-01-01 12:00:00Z]]},
          {%{
            version: 3,
            channels: 2,
            frame_counter: 4,
            frame_type: :data,
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
