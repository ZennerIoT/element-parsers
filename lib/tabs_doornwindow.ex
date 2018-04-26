defmodule Parser do
  use Platform.Parsing.Behaviour

  #ELEMENT IoT Parser for TrackNet Tabs object locator
  # According to documentation provided by TrackNet

  def parse(<<status, battery, temp, time::little-16, count::little-24>>, _meta) do
  <<rfu::7, state::1>> = <<status>>
  <<rem_cap::4, voltage::4>> = <<battery>>
  <<rfu::1, temperature::7>> = <<temp>>

  contact = case state do
    0 -> "closed"
    1 -> "open"
  end


    %{
      battery_state: 100*(rem_cap/15),
      battery_voltage: (25+voltage)/10,
      temperature: temperature-32,
      contact: contact,
      time_elapsed_since_trigger: time,
      total_count: count
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
        "field" => "contact",
        "display" => "Contact"
       }
    ]
  end
end
