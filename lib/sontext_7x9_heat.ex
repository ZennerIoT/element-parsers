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
  #   2020-06-26 [jb]: Using memory_address, sub_device and tariff in reading keys.
  #

  # Not checking the frame_port, because its just indicating the length of the payload
  def parse(<<payload::binary>>, %{meta: %{frame_port: frame_port}}) do
    payload
    |> LibWmbus.Dib.parse_dib()
    |> Enum.map(fn
      %{memory_address: m, sub_device: sd, tariff: t, data: %{desc: d, unit: "", value: v}} ->
        %{"#{m}_#{sd}_#{t}_#{d}" => v}
      %{memory_address: m, sub_device: sd, tariff: t, data: %{desc: d, unit: u, value: v}} ->
        %{"#{m}_#{sd}_#{t}_#{d}_#{u}" => v}
      error ->
        Logger.warn("Invalid result from parse_dibs: #{inspect error}")
        %{}
    end)
    |> Enum.reduce(%{frame_port: frame_port}, &Map.merge(&2, &1))
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
        field: "0_0_0_energy_Wh",
        display: "Energy",
        unit: "Wh",
      },
      %{
        field: "0_0_0_flow_m³/h",
        display: "Flow",
        unit: "m³/h",
      },
      %{
        field: "0_0_0_power_W",
        display: "Power",
        unit: "W",
      },
      %{
        field: "0_0_0_volume_m³",
        display: "Volume",
        unit: "m³",
      },
      %{
        field: "0_0_0_return_temperature_°C",
        display: "Return Temp.",
        unit: "°C",
      },
      %{
        field: "0_0_0_supply_temperature_°C",
        display: "Supply Temp.",
        unit: "°C",
      },
      %{
        field: "0_0_0_datetime",
        display: "DateTime",
      },
      %{
        field: "0_0_0_fabrication_block",
        display: "Fabrication-Block",
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
          "0_0_0_datetime" => ~N[2020-06-09 08:30:00],
          "0_0_0_energy_Wh" => 1000,
          "0_0_0_fabrication_block" => 25337164,
          "0_0_0_flow_m³/h" => 0.0,
          "0_0_0_power_W" => 0,
          "0_0_0_return_temperature_°C" => 20.68,
          "0_0_0_supply_temperature_°C" => 20.18,
          "0_0_0_unkown_manufacturer_specific" => "00",
          "0_0_0_volume_m³" => 0.51,
          "20_0_0_date" => ~D[2127-01-01],
          "20_0_0_energy_Wh" => 0,
          "20_0_0_volume_m³" => 0.0
        }
      },
      {
        :parse_hex,
        "0406C90000000414980200000C7821713325046D080B9A2602FF2C0000820A6CE1F1840A0600000000840A14000000000259A808025DB608023B0000032C000000",
        %{meta: %{frame_port: 2}},
        %{
          :frame_port => 2,
          "0_0_0_datetime" => ~N[2020-06-26 11:08:00],
          "0_0_0_energy_Wh" => 201000,
          "0_0_0_fabrication_block" => 25337121,
          "0_0_0_flow_m³/h" => 0.0,
          "0_0_0_power_W" => 0,
          "0_0_0_return_temperature_°C" => 22.3,
          "0_0_0_supply_temperature_°C" => 22.16,
          "0_0_0_unkown_manufacturer_specific" => "00",
          "0_0_0_volume_m³" => 6.64,
          "20_0_0_date" => ~D[2127-01-01],
          "20_0_0_energy_Wh" => 0,
          "20_0_0_volume_m³" => 0.0
        }
      },

    ]
  end
end
