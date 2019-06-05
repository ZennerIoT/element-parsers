defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # ELEMENT IoT Parser for device Elvaco CMa11L
  #     documentation: https://www.elvaco.se/en/product/sensors1/cma11l-indoor-sensor-for-temperaturehumidity-lorawan--1050140
  #
  # Changelog:
  #   2019-06-05 [gw]: Initial parser according to documentation.
  #

  # 6.7.1 standard format without SDC
  def parse(<<0x00, 0x02, 0x65, temperature::signed-little-16, 0x01, 0xFB, 0x1B, humidity::8>>, _meta) do
    %{
      type: :standard,
      temperature: calculate_temperature(temperature),
      humidity: humidity,
    }
  end
  # 6.7.1 standard format withSDC
  def parse(<<0x00, 0x02, 0x65, temperature::signed-little-16, 0x01, 0xFB, 0x1B, humidity::8, _rest::binary-5>>, _meta) do
    %{
      type: :standard,
      temperature: calculate_temperature(temperature),
      humidity: humidity,
    }
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  defp calculate_temperature(temperature), do: temperature / 100

  # Define fields with human readable name and a SI unit if available.
  def fields() do
    [
      %{
        field: "type",
        display: "Typ",
      },
      %{
        field: "temperature",
        display: "Temperatur",
        unit: "°C",
      },
      %{
        field: "humidity",
        display: "Luftfeuchtigkeit",
        unit: "%",
      },
    ]
  end

  def tests() do
    [
      {
        :parse_hex, "000265750A01FB1B28", %{meta: %{frame_port: 2}}, %{
        type: :standard,
        temperature: 26.77,
        humidity: 40,
      }
      },
    ]
  end
end
