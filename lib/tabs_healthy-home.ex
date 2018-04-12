defmodule Parser do
  use Platform.Parsing.Behaviour

  #ELEMENT IoT Parser for TrackNet Tabs object locator
  # According to documentation provided by TrackNet
  
  def parse(<<status, battery, temp, humidity, co2::little-16, voc::little-16>>, _meta) do
  <<rem_cap::4, voltage::4>> = <<battery>>
  <<rfu::1, temperature::7>> = <<temp>>
  <<rfu::1, rhum::7>> = <<humidity>>


    %{
      battery_state: rem_cap,
      battery_voltage: voltage,
      temperature: temperature-32,
      relative_humidity: rhum,
      co2: co2,
      voc: voc
    }
  end

end
