defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Lobaro LoRaWAN GPS Tracker
  #
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
  #   2020-11-25 [jb]: Fixed negative Temperature for v5.0
  #   2020-12-04 [jb]: REWRITE of parser with NEW field names. Fixing wrong parsing between versions.
  #

  # Format for firmware 7.0 - Status message
  def parse(
        <<"GPS", version::binary-3, status, reboot_reason, final_words::8, vbat::16,
          temp::16-signed, state::binary-1>>,
        %{meta: %{frame_port: 1}}
      ) do
    <<v1::8, v2::8, v3::8>> = version

    %{
      payload_version: 7,
      message_type: :status,
      firmware_version: "v#{v1}.#{v2}.#{v3}",
      status: status(status),
      reboot_reason: reboot_reason(reboot_reason),
      final_words: final_words
    }
    |> append_temp_vbat(temp, vbat)
    |> append_state(state)
  end

  # Format for firmware 7.0 - Data message
  def parse(
        <<temp::16-signed, vbat::16, lat_deg::32-signed, lon_deg::32-signed, alt_cm::24-signed,
          state::binary-1, gps_satellites::8, gps_hdop::8, timestamp::40-signed, rest::binary>>,
        %{meta: %{frame_port: 2}}
      ) do
    more =
      case rest do
        <<0::40>> -> %{last_movement_error: :never}
        <<movement::40>> -> %{last_movement: DateTime.to_iso8601(DateTime.from_unix!(movement))}
        _ -> %{}
      end

    %{
      payload_version: 7,
      message_type: :data,
      gps_satellites: gps_satellites,
      gps_hdop: gps_hdop
    }
    |> Map.merge(more)
    |> append_temp_vbat(temp, vbat)
    |> append_state(state)
    |> append_location_deg(lat_deg, lon_deg, alt_cm)
    |> append_measured_at(timestamp)
  end

  # Format for firmware 5.0.x
  def parse(
        <<temp::16-signed, vbat::16-signed, lat_deg::32-signed, lon_deg::32-signed,
          alt_cm::24-signed, state::binary-1, gps_satellites>>,
        %{meta: %{frame_port: 2}}
      ) do
    %{
      payload_version: 5,
      gps_satellites: gps_satellites
    }
    |> append_temp_vbat(temp, vbat)
    |> append_state(state)
    |> append_location_deg(lat_deg, lon_deg, alt_cm)
  end

  # legacy format, firmware 4.x
  def parse(
        <<button_number, temp::16, vbat::16, lat_deg, lat_min, lat_10000::16, long_deg, long_min,
          long_10000::16, rest::binary>>,
        %{meta: %{frame_port: 1}}
      ) do
    # calculate the GPS coordinates
    lat = lat_deg + lat_min / 60 + lat_10000 / 600_000
    lon = long_deg + long_min / 60 + long_10000 / 600_000

    row =
      %{
        payload_version: 4,
        button_number: button_number,
        gps_valid: false
      }
      |> append_temp_vbat(temp, vbat)

    case rest do
      <<gps_valid>> when gps_valid != 0 ->
        row
        |> Map.merge(%{gps_valid: true})
        |> append_location(lat, lon, 0)

      <<_>> ->
        row

      <<>> ->
        row

      _ ->
        raise "Invalid v4 payload"
    end
  end

  def parse(payload, meta) do
    Logger.warn(
      "Could not parse payload #{inspect(payload)} with frame_port #{
        inspect(get_in(meta, [:meta, :frame_port]))
      }"
    )

    []
  end

  def fields() do
    [
      %{
        "field" => "temperature",
        "display" => "Temperature",
        "unit" => "°C"
      },
      %{
        "field" => "battery",
        "display" => "Battery",
        "unit" => "V"
      },
      %{
        "field" => "mode",
        "display" => "Mode"
      },
      %{
        "field" => "reboot_reason",
        "display" => "RebootReason"
      },
      %{
        "field" => "status",
        "display" => "Status"
      },
      %{
        "field" => "message_type",
        "display" => "MessageType"
      },
      %{
        "field" => "gps_valid",
        "display" => "GPS Valid"
      },
      %{
        "field" => "gps_satellites",
        "display" => "GPS Satellites"
      },
      %{
        "field" => "gps_lon",
        "display" => "GPS Lon"
      },
      %{
        "field" => "gps_lat",
        "display" => "GPS Lat"
      },
      %{
        "field" => "gps_alt",
        "display" => "GPS Alt",
        "unit" => "m"
      },
      %{
        "field" => "gps_hdop",
        "display" => "GPS Hdop"
      },
      %{
        "field" => "Timestamp",
        "display" => "Timestamp"
      },
      %{
        "field" => "last_movement",
        "display" => "LastMovement"
      },
      %{
        "field" => "button_number",
        "display" => "ButtonNumber"
      },
      %{
        "field" => "firmware_version",
        "display" => "Firmware"
      },
      %{
        "field" => "payload_version",
        "display" => "Payload"
      }
    ]
  end

  defp append_measured_at({row, meta}, timestamp) do
    case timestamp do
      0 ->
        {Map.merge(row, %{timestamp_error: :never}), meta}

      _ ->
        dt = DateTime.from_unix!(timestamp)

        {
          Map.merge(row, %{
            timestamp: DateTime.to_iso8601(dt)
          }),
          [{:measured_at, dt} | meta]
        }
    end
  end

  defp append_measured_at(row, timestamp) do
    append_measured_at({row, []}, timestamp)
  end

  defp append_location_deg(row, lat_deg, lon_deg, alt_cm) do
    lat = lat_deg / 100_000
    lon = lon_deg / 100_000
    append_location(row, lat, lon, alt_cm)
  end

  defp append_location(%{gps_valid: valid} = row, lat, lon, alt_cm) do
    more = %{
      gps_lat: lat,
      gps_lon: lon,
      gps_alt: alt_cm / 100
    }

    meta = [location: {lon, lat}]

    case valid do
      true -> {Map.merge(row, more), meta}
      false -> {row, []}
    end
  end

  defp append_state(row, <<_rfu::6, op_mode::1, gps_valid::1>>) do
    Map.merge(row, %{
      mode: %{0 => :passive, 1 => :active}[op_mode],
      gps_valid: gps_valid == 1
    })
  end

  defp append_temp_vbat(row, temp, vbat) do
    Map.merge(row, %{
      temperature: temp / 10,
      battery: vbat / 1000
    })
  end

  defp status(status) do
    case status do
      0 -> "OK"
      101 -> "GPS_ERROR"
      102 -> "MEMS_ERROR"
      103 -> "GPS_AND_MEMS_ERROR"
      _ -> "unknown_#{status}"
    end
  end

  defp reboot_reason(reboot_reason) do
    case reboot_reason do
      1 -> "LOW_POWER_RESET"
      2 -> "WINDOW_WATCHDOG_RESET"
      3 -> "INDEPENDENT_WATCHDOG_RESET"
      4 -> "SOFTWARE_RESET"
      5 -> "POWER_ON_RESET"
      6 -> "EXTERNAL_RESET_PIN_RESET"
      7 -> "OBL_RESET"
      _ -> "unknown_#{reboot_reason}"
    end
  end

  def tests() do
    [
      # v7
      {
        :parse_hex,
        "47505307000A0006000C38010201",
        %{meta: %{frame_port: 1}, _comment: "Version 7.x on Port 1 - status message from docs"},
        %{
          final_words: 0,
          payload_version: 7,
          message_type: :status,
          mode: :passive,
          gps_valid: true,
          reboot_reason: "EXTERNAL_RESET_PIN_RESET",
          status: "OK",
          temperature: 25.8,
          battery: 3.128,
          firmware_version: "v7.0.10"
        }
      },
      {
        :parse_hex,
        "00D40BC40051B427000F45DA0016A803060F005ECCCE29",
        %{
          meta: %{frame_port: 2},
          _comment: "Version 7.0 on Port 2 - data message from docs without last_movement"
        },
        {
          %{
            payload_version: 7,
            gps_valid: true,
            gps_satellites: 6,
            gps_lat: 53.54535,
            gps_lon: 10.00922,
            gps_alt: 58.0,
            gps_hdop: 15,
            message_type: :data,
            mode: :active,
            temperature: 21.2,
            timestamp: "2020-05-26T08:07:05Z",
            battery: 3.012
          },
          [measured_at: ~U[2020-05-26 08:07:05Z], location: {10.00922, 53.54535}]
        }
      },
      {
        :parse_hex,
        "00D40BC40051B427000F45DA0016A803060F005ECCCE29005ECCCE20",
        %{
          meta: %{frame_port: 2},
          _comment: "Version 7.1 on Port 2 - data message from docs with last_movement"
        },
        {
          %{
            payload_version: 7,
            gps_valid: true,
            gps_satellites: 6,
            gps_lat: 53.54535,
            gps_lon: 10.00922,
            gps_alt: 58.0,
            gps_hdop: 15,
            last_movement: "2020-05-26T08:06:56Z",
            message_type: :data,
            mode: :active,
            temperature: 21.2,
            timestamp: "2020-05-26T08:07:05Z",
            battery: 3.012
          },
          [measured_at: ~U[2020-05-26 08:07:05Z], location: {10.00922, 53.54535}]
        }
      },

      # v5
      {
        :parse_hex,
        "0001 180D 69351C0F 71093802 00004B 01 06",
        %{meta: %{frame_port: 2}, _comment: "Version 5.x on Port 2 according to TTN parser"},
        {
          %{
            payload_version: 5,
            mode: :passive,
            gps_lat: 17650.88271,
            gps_lon: 18964.2957,
            gps_valid: true,
            gps_satellites: 6,
            gps_alt: 0.75,
            temperature: 0.1,
            battery: 6.157
          },
          [location: {18964.2957, 17650.88271}]
        }
      },
      {
        :parse_hex,
        "f001 f80D f9351C0F f1093802 f0004B 10 01",
        %{meta: %{frame_port: 2}, _comment: "Version 5.x on Port 2 according to TTN parser"},
        {
          %{
            battery: -2.035,
            payload_version: 5,
            gps_satellites: 1,
            gps_valid: false,
            mode: :passive,
            temperature: -409.5
          },
          []
        }
      },

      # v4
      {
        :parse_hex,
        "01 1234 4321 01 02 0304 02 03 0405",
        %{meta: %{frame_port: 1}, _comment: "Version 4.x on Port 1 with missing gps_valid byte"},
        %{
          button_number: 1,
          payload_version: 4,
          gps_valid: false,
          temperature: 466.0,
          battery: 17.185
        }
      },
      {
        :parse_hex,
        "01 1234 4321 01 02 0304 02 03 0405 00",
        %{meta: %{frame_port: 1}, _comment: "Version 4.x on Port 1 without gps valid"},
        %{
          button_number: 1,
          payload_version: 4,
          gps_valid: false,
          temperature: 466.0,
          battery: 17.185
        }
      },
      {
        :parse_hex,
        "01 1234 4321 01 02 0304 02 03 0405 01",
        %{meta: %{frame_port: 1}, _comment: "Version 4.x on Port 1 with valid gps"},
        {
          %{
            battery: 17.185,
            button_number: 1,
            payload_version: 4,
            gps_alt: 0.0,
            gps_lat: 1.03462,
            gps_lon: 2.0517149999999997,
            gps_valid: true,
            temperature: 466.0
          },
          [location: {2.0517149999999997, 1.03462}]
        }
      },
      {
        :parse_hex,
        "00D40BC40051B427000F45DA0016A803060F005ECCCE29",
        %{
          meta: %{frame_port: 2},
          _comment: "Some v7 message from a device"
        },
        {%{
           battery: 3.012,
           payload_version: 7,
           gps_alt: 58.0,
           gps_lat: 53.54535,
           gps_lon: 10.00922,
           gps_satellites: 6,
           gps_valid: true,
           gps_hdop: 15,
           message_type: :data,
           mode: :active,
           temperature: 21.2,
           timestamp: "2020-05-26T08:07:05Z"
         }, [measured_at: ~U[2020-05-26 08:07:05Z], location: {10.00922, 53.54535}]}
      },
      {
        :parse_hex,
        "00D40BC40051B427000F45DA0016A803060F005ECCCE29005ECCCE20",
        %{
          meta: %{frame_port: 2},
          _comment: "Some v7 message from a device with gps_valid: true"
        },
        {%{
           battery: 3.012,
           payload_version: 7,
           gps_alt: 58.0,
           gps_lat: 53.54535,
           gps_lon: 10.00922,
           gps_satellites: 6,
           gps_valid: true,
           gps_hdop: 15,
           last_movement: "2020-05-26T08:06:56Z",
           message_type: :data,
           mode: :active,
           temperature: 21.2,
           timestamp: "2020-05-26T08:07:05Z"
         }, [measured_at: ~U[2020-05-26 08:07:05Z], location: {10.00922, 53.54535}]}
      },
      {
        :parse_hex,
        "00D40BC40051B427000F45DA0016A802060F005ECCCE29005ECCCE20",
        %{
          meta: %{frame_port: 2},
          _comment: "Some v7 message from a device with gps_valid: false"
        },
        {%{
           battery: 3.012,
           payload_version: 7,
           gps_satellites: 6,
           gps_valid: false,
           gps_hdop: 15,
           last_movement: "2020-05-26T08:06:56Z",
           message_type: :data,
           mode: :active,
           temperature: 21.2,
           timestamp: "2020-05-26T08:07:05Z"
         }, [measured_at: ~U[2020-05-26 08:07:05Z]]}
      },
      {
        :parse_hex,
        "47505307000A0006000C38010201",
        %{
          meta: %{frame_port: 1},
          _comment: "Some v7 message from a device"
        },
        %{
          battery: 3.128,
          final_words: 0,
          payload_version: 7,
          gps_valid: true,
          message_type: :status,
          mode: :passive,
          reboot_reason: "EXTERNAL_RESET_PIN_RESET",
          status: "OK",
          temperature: 25.8,
          firmware_version: "v7.0.10"
        }
      },
      {
        :parse_hex,
        "00940C3C00528189000F3322000C890304",
        %{
          meta: %{frame_port: 2},
          _comment: "Some v5 message from a device"
        },
        {%{
           battery: 3.132,
           payload_version: 5,
           gps_alt: 32.09,
           gps_lat: 54.07113,
           gps_lon: 9.9613,
           gps_satellites: 4,
           gps_valid: true,
           mode: :active,
           temperature: 14.8
         }, [location: {9.9613, 54.07113}]}
      },
      {
        :parse_hex,
        "00940C3C00528179000F3327000F960303",
        %{
          meta: %{frame_port: 2},
          _comment: "Some v5 message from a device another"
        },
        {%{
           battery: 3.132,
           payload_version: 5,
           gps_alt: 39.9,
           gps_lat: 54.07097,
           gps_lon: 9.96135,
           gps_satellites: 3,
           gps_valid: true,
           mode: :active,
           temperature: 14.8
         }, [location: {9.96135, 54.07097}]}
      },
      {
        :parse_hex,
        "FFFB0BB9004A2D1A000E40E5007C10030A",
        %{
          meta: %{frame_port: 2},
          _comment: "Some v5 message from a device with negative temperature"
        },
        {
          %{
            battery: 3.001,
            payload_version: 5,
            gps_alt: 317.6,
            gps_lat: 48.6121,
            gps_lon: 9.34117,
            gps_satellites: 10,
            gps_valid: true,
            mode: :active,
            temperature: -0.5
          },
          [location: {9.34117, 48.6121}]
        }
      }
    ]
  end
end
