defmodule Parser do
  use Platform.Parsing.Behaviour
  #Parser for Siconia sensor according to standard preconfiguration by iot-shop.de or ZENNER IoT Solutions
  #Long press: start joining procedure (blinks green 3 times) or puts device to sleep mode (blinks red 3 times)
  #Short press: if joined, a packet will be sent, if not nothing happens.

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
        "display" => "Battery charge",
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
