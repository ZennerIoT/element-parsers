defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # Parser for Lobaro Pressure Sensor 26D that will provide pressure and temperature data.
  #
  # Changelog:
  #   2019-05-14 [as]: Initial implementation according to "LoRaWAN-Pressure-Manual.pdf" as provided by Lobaro
  #   2019-11-21 [as]: updating parser according to firmware version 0.1.0

  def parse(<<pressure::little-float-32, temp::little-16>>, %{meta: %{frame_port: 1}}) do
    %{
      type: :measurement,
      pressure: pressure,
      temperature: temp/100
    }
  end
  def parse(<<pressure::little-float-32, temp::little-signed-16, battery::little-signed-16>>, _meta) do
    %{
      type: :measurement,
      pressure: pressure,
      temperature: temp/100,
      battery: battery
    }
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  def fields() do
    [
      %{
        field: "pressure",
        display: "Pressure",
        unit: "bar"
      },
      %{
        field: "temperature",
        display: "Temperature",
        unit: "°C"
      },
      %{
        field: "battery",
        display: "Battery voltage",
        unit: "mV"
      }
    ]
  end

  def tests() do
    [
      {:parse_hex, "60911f406F08", %{meta: %{frame_port: 1}}, %{type: :measurement, pressure: 2.4932479858398438, temperature: 21.59}}
    ]
  end
end
