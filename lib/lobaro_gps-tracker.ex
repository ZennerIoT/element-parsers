defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Lobaro LoRaWAN GPS Tracker v5.0
  # According to documentation provided by Lobaro
  # Link: https://www.lobaro.com/portfolio/lorawan-gps-tracker/
  # Documentation: https://www.lobaro.com/download/7315/
  # Documentation: https://docs.lobaro.com/lorawan-sensors/gps-lorawan/index.html
  #
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #   2020-01-10 [tr]: Added Payload Version 5.0.
  #   2020-11-04 [tr]: Added Payload Version 7.0 and 7.1 and disabled output of GPS data of 5.0 version when no sat. is available.
  #

  # Payload version 7.0 and higher status message
  def parse(<<firmware::binary-3, version::binary-3, status::8, reboot_reason::8, _final_words::8, voltage::16, temp::16-signed, flags::binary-1>>, %{meta: %{frame_port: 1}} ) do

    <<v1::8, v2::8, v3::8>> = version
    <<_rfu::6, current_operation_mode::1, position_currently_valid::1>> =flags

    %{
      firmware: firmware,
      version: "v#{v1}.#{v2}.#{v3}",
      status: parse_status(status),
      reboot_reason: parse_reboot_reason(reboot_reason),
      voltage: voltage/1000,
      temp: temp/10,
      current_operation_mode: parse_current_operation_mode(current_operation_mode),
      position_currently_valid: parse_position_valid(position_currently_valid)
    }
  end
  # Payload version 7.0 and higher data message ("movement" not existing between 7.0 and 7.1)
  def parse(<<temp::16-signed, voltage::16, latitude::32-signed, longitude::32-signed, altitude::24-signed, flags::binary-1, sat_cnt::8, hdop::8, timestamp::40-signed, rest::binary>>, %{meta: %{frame_port: 2}} ) do
    <<_rfu::6, current_operation_mode::1, position_currently_valid::1>> =flags

    meta = case position_currently_valid do
    1 -> [location: {longitude/100000, latitude/100000}]
    _-> []
    end

    data = case rest do
    <<movement::40-signed>> -> %{movement: parse_unix_utc(movement)}
    _-> %{}
    end
    |>Map.merge(
    case position_currently_valid do
    1 -> %{
          latitude: latitude/100000,
          longitude: longitude/100000,
          altitude: altitude/100
          }
    _-> %{}
    end
    )
    |>Map.merge(%{
      voltage: voltage/1000,
      temp: temp/10,
      current_operation_mode: parse_current_operation_mode(current_operation_mode),
      position_currently_valid: parse_position_valid(position_currently_valid),
      sat_cnt: sat_cnt,
      hdop: hdop/10,
      timestamp: parse_unix_utc(timestamp),
    })
    {
      data,
      meta
    }
  end

  # parsing packet if GPS fix available
  def parse(<<type::big-8, temp::big-16, vbat::big-16, lat_deg::big-8, lat_min::big-8, lat_10000::big-16, long_deg::big-8, long_min::big-8, long_10000::big-16, 0x01, sat_cnt::8>>, _meta) do

    # calculate the GPS coordinates
    gpslatitude = lat_deg + (lat_min/60) + (lat_10000/600000)
    gpslongitude = long_deg + (long_min/60) + (long_10000/600000)

    mode = case type do
      0 -> "alive"
      1 -> "active"
      _ -> "unknown"
    end

    # return value map
    {%{
      mode: mode,  # active/alive
      temp: temp/10,   # Temperature in °C
      vbat: vbat/1000, # Battery level in V
      sat_cnt: sat_cnt, # received Sattelites
      position: "GPS fix"
      },
    [
      location: {gpslongitude, gpslatitude}, # GPS coordinates as GEO Point for showing in map
    ]}
  end

  # parsing packet if GPS fix available (V 5.0)
  def parse(<<temp::big-16, vbat::big-16, lat_deg::big-32, long_deg::big-32, alt_cm::big-24, status::binary-1, sat_cnt::8>>, _meta) do
    <<last_measurement_isvalid::1, op_mode::1, _::6>> = status
    last_measurement_isvalid = case last_measurement_isvalid do
      0 -> "false"
      1 -> "true"
      _ -> "unknown"
    end

    op_mode = case op_mode do
      0 -> "alive"
      1 -> "active"
      _ -> "unknown"
    end

    meta = case sat_cnt do
    0 -> []
    _ -> [location: {long_deg/100000, lat_deg/100000}]
    end

    data = case sat_cnt do
    0 -> %{}
    _ -> %{
      gpslatitude: lat_deg/100000,
      gpslongitude: long_deg/100000,
      alt_m: alt_cm/100
          }

    end
    |>Map.merge(
    %{
      last_measurement_isvalid: last_measurement_isvalid,
      op_mode: op_mode,  # active/alive
      temp: temp/10,   # Temperature in °C
      vbat: vbat/1000, # Battery level in V
      sat_cnt: sat_cnt, # received Sattelites
      position: "GPS fix"
      }
    )
    # return value map
    {data,
    meta}
  end


  #parsing packet if no GPS fix
  def parse(<<type::big-8, temp::big-16, vbat::big-16, _lat_deg::big-8, _lat_min::big-8, _lat_10000::big-16, _long_deg::big-8, _long_min::big-8, _long_10000::big-16, 0x00, sat_cnt::8>>, _meta) do

    mode = case type do
      0 -> "Scheduled"
      1 -> "Unscheduled"
      _ -> "unknown"
    end
    # return value map
    %{
      mode: mode,  # active/alive
      temp: temp/10,   # Temperature in °C
      vbat: vbat/1000, # Battery level in V
      sat_cnt: sat_cnt, # received Sattelites
      position: "no GPS fix"
      }
  end

  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  defp parse_unix_utc(0) do
      "never"
    end

  defp parse_unix_utc(unix_ts) do
    {status, date}= DateTime.from_unix(unix_ts)
    case status do
      :ok -> date
      _ -> "error"
    end
  end

  defp parse_position_valid(position_currently_valid) do
    case position_currently_valid do
      0 -> "invalid"
      1 -> "valid"
      _ -> "unknown"
    end
  end

  defp parse_current_operation_mode(current_operation_mode) do
    case current_operation_mode do
      0 -> "passive"
      1 -> "active"
      _ -> "unknown"
    end
  end

  defp parse_status(status) do
    case status do
      0 -> "OK"
      101 -> "GPS_ERROR"
      102 -> "MEMS_ERROR"
      103 -> "GPS_AND_MEMS_ERROR"
      _-> "unknown"
    end
  end

  defp parse_reboot_reason(reboot_reason) do
    case reboot_reason do
      1 -> "LOW_POWER_RESET"
      2 -> "WINDOW_WATCHDOG_RESET"
      3	-> "INDEPENDENT_WATCHDOG_RESET"
      4 -> "SOFTWARE_RESET"
      5 -> "POWER_ON_RESET"
      6 -> "EXTERNAL_RESET_PIN_RESET"
      7 -> "OBL_RESET"
      _ -> "unknown"
    end
  end

  def tests() do
    [

      {:parse_hex, "00D40BC40051B427000F45DA0016A803060F005ECCCE29", %{meta: %{frame_port: 2}},{%{
        voltage: 3.012,
        temp: 21.2,
        current_operation_mode: "active",
        position_currently_valid: "valid",
        latitude: 53.54535,
        longitude: 10.00922,
        altitude: 58.0,
        sat_cnt: 6,
        hdop: 1.5,
        timestamp: ~U[2020-05-26 08:07:05Z]
        }, [location: {10.00922, 53.54535}]}
      },

      {:parse_hex, "00D40BC40051B427000F45DA0016A803060F005ECCCE29005ECCCE20", %{meta: %{frame_port: 2}},{%{
        voltage: 3.012,
        temp: 21.2,
        current_operation_mode: "active",
        position_currently_valid: "valid",
        latitude: 53.54535,
        longitude: 10.00922,
        altitude: 58.0,
        sat_cnt: 6,
        hdop: 1.5,
        movement: ~U[2020-05-26 08:06:56Z],
        timestamp: ~U[2020-05-26 08:07:05Z]
        }, [location: {10.00922, 53.54535}]}
      },

      {:parse_hex, "00D40BC40051B427000F45DA0016A802060F005ECCCE29005ECCCE20", %{meta: %{frame_port: 2}},{%{
        voltage: 3.012,
        temp: 21.2,
        current_operation_mode: "active",
        position_currently_valid: "invalid",
        sat_cnt: 6,
        hdop: 1.5,
        movement: ~U[2020-05-26 08:06:56Z],
        timestamp: ~U[2020-05-26 08:07:05Z]
        }, []}
      },

      {:parse_hex, "47505307000A0006000C38010201", %{meta: %{frame_port: 1}},%{
        firmware: "GPS",
        version: "v7.0.10",
        status: "OK",
        reboot_reason: "EXTERNAL_RESET_PIN_RESET",
        voltage: 3.128,
        temp: 25.8,
        current_operation_mode: "passive",
        position_currently_valid: "valid"
        }
      },

      {:parse_hex, "00940C3E00528187000F332600030C0304", %{},{%{
        alt_m: 7.8,
        last_measurement_isvalid: "false",
        op_mode: "alive",
        position: "GPS fix",
        gpslatitude: 54.07111,
        gpslongitude: 9.96134,
        sat_cnt: 4,
        temp: 14.8,
        vbat: 3.134
        }, [location: {9.96134, 54.07111}]}
      },

      {:parse_hex, "00940C3C00528189000F3322000C890304", %{},{%{
        alt_m: 32.09,
        last_measurement_isvalid: "false",
        op_mode: "alive",
        position: "GPS fix",
        gpslatitude: 54.07113,
        gpslongitude: 9.9613,
        sat_cnt: 4,
        temp: 14.8,
        vbat: 3.132
        }, [location: {9.9613, 54.07113}]}
      },

      {:parse_hex, "00940C3C00528179000F3327000F960303", %{},{%{
        alt_m: 39.9,
        last_measurement_isvalid: "false",
        op_mode: "alive",
        position: "GPS fix",
        gpslatitude: 54.07097,
        gpslongitude: 9.96135,
        sat_cnt: 3,
        temp: 14.8,
        vbat: 3.132
        }, [location: {9.96135, 54.07097}]}
        },
    ]
  end

end
