defmodule Parser do
  use Platform.Parsing.Behaviour

  #ELEMENT IoT Parser for TrackNet Tabs object locator
  # According to documentation provided by TrackNet
  # Payload Description Version v1.3


  def parse(<<_status, battery, temp, humidity, co2::little-16, voc::little-16>>, _meta) do
  <<rem_cap::4, voltage::4>> = <<battery>>
  <<_rfu::1, temperature::7>> = <<temp>>
  <<_rfu::1, rhum::7>> = <<humidity>>


    %{
      battery_state: 100*(rem_cap/15),
      battery_voltage: (25+voltage)/10,
      temperature: temperature-32,
      relative_humidity: rhum,
      co2: co2,
      voc: voc
    }
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
end
