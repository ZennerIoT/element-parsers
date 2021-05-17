defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # ELEMENT IoT Parser for Pepperls+Fuchs WILSEN.sonic.level Sensor
  #
  # Name: Pepperl+Fuchs WILSEN.sonic.level
  # Changelog:
  #   2020-07-06 [tr]: Initial implementation according to Document "TDOCT-6836__GER.docx"
  #   2021-05-17 [jb]: Updated according to Document "tdoct7056__eng.docx", added error handling.
  #

  def parse(<<payload::binary>>, %{meta: %{frame_port: 1}}) do
    template =
      case byte_size(payload) do
        20 -> %{type: :sensor}
        34 -> %{type: :sensor_and_gps}
        38 -> %{type: :heartbeat}
        sz -> %{type: "unknown_length_#{sz}"}
      end

    template
    |> parse_part(payload)
    |> handle_sensor_error
    |> handle_location
  end

  def parse(payload, meta) do
    Logger.warn(
      "Could not parse payload #{inspect(payload)} with frame_port #{
        inspect(get_in(meta, [:meta, :frame_port]))
      }"
    )

    []
  end

  defp handle_sensor_error(%{fillinglvl_percent: 100, proxx_cm: 0} = row) do
    Map.merge(row, %{
      sensor_error: :object_too_close
    })
  end

  defp handle_sensor_error(%{proxx_cm: 65535} = row) do
    Map.merge(row, %{
      sensor_error: :object_too_far
    })
  end

  defp handle_sensor_error(row), do: row

  defp handle_location(%{longitude: lon, latitude: lat} = row) do
    {row, [location: {lon, lat}]}
  end

  defp handle_location(row) do
    row
  end

  defp parse_part(parsed, <<_::binary-1, 0x0B01::16, proxx_cm::16, rest::binary>>) do
    parsed
    |> Map.merge(%{
      proxx_cm: proxx_cm
    })
    |> parse_part(rest)
  end

  defp parse_part(parsed, <<_::binary-1, 0x0B06::16, fillinglvl_percent::8, rest::binary>>) do
    parsed
    |> Map.merge(%{
      fillinglvl_percent: fillinglvl_percent
    })
    |> parse_part(rest)
  end

  defp parse_part(parsed, <<_::binary-1, 0x0201::16, temp_celsius::float-32, rest::binary>>) do
    parsed
    |> Map.merge(%{
      temp_celsius: temp_celsius
    })
    |> parse_part(rest)
  end

  defp parse_part(parsed, <<_::binary-1, 0x5101::16, battery_vol::8, rest::binary>>) do
    parsed
    |> Map.merge(%{
      battery_vol: battery_vol / 10
    })
    |> parse_part(rest)
  end

  defp parse_part(parsed, <<_::binary-1, 0x5001::16, latitude::32, rest::binary>>) do
    parsed
    |> Map.merge(
      case latitude do
        0 ->
          %{gps_error: :invalid_position}

        _ ->
          %{
            latitude: latitude / 1_000_000
          }
      end
    )
    |> parse_part(rest)
  end

  defp parse_part(parsed, <<_::binary-1, 0x5002::16, longitude::32, rest::binary>>) do
    parsed
    |> Map.merge(
      case longitude do
        0 ->
          %{gps_error: :invalid_position}

        _ ->
          %{
            longitude: longitude / 1_000_000
          }
      end
    )
    |> parse_part(rest)
  end

  defp parse_part(parsed, <<_::binary-1, 0x2A25::16, serialNr::binary-14, rest::binary>>) do
    parsed
    |> Map.merge(%{
      serialNr: serialNr
    })
    |> parse_part(rest)
  end

  defp parse_part(parsed, <<_::binary-1, 0x3101::16, lora_count::16, rest::binary>>) do
    parsed
    |> Map.merge(%{
      lora_count: lora_count
    })
    |> parse_part(rest)
  end

  defp parse_part(parsed, <<_::binary-1, 0x3102::16, gps_count::16, rest::binary>>) do
    parsed
    |> Map.merge(%{
      gps_count: gps_count
    })
    |> parse_part(rest)
  end

  defp parse_part(parsed, <<_::binary-1, 0x3103::16, us_sensor_count::32, rest::binary>>) do
    parsed
    |> Map.merge(%{
      us_sensor_count: us_sensor_count
    })
    |> parse_part(rest)
  end

  defp parse_part(parsed, <<_::binary-1, _::binary-2, _rest>>) do
    parsed
    |> Map.merge(%{
      parse_error: "Stopped Parsing due to unknown value ID"
    })
  end

  defp parse_part(parsed, <<>>) do
    parsed
  end

  defp parse_part(parsed, unknown) do
    Map.merge(parsed, %{
      unparseable_binary: Base.encode16(unknown)
    })
  end

  def fields() do
    [
      %{
        field: "proxx_cm",
        display: "Abstandswert",
        unit: "cm"
      },
      %{
        field: "fillinglvl_percent",
        display: "Füllstand",
        unit: "%"
      },
      %{
        field: "temp_celsius",
        display: "Temperatur",
        unit: "°C"
      },
      %{
        field: "battery_vol",
        display: "Batteriezustand",
        unit: "V"
      },
      %{
        field: "latitude",
        display: "Breitengrad"
      },
      %{
        field: "longitude",
        display: "Längengrad"
      },
      %{
        field: "serialNr",
        display: "P+F Seriennummer"
      },
      %{
        field: "loca_count",
        display: "Anzahl LoRa-Übertragungen"
      },
      %{
        field: "us_sensor_count",
        display: "Anzahl Ultraschallmessungen",
        unit: "°C"
      },
      %{
        field: "gps_count",
        display: "Anzahl GPS-Positionsbestimmungen"
      }
    ]
  end

  def tests() do
    [
      {
        :parse_hex,
        "040B010000030B066406020141CB954403510124",
        %{
          meta: %{frame_port: 1},
          _comment: "From docs"
        },
        %{
          battery_vol: 3.6,
          fillinglvl_percent: 100,
          proxx_cm: 0,
          sensor_error: :object_too_close,
          temp_celsius: 25.44788360595703,
          type: :sensor
        }
      },
      {
        :parse_hex,
        "040B010024030B066406020141CA1FDC035101260650010000000006500200000000",
        %{
          meta: %{frame_port: 1},
          _comment: "From docs"
        },
        %{
          battery_vol: 3.8,
          fillinglvl_percent: 100,
          gps_error: :invalid_position,
          proxx_cm: 36,
          temp_celsius: 25.26555633544922,
          type: :sensor_and_gps
        }
      },
      {
        :parse_hex,
        "102A255F50465F4C6F52615F56312E315F0431011EE104310200050631030000217E03510126",
        %{
          meta: %{frame_port: 1},
          _comment: "From docs"
        },
        %{
          battery_vol: 3.8,
          gps_count: 5,
          type: :heartbeat,
          lora_count: 7905,
          serialNr: "_PF_LoRa_V1.1_",
          us_sensor_count: 8574
        }
      },
      {
        :parse_hex,
        "04 0B 01 00 41 03 0B 06 59 06 02 01 41 00 00 00 03 51 01 23",
        %{
          meta: %{frame_port: 1},
          _comment: "From docs, payload 1"
        },
        %{
          battery_vol: 3.5,
          fillinglvl_percent: 89,
          proxx_cm: 65,
          temp_celsius: 8.0,
          type: :sensor
        }
      },
      {
        :parse_hex,
        "04 0B 01 00 41 03 0B 06 59 06 02 01 41 01 99 9A 03 51 01 22 06 50 02 00 7D 21 78 06 50 01 02 F1 C3 DF",
        %{
          meta: %{frame_port: 1},
          _comment: "From docs, payload 2"
        },
        {%{
           battery_vol: 3.4,
           fillinglvl_percent: 89,
           latitude: 49.398751,
           longitude: 8.200568,
           proxx_cm: 65,
           temp_celsius: 8.100000381469727,
           type: :sensor_and_gps
         }, [location: {8.200568, 49.398751}]}
      },
      {
        :parse_hex,
        "10 2A 25 34 38 30 30 30 30 30 30 36 32 38 37 38 33 04 31 01 07 01 04 31 02 03 22 06 31 03 00 00 0F 1C 03 51 01 23",
        %{
          meta: %{frame_port: 1},
          _comment: "From docs, payload 3 (heartbeat)"
        },
        %{
          battery_vol: 3.5,
          gps_count: 802,
          type: :heartbeat,
          lora_count: 1793,
          serialNr: "48000000628783",
          us_sensor_count: 3868
        }
      },
      {
        :parse_hex,
        "CAFEBABE",
        %{
          meta: %{frame_port: 1},
          _comment: "From docs, payload 3 (heartbeat)"
        },
        %{
          parse_error: "Stopped Parsing due to unknown value ID",
          type: "unknown_length_4"
        }
      },
      {
        :parse_hex,
        "AA",
        %{
          meta: %{frame_port: 1},
          _comment: "From docs, payload 3 (heartbeat)"
        },
        %{type: "unknown_length_1", unparseable_binary: "AA"}
      }
    ]
  end
end
