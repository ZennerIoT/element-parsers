defmodule Parser do
  use Platform.Parsing.Behaviour
  use Bitwise
  
# Test hex payload: "08FE3D59D1D3027E5281E0"

  def parse(<<status, battery, temp, lat::signed-little-32, lon::signed-little-32, _::binary>>, _meta) do
  <<rem_cap::4, voltage::4>> = <<battery>>
  <<rfu::1, temperature::7>> = <<temp>>
  <<rfu::4, fix::1, rfu::2, btn::1>> = <<status>>
  <<rfu::4, latitude::28>> = <<lat::32>>
  <<acc::3, longitude::29>> = <<lon::32>>

  button = case btn do
    0 -> "not pushed"
    1 -> "pushed"
  end

  gnss_fix = case fix do
    0 -> "has fix"
    1 -> "no fix"
  end
  
  acc = case acc do
    7 -> 256
    _ -> 2<<<(acc+1)
  end


  {
     %{
      battery_state: 100*(rem_cap/15),
      battery_voltage: (25+voltage)/10,
      # temperature: temperature-32,
      gnss: gnss_fix,
      button: button,
      latitude: latitude/1000000,
      longitude: longitude/1000000,
      acc: acc
    },
    [
      location: {longitude/1000000, latitude/1000000}
    ]
  }
  end

end
