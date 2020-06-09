defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # Parser for Sontex 7x9 heat/waerme counters, sending M-Bus data.
  #
  # Supported devices:
  #   * Supercal 739
  #   * Superstatic 749
  #   * Superstatic 789
  #
  # Changelog:
  #   2020-06-09 [jb]: Initial implementation according to "M-Bus Frames 7x9 - LoRAWAN_20190812.pdf"
  #

  # Not checking the frame_port, because its just indicating the length of the payload
  def parse(<<payload::binary>>, %{meta: %{frame_port: frame_port}}) do
    payload
    |> LibWmbus.Dib.parse_dib()
    |> Enum.map(fn
      %{data: %{desc: d, unit: "", value: v}} ->
        %{"#{d}" => v}
      %{data: %{desc: d, unit: u, value: v}} ->
        %{"#{d}_#{u}" => v}
      error ->
        Logger.warn("Invalid result from parse_dibs: #{inspect error}")
        %{}
    end)
    |> Enum.reduce(%{frame_port: frame_port}, fn v, acc -> Map.merge(acc, v) end)
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  # Define fields with human readable name and a SI unit if available.
  def fields() do
    [
      # The first field should be a numeric value, so it can be used for graphs.
      %{
        field: "energy_Wh",
        display: "Energy",
        unit: "Wh",
      },
      %{
        field: "flow",
        display: "Flow",
        unit: "m³/h",
      },
      %{
        field: "power_W",
        display: "Power",
        unit: "W",
      },
      %{
        field: "volume_m³",
        display: "Volume",
        unit: "m³",
      },
      %{
        field: "return_temperature_°C",
        display: "Return Temp.",
        unit: "°C",
      },
      %{
        field: "supply_temperature_°C",
        display: "Supply Temp.",
        unit: "°C",
      },
    ]
  end

  def tests() do
    [
      {
        :parse_hex,
        "0406010000000414330000000C7864713325046D1E08892602FF2C0000820A6CE1F1840A0600000000840A14000000000259E207025D1408023B0000032C000000",
        %{meta: %{frame_port: 2}},
        %{
          :frame_port => 2,
          "date" => ~D[2127-01-01], # Seems to be wrong ON DEVICE
          "datetime" => ~N[2020-06-09 08:30:00], # Correct from device
          "energy_Wh" => 0,
          "fabrication_block" => 25337164,
          "flow_m³/h" => 0.0,
          "power_W" => 0,
          "return_temperature_°C" => 20.68,
          "supply_temperature_°C" => 20.18,
          "unkown_manufacturer_specific" => "00",
          "volume_m³" => 0.0
        }
      }
    ]
  end
end
