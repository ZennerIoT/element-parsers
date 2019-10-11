defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for SensoNeo Single Sensor
  # According to documentation provided by Sensoneo
  # Link: https://sensoneo.com/product/smart-sensors/

  #
  # Changelog
  #   2018-09-13 [as]: Initial version.
  #   2018-09-17 [as]: fixed position value, was switched
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #   2019-10-10 [jb]: New implementation for <= v2 payloads.
  #

  def parse(<<"(", _::binary>> = payload, %{meta: %{frame_port: 1}}) do
    ~r/\(U([0-9.]+)T([0-9+-]+)D([0-9]+)P([0-9]+)\)/
    |> Regex.run(payload)
    |> case do
      [_, voltage, temp, distance, position] ->
        %{
          voltage: String.to_float(voltage),
          temperature: String.to_integer(temp),
          distance: String.to_integer(distance),
          position: position(position)
        }
      _ ->
        Logger.info("Sensoneo Parser: Unknown payload #{inspect payload}")
        []
    end
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  defp position("0"), do: "tilt"
  defp position("1"), do: "normal"
  defp position(_), do: "unknown"

  def fields do
    [
      %{
        field: "voltage",
        display: "Voltage",
        unit: "V"
      },
      %{
        field: "temperature",
        display: "Temperature",
        unit: "°C"
      },
      %{
        field: "distance",
        display: "Distance",
        unit: "cm"
      },
      %{
        field: "position",
        display: "Position"
      },
    ]
  end

  def tests() do
    [
      # Version 1 or 2
      {
        :parse_hex,
        "2855332E3736542B313444323531503129",
        %{meta: %{frame_port: 1}},
        %{
          distance: 251,
          position: "normal",
          temperature: 14,
          voltage: 3.76
        }
      },
    ]
  end
end
