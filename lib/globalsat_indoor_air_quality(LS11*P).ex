defmodule Parser do
  use Platform.Parsing.Behaviour
  
  #Parser for globalsat indoor climate monitor LS11*P
  #works for CO, CO2 and PM2.5 Models
  #Author F. Wolf fw@alpha-omega-technology.de

  def parse(<<type::big-8, temp::signed-big-16, humid::big-16, sens::big-16>>, _meta) do
  
  %{
    temperature: temp/100,
    humidity: humid/100,
    sens: sens,
    type: type,
  }
  end 
  
  cond do
    type == 1  -> 
      sensor = "CO2"
    type == 2  -> 
      sensor = "CO"
    type == 3  -> 
      sensor = "PM 2.5"
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
        "display" => sensor,
        "unit" => "ppm"
      },
    ]
  end
end
