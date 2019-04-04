defmodule Parser do
  use Platform.Parsing.Behaviour

  #ELEMENT IoT Parser for TrackNet Tabs Door & Windows Sensor
  # According to documentation provided by TrackNet
  # Payload Description Version v1.3

  # Changelog
  #   2019-04-04 [gw]: Adding tests(), formatted code, corrected name of device in comment.

  def parse(<<status, battery, temp, time::little-16, count::little-24>>, _meta) do
    <<_rfu::7, state::1>> = <<status>>
    <<rem_cap::4, voltage::4>> = <<battery>>
    <<_rfu::1, temperature::7>> = <<temp>>

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
      },
      %{
        "field" => "total_count",
        "display" => "Total count"
      },
      %{
        "field" => "time_elapsed_since_trigger",
        "display" => "Time elapsed since trigger"
      }
    ]
  end

  def tests() do
    [
      {
        :parse_hex, "00FB050000781D00", %{meta: %{frame_port: 100}},
        %{
          battery_state: 100.0,
          battery_voltage: 3.6,
          contact: "closed",
          temperature: -27,
          total_count: 7544,
          time_elapsed_since_trigger: 0
        }
      },
      {
        :parse_hex, "01FB050000771D00", %{meta: %{frame_port: 100}},
        %{
          battery_state: 100.0,
          battery_voltage: 3.6,
          contact: "open",
          temperature: -27,
          total_count: 7543,
          time_elapsed_since_trigger: 0
        }
      }
    ]
  end
end
