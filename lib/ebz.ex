defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # Parser for eBZ electricity meter.

  # Changelog:
  #   2019-05-09 [tr]: Initial implementation according to "example Payload"
  #   2020-02-03 [jb]: MSCONS compatibility and reformatting.

  # Example Payload:
  #   090145425A01000C02B60108001EFB000000000D185B200208001EFB0000000000000000
  #     Hersteller-ID           090145425A01000C02B6           {1 EBZ01 0078 7126}
  #     Tarif                   010800                         {1.8.0}
  #     Einheit                 1E                             {Wh}
  #     Scaler                  FB                             {*10^-5}
  #     Wert UInt64             000000000D185B20               {219700000 Wh * 10^-5 = 2197 Wh = 2,197 kWh}
  #     Tarif                   020800                         {2.8.0}
  #     Einheit                 1E                             {Wh}
  #     Scaler                  FB                             {*10^-5}
  #     Wert UInt64             0000000000000000               {000000000 Wh}

  def parse(
        <<
          9, 1, "EBZ", number_range::binary-1, device_id::32,
          obis::binary-3,  unit::8,  scaler::8-signed,  value::64,
          obis2::binary-3, unit2::8, scaler2::8-signed, value2::64
        >>,
        %{meta: %{frame_port: 15}}) do

    serial_suffix = device_id |> Integer.to_string |> String.pad_leading(8, "0")
    serial = "1EBZ#{Base.encode16(number_range)}#{serial_suffix}"

    [
      %{
        serial: serial,
        obis: to_obis_string("1-0", obis),
        unit: unit_to_human(unit),
      } |> add_obis_value(value, scaler),
      %{
        serial: serial,
        obis: to_obis_string("1-0", obis2),
        unit: unit_to_human(unit2),
      } |> add_obis_value(value2, scaler2),
    ]
  end

  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  defp add_obis_value(%{unit: "Wh"} = row, value, scaler) do
    obis_value = scale(value, scaler)
    Map.merge(row, %{
      obis_value: obis_value / 1000,  # Need to fix from Wh to kWh for MSCONS
      unit: "kWh",
    })
  end
  defp add_obis_value(row, _value, _scaler), do: row

  defp to_obis_string(prefix, <<o1::8, o2::8, o3::8>>), do: "#{prefix}:#{o1}.#{o2}.#{o3}"

  defp unit_to_human(30), do: "Wh"
  defp unit_to_human(_), do: "unknown"

  defp scale(value, scaler), do: value * :math.pow(10, scaler)


  # Define fields with human readable name and a SI unit if available.
  def fields() do
    [
      # The first field should be a numeric value, so it can be used for graphs.
      %{
        field: "obis_value",
        display: "Value",
      },
      %{
        field: "unit",
        display: "Unit",
      },
      %{
        field: "serial",
        display: "Serial"
      },
      %{
        field: "obis_code",
        display: "OBIS",
      },
    ]
  end

  def tests() do
    [
      {:parse_hex, "090145425A01000C02B60108001EFB000000000D185B200208001EFB0000000000000000", %{meta: %{frame_port: 15}},
        [
          %{obis: "1-0:1.8.0", obis_value: 2.197, serial: "1EBZ0100787126", unit: "kWh"},
          %{obis: "1-0:2.8.0", obis_value: 0.0, serial: "1EBZ0100787126", unit: "kWh"}
        ]
      },
    ]
  end
end
