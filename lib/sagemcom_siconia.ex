defmodule Parser do
  use Platform.Parsing.Behaviour

  #Parser for Siconia sensor according to standard AOT program
  #Author F. Wolf fw@alpha-omega-technology.de

  def parse(<<temp::signed-little-32, humid::little-32, bat::little-32>>, _meta) do

  %{
    temperature: temp/100,
    humidity: humid/100,
    battery: bat,
  }
  end

  def fields do
    [
      %{
        "field" => "battery",
        "display" => "Batterieladezustand",
        "unit" => "%"
      },
      %{
        "field" => "temperature",
        "display" => "Temperature",
        "unit" => "°C"
      },
      %{
        "field" => "humidity",
        "display" => "Relative humidity",
        "unit" => "%"
      }
    ]
  end
end
