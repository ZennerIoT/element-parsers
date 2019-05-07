defmodule Parser do
  use Platform.Parsing.Behaviour
  use Bitwise

  require Logger
  require Timex

  #ELEMENT IoT Parser for NAS Luminaire Controller Zhaga UL2030 v0.6.29
  # According to documentation provided by NAS: https://www.nasys.no/wp-content/uploads/Luminaire_Controller_Zhaga_UL2030_6.pdf
  # Payload Description Version v0.6.29

  #
  # Changelog
  #   2019-04-04 [gw]: Initial version

  # Used ports
  # 24, Status, Uplink
  # 25, Usage, Uplink
  # 50, Configuration, Uplink/Downlink
  # 51, Update Mode, Downlink
  # 52, Multicast, Downlink
  # 60, Command, Uplink/Downlink
  # 99, Boot/Debug, Uplink

  ### Status Message ###
  def parse(<<unix_timestamp::32-little, status, rssi::signed, profiles::binary>>, %{meta: %{frame_port: 24}} = _meta) do
    <<
      relay_2::1,
      fw_error::1,
      hw_error::1,
      dig_error::1,
      thr_error::1,
      ldr_error::1,
      dali_connection_error::1,
      dali_error::1
    >> = <<status>>

    map = %{
      type: "status",
      dali: status_to_atom(dali_error),
      dali_connection: status_to_atom(dali_connection_error),
      ldr: status_to_atom(ldr_error),
      thr: status_to_atom(thr_error),
      dig: status_to_atom(dig_error),
      hw: status_to_atom(hw_error),
      fw: status_to_atom(fw_error),
      relay_2: relay_status_to_atom(relay_2),

      timestamp: DateTime.from_unix!(unix_timestamp),
      timestamp_unix: unix_timestamp,
      rssi: rssi,
    }

    map
    |> add_profiles(profiles, 0)
  end

  ### Usage Message ###
  def parse(bin, %{meta: %{frame_port: 25}} = _meta) do
    read_usage_messages(bin)
  end

  ### Config message responses (fPort 50) ###

  # set sunrise/sunset response
  def parse(<<0x06FFFFFFFFFFFF::56>>, %{meta: %{frame_port: 50}}) do
    %{
      type: "config",
      info: "sunrise/sunset config disabled"
    }
  end
  def parse(<<0x06, sunrise_offset::signed, sunset_offset::signed, latitude::little-16, longitude::little-16>>, %{meta: %{frame_port: 50}}) do
    %{
      type: "config",
      sunrise_offset: sunrise_offset,
      sunset_offset: sunset_offset,
      latitude: latitude / 100,
      longitude: longitude / 100
    }
  end

  # set status report interval response
  def parse(<<0x07, interval::little-32>>, %{meta: %{frame_port: 50}}) do
    %{
      type: "config",
      status_report_interval: interval
    }
  end

  # apply profile response
  def parse(<<0x08, profile_id, profile_seq, addr, days_active, rest::binary>>, %{meta: %{frame_port: 50}}) do
    map =
      %{
        type: "config",
        profile_id: profile_id,
        profile_seq: profile_seq,
        dali_addr: profile_addr_to_dali_addr(<<addr>>),
        holidays_active: is_day_active(days_active, 1),
        mondays_active: is_day_active(days_active, 2),
        tuesdays_active: is_day_active(days_active, 4),
        wednesdays_active: is_day_active(days_active, 8),
        thursdays_active: is_day_active(days_active, 16),
        fridays_active: is_day_active(days_active, 32),
        saturdays_active: is_day_active(days_active, 64),
        sundays_active: is_day_active(days_active, 128),
      }

    add_dim_steps(map, rest, 1)
  end

  defp add_dim_steps(map, <<step_time, dim_level, rest::binary>>, i) do
    {:ok, midnight} = NaiveDateTime.new(0, 1, 1, 0, 0, 0)
    step_time =
      midnight
      |> Timex.to_datetime()
      |> Timex.shift(minutes: step_time * 10)
      |> Timex.format!("{h24}:{m}")

    map
    |> Map.put("dim_step_#{i}_time", step_time)
    |> Map.put("dim_step_#{i}_level", dim_level)
    |> add_dim_steps(rest, i + 1)
  end
  defp add_dim_steps(map, <<>>, _), do: map

  # set time response
  def parse(<<0x09, timestamp::little-32>>, %{meta: %{frame_port: 50}}) do
    %{
      type: "config",
      timestamp_unix: timestamp,
      timestamp: DateTime.from_unix!(timestamp)
    }
  end

  ### Command Message Responses (fPort 60) ###

  # DALI status (can contain up to 25 devices)
  def parse(<<0x00, rest::binary>>, %{meta: %{frame_port: 60}}) do
    parse_dali_status_recursively(rest)
  end

  # set dim level
  def parse(<<0x01, addr, dim_level>>, %{meta: %{frame_port: 60}}) do
    %{
      type: "command",
      dali_address: profile_addr_to_dali_addr(<<addr>>),
      dim_level: dim_level
    }
  end

  # Custom DALI request response
  def parse(<<0x03, rest::binary>>, %{meta: %{frame_port: 60}}) do
    parse_custom_dali_response_recursively(rest)
  end

  ### Boot/Debug message ###

  # is actually 15 bytes long, instead of 14 according to the docs
  def parse(<<0x00, serial::little-32, fw::24, timestamp::little-32, hw, opt, _rest::binary>>, %{meta: %{frame_port: 99}} = _meta) do
    <<major::8, minor::8, patch::8>> = <<fw::24>>
    %{
      type: "debug",
      status: "boot",
      serial: Base.encode16(<<serial::32>>),
      firmware: "#{major}.#{minor}.#{patch}",
      timestamp: DateTime.from_unix!(timestamp),
      timestamp_unix: timestamp,
      hw_setup: hw,
      opt: opt
    }
  end
  def parse(<<0x01, _rest::binary>>, %{meta: %{frame_port: 99}} = _meta) do
    %{
      type: "debug",
      status: "shutdown"
    }
  end
  def parse(<<0x10, 2::8, _rest::binary>>, %{meta: %{frame_port: 99}} = _meta) do
    %{
      type: "debug",
      status: "error",
      error_code: 2,
      error: "Multiple unconfigured drivers detected"
    }
  end
  def parse(<<0x10, error, _rest::binary>>, %{meta: %{frame_port: 99}} = _meta) do
    %{
      type: "debug",
      status: "error",
      error_code: error,
      error: "Unknown error"
    }
  end

  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with meta #{inspect meta}")
    []
  end

  ### Common helper

  defp profile_addr_to_dali_addr(<<0xFE>>), do: "Broadcast"
  defp profile_addr_to_dali_addr(<<1::1, 0::1, 0::1, dali_group_addr::4, 0::1>>), do: "Group address #{dali_group_addr}"
  defp profile_addr_to_dali_addr(<<0::1, dali_single_addr::6, 0::1>>), do: "Single device #{dali_single_addr}"
  defp profile_addr_to_dali_addr(other) do
    Logger.info("Unknown DALI address #{inspect other}")
    ""
  end

  ### Command Message Response Helper ###

  defp parse_dali_status_recursively(<<addr, status, rest::binary>>) do
    result =
      %{
        type: "command",
        dali_address: profile_addr_to_dali_addr(<<addr>>),
        dali_status: parse_dali_status(<<status>>)
      }
    [result] ++ parse_dali_status_recursively(rest)
  end
  defp parse_dali_status_recursively(<<>>), do: []

  defp parse_dali_status(<<0x04>>), do: "Ballast is off"
  defp parse_dali_status(<<0x02>>), do: "Lamp is burned out"
  defp parse_dali_status(<<other>>), do: "Unknown dali status #{inspect other}"

  ### Custom DALI Request Response helper ###

  defp parse_custom_dali_response_recursively(<<addr, query, answer, rest::binary>>) do
    result =
      %{
        type: "command",
        dali_address: profile_addr_to_dali_addr(<<addr>>),
        dali_query: dali_query_to_string(query),
        dali_response: parse_dali_response(query, answer)
      }
    [result] ++ parse_custom_dali_response_recursively(rest)
  end
  defp parse_custom_dali_response_recursively(<<>>), do: []

  defp dali_query_to_string(161), do: "Max level"
  defp dali_query_to_string(162), do: "Min level"
  defp dali_query_to_string(163), do: "Power on level"
  defp dali_query_to_string(164), do: "Failure level"
  defp dali_query_to_string(165), do: "Fade time/rate"
  defp dali_query_to_string(_), do: "Unknown query"

  defp parse_dali_response(165, answer), do: "<#{answer / 10}s / 45 steps/s"
  defp parse_dali_response(query, answer) when query <= 164 and query >= 161, do: answer
  defp parse_dali_response(_, answer), do: answer

  ### Status Message helper ###

  defp add_profiles(map, <<id, seq, addr, days_active, current_level, rest::binary>>, i) do
    map
    |> Map.put("profile_#{i}_id", id)
    |> Map.put("profile_#{i}_seq", seq)
    |> Map.put("profile_#{i}_addr", profile_addr_to_dali_addr(<<addr>>))
    |> Map.put("profile_#{i}_current_dim_level", current_level)
    |> Map.put("profile_#{i}_holidays", is_day_active(days_active, 1))
    |> Map.put("profile_#{i}_mondays", is_day_active(days_active, 2))
    |> Map.put("profile_#{i}_tuesdays", is_day_active(days_active, 4))
    |> Map.put("profile_#{i}_wednesdays", is_day_active(days_active, 8))
    |> Map.put("profile_#{i}_thursdays", is_day_active(days_active, 16))
    |> Map.put("profile_#{i}_fridays", is_day_active(days_active, 32))
    |> Map.put("profile_#{i}_saturdays", is_day_active(days_active, 64))
    |> Map.put("profile_#{i}_sundays", is_day_active(days_active, 128))
    |> add_profiles(rest, i + 1)
  end

  defp add_profiles(map, <<>>, _), do: map

  defp is_day_active(days_active, day) do
    only_selected_day = Bitwise.band(days_active, day)
    cond do
      only_selected_day == 0 -> "not active"
      only_selected_day > 0 -> "active"
    end
  end

  defp status_to_atom(0), do: :ok
  defp status_to_atom(1), do: :alert

  defp relay_status_to_atom(0), do: :off
  defp relay_status_to_atom(1), do: :on

  ### Usage Message helper ###

  defp read_usage_messages(<<addr, reported_fields, rest::binary>>) do
    <<
      _rfu::2,
      system_voltage::1, # uint8, V
      power_factor_instant::1, # uint8, divide by 100
      load_side_energy_instant::1, # uint16, W
      load_side_energy_total::1, # uint32, Wh
      active_energy_instant::1, # uint16, W
      active_energy_total::1 # uint32, Wh
    >> = <<reported_fields>>

    {map, new_rest} =
      {
        %{
          type: "usage",
          dali_address: profile_addr_to_dali_addr(<<addr>>)
        }, rest
      }
      |> add_active_energy_total(active_energy_total)
      |> add_active_energy_instant(active_energy_instant)
      |> add_load_side_energy_total(load_side_energy_total)
      |> add_load_side_energy_instant(load_side_energy_instant)
      |> add_power_factor_instant(power_factor_instant)
      |> add_system_voltage(system_voltage)

    [map] ++ read_usage_messages(new_rest)
  end
  defp read_usage_messages(<<>>), do: []

  defp add_active_energy_total({map, <<active_energy_total::little-32, rest::binary>>}, 1) do
    {
      Map.put(map, :active_energy_total, active_energy_total),
      rest
    }
  end
  defp add_active_energy_total(map_with_rest_tuple, 0), do: map_with_rest_tuple

  defp add_active_energy_instant({map, <<active_energy_instant::little-16, rest::binary>>}, 1) do
    {
      Map.put(map, :active_energy_instant, active_energy_instant),
      rest
    }
  end
  defp add_active_energy_instant(map_with_rest_tuple, 0), do: map_with_rest_tuple

  defp add_load_side_energy_total({map, <<load_side_energy_total::little-32, rest::binary>>}, 1) do
    {
      Map.put(map, :load_side_energy_total, load_side_energy_total),
      rest
    }
  end
  defp add_load_side_energy_total(map_with_rest_tuple, 0), do: map_with_rest_tuple

  defp add_load_side_energy_instant({map, <<load_side_energy_instant::little-16, rest::binary>>}, 1) do
    {
      Map.put(map, :load_side_energy_instant, load_side_energy_instant),
      rest
    }
  end
  defp add_load_side_energy_instant(map_with_rest_tuple, 0), do: map_with_rest_tuple

  defp add_power_factor_instant({map, <<power_factor_instant::8, rest::binary>>}, 1) do
    {
      Map.put(map, :power_factor_instant, power_factor_instant / 100),
      rest
    }
  end
  defp add_power_factor_instant(map_with_rest_tuple, 0), do: map_with_rest_tuple

  defp add_system_voltage({map, <<system_voltage::8, rest::binary>>}, 1) do
    {
      Map.put(map, :system_voltage, system_voltage),
      rest
    }
  end
  defp add_system_voltage(map_with_rest_tuple, 0), do: map_with_rest_tuple

  def fields() do
    [
      %{
        "field" => "type",
        "display" => "Messagetype",
      },
      # Status Message
      %{
        "field" => "dali",
        "display" => "Dali state"
      },
      %{
        "field" => "dali_connection",
        "display" => "Dali connection state"
      },
      %{
        "field" => "ldr",
        "display" => "LDR state"
      },
      %{
        "field" => "thr",
        "display" => "THR state"
      },
      %{
        "field" => "dig",
        "display" => "DIG state"
      },
      %{
        "field" => "hw",
        "display" => "Hardware state"
      },
      %{
        "field" => "fw",
        "display" => "Firmware state"
      },
      %{
        "field" => "relay_2",
        "display" => "Relay 2 state"
      },
      %{
        "field" => "timestamp",
        "display" => "Timestamp"
      },
      %{
        "field" => "timestamp_unix",
        "display" => "Timestamp Unix"
      },
      %{
        "field" => "rssi",
        "display" => "RSSI",
        "unit" => "dBm"
      },
      # Usage Message
      %{
        "field" => "dali_address",
        "display" => "Dali address"
      },
      %{
        "field" => "active_energy_total",
        "display" => "Active energy total",
        "unit" => "Wh"
      },
      %{
        "field" => "active_energy_instant",
        "display" => "Active energy consumption",
        "unit" => "W"
      },
      %{
        "field" => "load_side_energy_total",
        "display" => "Load side energy total",
        "unit" => "Wh"
      },
      %{
        "field" => "load_side_energy_instant",
        "display" => "Load side energy consumption",
        "unit" => "W"
      },
      %{
        "field" => "power_factor_instant",
        "display" => "Power factor instant",
      },
      %{
        "field" => "system_voltage",
        "display" => "System voltage",
        "unit" => "V"
      },
    ]
  end

  def tests() do
    [
      ### Status Message (sample from docs) ###
      {
        :parse_hex, "28E29B59018E0416FE1E32022AFEE132", %{meta: %{frame_port: 24}}, %{
          "profile_0_id" => 4,
          "profile_0_seq" => 22,
          "profile_0_addr" => "Broadcast",
          "profile_0_holidays" => "not active",
          "profile_0_mondays" => "active",
          "profile_0_tuesdays" => "active",
          "profile_0_wednesdays" => "active",
          "profile_0_thursdays" => "active",
          "profile_0_fridays" => "not active",
          "profile_0_saturdays" => "not active",
          "profile_0_sundays" => "not active",
          "profile_0_current_dim_level" => 50,
          "profile_1_id" => 2,
          "profile_1_seq" => 42,
          "profile_1_addr" => "Broadcast",
          "profile_1_holidays" => "active",
          "profile_1_mondays" => "not active",
          "profile_1_tuesdays" => "not active",
          "profile_1_wednesdays" => "not active",
          "profile_1_thursdays" => "not active",
          "profile_1_fridays" => "active",
          "profile_1_saturdays" => "active",
          "profile_1_sundays" => "active",
          "profile_1_current_dim_level" => 50,
          dali: :alert,
          dali_connection: :ok,
          ldr: :ok,
          thr: :ok,
          dig: :ok,
          hw: :ok,
          fw: :ok,
          relay_2: :off,
          rssi: -114,
          timestamp_unix: 1503388200,
          timestamp: DateTime.from_unix!(1503388200),
          type: "status"
        }
      },
      ### Usage message (sample from docs) ###
      {
        :parse_hex, "04030000000000000603151400000000", %{meta: %{frame_port: 25}}, [
          %{
            active_energy_instant: 0,
            active_energy_total: 0,
            dali_address: "Single device 2",
            type: "usage"
          },
          %{
            active_energy_instant: 0,
            active_energy_total: 5141,
            dali_address: "Single device 3",
            type: "usage"
          }
        ]
      },
      { # real payload from device
        :parse_hex, "011F4E04000006004D04000007002A", %{meta: %{frame_port: 25}}, [
          %{
            active_energy_instant: 6,
            active_energy_total: 1102,
            dali_address: "",
            load_side_energy_instant: 7,
            load_side_energy_total: 1101,
            power_factor_instant: 0.42,
            type: "usage"
          }
        ]
      },
      ### config message responses ###
      {# sunrise/sunset config was disabled
        :parse_hex, "06FFFFFFFFFFFF", %{meta: %{frame_port: 50}}, %{
          type: "config",
          info: "sunrise/sunset config disabled"
        }
      },
      { # sunrise/sunset config sample from doc
        :parse_hex, "06E21E9619B309", %{meta: %{frame_port: 50}}, %{
          type: "config",
          sunrise_offset: -30,
          sunset_offset: 30,
          latitude: 65.50,
          longitude: 24.83
        }
      },
      { # set status report interval
        :parse_hex, "0708070000", %{meta: %{frame_port: 50}}, %{
          type: "config",
          status_report_interval: 1800
        }
      },
      { # apply profile with dim sequence (sample from doc, except fridays also active)
        :parse_hex, "081603FE3E061E24503C1E6650", %{meta: %{frame_port: 50}}, %{
          "dim_step_1_time" => "01:00",
          "dim_step_1_level" => 30,
          "dim_step_2_time" => "06:00",
          "dim_step_2_level" => 80,
          "dim_step_3_time" => "10:00",
          "dim_step_3_level" => 30,
          "dim_step_4_time" => "17:00",
          "dim_step_4_level" => 80,
          type: "config",
          profile_id: 22,
          profile_seq: 3,
          dali_addr: "Broadcast",
          holidays_active: "not active",
          mondays_active: "active",
          tuesdays_active: "active",
          wednesdays_active: "active",
          thursdays_active: "active",
          fridays_active: "active",
          saturdays_active: "not active",
          sundays_active: "not active"
        }
      },
      { # set device time
        :parse_hex, "09782BCC5C", %{meta: %{frame_port: 50}}, %{
          type: "config",
          timestamp: DateTime.from_unix!(1556884344),
          timestamp_unix: 1556884344,
        }
      },
      ### Command message responses ###
      { # Get DALI connection status with one device
        :parse_hex, "000204", %{meta: %{frame_port: 60}}, [
          %{
            type: "command",
            dali_address: "Single device 1",
            dali_status: "Ballast is off"
          }
        ]
      },
      { # Get DALI connection status with multiple devices (sample from docs)
        :parse_hex, "00020406020C02", %{meta: %{frame_port: 60}}, [
          %{
            type: "command",
            dali_address: "Single device 1",
            dali_status: "Ballast is off"
          },
          %{
            type: "command",
            dali_address: "Single device 3",
            dali_status: "Lamp is burned out"
          },
          %{
            type: "command",
            dali_address: "Single device 6",
            dali_status: "Lamp is burned out"
          }
        ]
      },
      {# set dimming level to 0
        :parse_hex, "01FE00", %{meta: %{frame_port: 60}}, %{
          type: "command",
          dali_address: "Broadcast",
          dim_level: 0
        }
      },
      {# set dimming level to 100
        :parse_hex, "01FE64", %{meta: %{frame_port: 60}}, %{
          type: "command",
          dali_address: "Broadcast",
          dim_level: 100
        }
      },
      { # custom DALI response (sample from docs)
        :parse_hex, "0348A1FE48A2A848A3FE48A4FE48A507", %{meta: %{frame_port: 60}}, [
          %{
            type: "command",
            dali_address: "Single device 36",
            dali_query: "Max level",
            dali_response: 254
          },
          %{
            type: "command",
            dali_address: "Single device 36",
            dali_query: "Min level",
            dali_response: 168
          },
          %{
            type: "command",
            dali_address: "Single device 36",
            dali_query: "Power on level",
            dali_response: 254
          },
          %{
            type: "command",
            dali_address: "Single device 36",
            dali_query: "Failure level",
            dali_response: 254
          },
          %{
            type: "command",
            dali_address: "Single device 36",
            dali_query: "Fade time/rate",
            dali_response: "<0.7s / 45 steps/s"
          },
        ]
      },
      ### Boot/debug message ###
      { # boot (sample from docs)
        :parse_hex, "00FF001047000405C31441590500", %{meta: %{frame_port: 99}}, %{
          type: "debug",
          status: "boot",
          serial: "471000FF",
          firmware: "0.4.5",
          timestamp: DateTime.from_unix!(1497437379),
          timestamp_unix: 1497437379,
          hw_setup: 5,
          opt: 0
        }
      },
      { # shutdown (sample NOT from docs)
        :parse_hex, "01", %{meta: %{frame_port: 99}}, %{
          type: "debug",
          status: "shutdown"
        }
      },
      { # error 02 (sample NOT from docs)
        :parse_hex, "1002", %{meta: %{frame_port: 99}}, %{
          type: "debug",
          status: "error",
          error_code: 2,
          error: "Multiple unconfigured drivers detected"
        }
      },
      { # error unknown (sample NOT from docs)
        :parse_hex, "1000", %{meta: %{frame_port: 99}}, %{
          type: "debug",
          status: "error",
          error_code: 0,
          error: "Unknown error"
        }
      }
    ]
  end

end
