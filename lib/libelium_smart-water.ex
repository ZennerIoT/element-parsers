defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for Libelium Smart Environment Device
  # According to documentation provided by Libelium
  # Link: http://www.libelium.com/development/plug-sense
  # Documentation: http://www.libelium.com/downloads/documentation/waspmote_plug_and_sense_technical_guide.pdf
  # sensors used (Libelium reference numbers): 9328, 9327, 9326, 9329, 9255-P

  def parse(<<temp::big-16, opr::big-16, ph::big-16, disox::big-16, conduct::big-16, power::big-16>>, _meta) do

    # return value map
    %{
      temp: temp/10,    # Temperature in °C
      opr: opr/100,     # Oxidation-reduction potential in V
      ph: ph/100,       # pH
      disox: disox/10,  # Dissolved Oxygen in %
      conduct: conduct, # Conductivity in µS/cm
      power: power      # Battery level in %
    }
  end

  def fields do
    [
      %{
        "field" => "temp",
        "display" => "Temperature",
        "unit" => "°C"
      },
      %{
        "field" => "opr",
        "display" => "Reduction potential",
        "unit" => "V"
      },
      %{
        "field" => "ph",
        "display" => "pH value"
      },
      %{
        "field" => "disox",
        "display" => "Dissolved oxygen",
        "unit" => "%"
      },
      %{
        "field" => "conduct",
        "display" => "Conductivity",
        "unit" => "µS/cm"
      },
      %{
        "field" => "power",
        "display" => "Battery level",
        "unit" => "%"
      }
    ]
  end

  # Test case and data for automatic testing
  def tests() do
    [
      {
        :parse_hex, "0055BDB6045201EE00150060", %{}, %{
          temp: 8.5,
          power: 96,
          ph: 11.06,
          opr: 485.66,
          disox: 49.4,
          conduct: 21
        }
      }
    ]
  end
end
