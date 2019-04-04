defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for TrackNet Tabs Healthy Home Sensor
  # According to documentation provided by TrackNet
  # Payload Description Version v1.3

  # Changelog
  #   2018-04-12 [as]: Initial version.
  #   2019-04-04 [jb]: Skipping 65535 for co2 and voc. Added tests. Added parse() fallback.

  def parse(<<_status, battery::binary-1, temp::binary-1, humidity::binary-1, co2::little-16, voc::little-16>>, _meta) do
    <<rem_cap::4, voltage::4>> = battery
    <<_rfu::1, temperature::7>> = temp
    <<_rfu::1, rhum::7>> = humidity

    %{
      battery_state: 100*(rem_cap/15),
      battery_voltage: (25+voltage)/10,
      temperature: temperature-32,
      relative_humidity: rhum,
    }
    |> add_value_or_skip(:co2, co2, [65535])
    |> add_value_or_skip(:voc, voc, [65535])
  end

  def parse(payload, meta) do
    Logger.info("Unhandled meta.frame_port: #{inspect get_in(meta, [:meta, :frame_port])} with payload #{inspect payload}")
    []
  end

  def add_value_or_skip(map, key, value, skipped_values) do
    if Enum.member?(skipped_values, value) do
      map
    else
      Map.put(map, key, value)
    end
  end

  def fields do
    [
      %{
        "field" => "battery_state",
        "display" => "Battery state",
        "unit" => "%"
      },
      %{
        "field" => "battery_voltage",
        "display" => "Battery voltage",
        "unit" => "V"
      },
      %{
        "field" => "temperature",
        "display" => "Temperature",
        "unit" => "°C"
      },
      %{
        "field" => "relative_humidity",
        "display" => "Relative humidity",
        "unit" => "%"
      },
      %{
        "field" => "co2",
        "display" => "CO2",
        "unit" => "ppm"
      },
      %{
        "field" => "voc",
        "display" => "Volatile organic compounds",
        "unit" => "ppm"
      }
    ]
  end

  def tests() do
    [
      {
        :parse_hex, "00FB352555021E00", %{meta: %{frame_port: 103}},
        %{
          battery_state: 100.0,
          battery_voltage: 3.6,
          co2: 597,
          relative_humidity: 37,
          temperature: 21,
          voc: 30
        }
      },
      {
        :parse_hex, "08FB3525FFFFFFFF", %{meta: %{frame_port: 103}},
        %{
          battery_state: 100.0,
          battery_voltage: 3.6,
          relative_humidity: 37,
          temperature: 21,
          # voc and co2 are filtered because they are 65535
        }
      },
    ]
  end

end
