defmodule Parser do
  use Platform.Parsing.Behaviour
  
  #Parser for globalsat indoor climate monitor
  #Author F. Wolf fw@alpha-omega-technology.de

  def parse(<<type::big-8, temp::signed-big-16, humid::big-16, sens::big-16>>, _meta) do
  
  sensor = case type do
    1 -> "CO2"
    2 -> "CO"
    3 -> "PM 2.5"
    _ -> "unknown"
  end
  
  %{
    temperature: temp/100,
    humidity: humid/100,
    sens: sens,
    type: sensor,
  }
  end 
  

   
  def fields do
    [
      %{
        "field" => "humidity",
        "display" => "rel. Luftfeuchte",
        "unit" => "%"
      },
      %{
        "field" => "temperature",
        "display" => "Temperature",
        "unit" => "°C"
      },
      %{
        "field" => "sens",
        "display" => "Concentration",
        "unit" => "ppm"
      },
    ]
  end
end
