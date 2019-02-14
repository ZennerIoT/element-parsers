defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for TrackNet Tabs object locator
  # According to documentation provided by TrackNet
  # Payload Description Version v1.3


  # Test hex payload "Motion" : "01FB060000CC0E00"
  # Status 1 = occupied; 0 = free

   def parse(event, _meta) do
    <<  _stat_rfu::7, stat::1, bat_c::4, bat_v::4, _temp_rfu::1, temp::7, _time::little-16, count::little-24 >> = event
    %{
        sensor_status: stat,
        batterie_voltage: (25+bat_v)/10,
        batterie_capacity: 100*(bat_c/15),
        temperatur: temp+15,
        count: count,
    }
  end

  def fields do
    [
      %{
        "field" => "battery_capacity",
        "display" => "Battery Capacity",
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
        "field" => "sensor_status",
        "display" => "Movement"
       }
    ]
  end
end
