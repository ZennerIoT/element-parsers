defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # Parser for EasyMeter ESYS LR10 LoRaWAN adapter.

  # Changelog:
  #   2020-02-03 [jb]: Initial implementation.
  #   2020-04-17 [jb]: Fixes after testing phase.

  # Payload:
  #   09014553591103A7511E Server-ID
  #
  #   FF				1.8.0 = --- (Leer wenn Tarife gesendet werden)
  #   C6020000	1.8.1 = 710
  #   70010000	1.8.2 = 368
  #
  #   3D010000	2.8.0 = 317 (Leer wenn Tarife gesendet werden)
  #   FF				2.8.1 = ---
  #   FF				2.8.2 = ---
  #
  #   Auch möglich: FFFFFF FFFFFF

  def parse(<<server_id::binary-10, rest::binary>>, %{meta: %{frame_port: 2}}) do

    {acc1, rest} = parse_parts("1-0:1.8.", rest)
    {acc2, rest} = parse_parts("1-0:2.8.", rest)
    {acc3, _est} = parse_parts(nil, rest) # Collecting unexpected suffix binaries

    Enum.map(acc1++acc2++acc3, &Map.merge(&1, %{
      server_id: Base.encode16(server_id, case: :upper),
      meter_id: serverid_to_meterid(server_id),
    }))
  end

  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  # Converts 09014553591103A7511E to 1ESY1161296926
  # Not yet sure it that is correct.
  defp serverid_to_meterid(<<9, 1, name_string::binary-3, number::binary-1, device::32>>) do
    number_string = number |> Base.encode16
    device_string = device |> Integer.to_string |> String.pad_leading(8, "0")
    "1#{name_string}#{number_string}#{device_string}"
  end
  defp serverid_to_meterid(_), do: "unknown"

  # Sending neither main value nor tarif values
  defp parse_parts(_obis_prefix, <<0xFF, 0xFF, 0xFF, rest::binary>>) do
    {[], rest}
  end
  # Sending x.x.0 main value, no tarif values
  defp parse_parts(obis_prefix, <<value::32-little, 0xFF, 0xFF, rest::binary>>) do
    {[obis_row(obis_prefix, value, 0)], rest}
  end
  # Sending x.x.1 and x.x.2 tarif values, no main value.
  defp parse_parts(obis_prefix, <<0xFF, tarif1::32-little, tarif2::32-little, rest::binary>>) do
    {[obis_row(obis_prefix, tarif1, 1), obis_row(obis_prefix, tarif2, 2)], rest}
  end

  defp parse_parts(_obis_prefix, <<>>) do
    {[], <<>>}
  end
  defp parse_parts(_obis_prefix, bin) do
    {[%{error: "invalid_binary_part", binary: "#{inspect bin}"}], <<>>}
  end

  defp obis_row(prefix, value, tarif) do
    obis = "#{prefix}#{tarif}"
    %{
      :obis => obis,
      :value => value,
      obis => value,
    }
  end

  # Define fields with human readable name and a SI unit if available.
  def fields() do
    [
      # The first field should be a numeric value, so it can be used for graphs.
      %{
        field: "value",
        display: "Value",
      },
      %{
        field: "obis",
        display: "OBIS",
      },
      %{
        field: "server_id",
        display: "Server-ID"
      },

      %{
        field: "1-0:1.8.0",
        display: "OBIS 1.8.0"
      },
      %{
        field: "1-0:1.8.1",
        display: "OBIS 1.8.1"
      },
      %{
        field: "1-0:1.8.2",
        display: "OBIS 1.8.2"
      },

      %{
        field: "1-0:2.8.0",
        display: "OBIS 2.8.0"
      },
      %{
        field: "1-0:2.8.1",
        display: "OBIS 2.8.1"
      },
      %{
        field: "1-0:2.8.2",
        display: "OBIS 2.8.2"
      },
    ]
  end

  def tests() do
    [
      {:parse_hex, "09014553591103A7511EFFC6020000700100003D010000FFFF", %{meta: %{frame_port: 2}},
        [
          %{
            :meter_id => "1ESY1161296926",
            :obis => "1-0:1.8.1",
            :server_id => "09014553591103A7511E",
            :value => 710,
            "1-0:1.8.1" => 710
          },
          %{
            :meter_id => "1ESY1161296926",
            :obis => "1-0:1.8.2",
            :server_id => "09014553591103A7511E",
            :value => 368,
            "1-0:1.8.2" => 368
          },
          %{
            :meter_id => "1ESY1161296926",
            :obis => "1-0:2.8.0",
            :server_id => "09014553591103A7511E",
            :value => 317,
            "1-0:2.8.0" => 317
          }
        ]
      },
      {:parse_hex, "09014553591103A7511EFFC6020000700100003D010000FF", %{meta: %{frame_port: 2}},
        [
          %{
            :meter_id => "1ESY1161296926",
            :obis => "1-0:1.8.1",
            :server_id => "09014553591103A7511E",
            :value => 710,
            "1-0:1.8.1" => 710
          },
          %{
            :meter_id => "1ESY1161296926",
            :obis => "1-0:1.8.2",
            :server_id => "09014553591103A7511E",
            :value => 368,
            "1-0:1.8.2" => 368
          },
          %{
            binary: "<<61, 1, 0, 0, 255>>",
            error: "invalid_binary_part",
            meter_id: "1ESY1161296926",
            server_id: "09014553591103A7511E"
          }
        ]
      },
      {:parse_hex, "09014553591103A7511EFFFFFFFFFFFF", %{meta: %{frame_port: 2}},
        []
      },

      # Works
      {:parse_hex, "09014553591103A7511E 3D010000 FF FF FF C6020000 70010000", %{meta: %{frame_port: 2}},
        [
          %{
            :meter_id => "1ESY1161296926",
            :obis => "1-0:1.8.0",
            :server_id => "09014553591103A7511E",
            :value => 317,
            "1-0:1.8.0" => 317
          },
          %{
            :meter_id => "1ESY1161296926",
            :obis => "1-0:2.8.1",
            :server_id => "09014553591103A7511E",
            :value => 710,
            "1-0:2.8.1" => 710
          },
          %{
            :meter_id => "1ESY1161296926",
            :obis => "1-0:2.8.2",
            :server_id => "09014553591103A7511E",
            :value => 368,
            "1-0:2.8.2" => 368
          }
        ]
      },
      # This does not work
      {:parse_hex, "09014553591103A7511E FF FFFF0000 70010000 3D010000 FF FF", %{meta: %{frame_port: 2}},
        [
          %{
            binary: "<<0, 0, 112, 1, 0, 0, 61, 1, 0, 0, 255, 255>>",
            error: "invalid_binary_part",
            meter_id: "1ESY1161296926",
            server_id: "09014553591103A7511E"
          }
        ]
      },
      # or this does not work
      {:parse_hex, "09014553591103A7511E FF C60200FF FF010000 3D010000 FF FF", %{meta: %{frame_port: 2}},
        [
          %{
            :meter_id => "1ESY1161296926",
            :obis => "1-0:1.8.0",
            :server_id => "09014553591103A7511E",
            :value => 182015,
            "1-0:1.8.0" => 182015
          },
          %{
            binary: "<<1, 0, 0, 61, 1, 0, 0, 255, 255>>",
            error: "invalid_binary_part",
            meter_id: "1ESY1161296926",
            server_id: "09014553591103A7511E"
          }
        ]
      },
    ]
  end
end
