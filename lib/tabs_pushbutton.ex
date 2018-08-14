defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for TrackNet Tabs object locator
  # According to documentation provided by TrackNet
  # Payload Description Version v1.3


  def parse(<<status, battery, temp, time::little-16, count::little-24, rest::binary>>, _meta) do
  <<rfu::6, state_1::1, state_0::1>> = <<status>>
  <<rem_cap::4, voltage::4>> = <<battery>>
  <<rfu::1, temperature::7>> = <<temp>>

  button_1 = case state_1 do
    0 -> "not pushed"
    1 -> "pushed"
  end

  button_0 = case state_0 do
    0 -> "not pushed"
    1 -> "pushed"
  end


    result = %{
      button_1_state: button_1,
      button_0_state: button_0,
      battery_state: 100*(rem_cap/15),
      battery_voltage: (25+voltage)/10,
      temperature: temperature-32,
      time_elapsed_since_trigger: time,
      total_count: count
    }


    # additional functionality for
    case rest do
      <<count_1::little-24>> ->
        Map.merge(result, %{
          total_count: count+count1,
          button_0_count: count,
          button_1_count: count1
        })
        _ -> result
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
        "field" => ""
      }
    ]
  end

end
