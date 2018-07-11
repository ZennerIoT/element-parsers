defmodule Parser do
  use Platform.Parsing.Behaviour
  use Bitwise

  #ELEMENT IoT Parser for TrackNet Tabs object locator
  # According to documentation provided by TrackNet
  # Payload Description Version v1.3

  #
  # Changelog
  #   2018-05-23 [jb]: Added tests(), formatted code.
  #

  # Test hex payload: "08FE3D59D1D3027E5281E0"

  def parse(<<status, battery, temp, lat::signed-little-32, lon::signed-little-32, _::binary>>, _meta) do
    <<rem_cap::4, voltage::4>> = <<battery>>
    <<_rfu::1, _temperature::7>> = <<temp>>
    <<_rfu1::4, fix::1, _rfu2::2, btn::1>> = <<status>>
    <<_rfu::4, latitude::28>> = <<lat::32>>
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

  def tests() do
    [
      {
        :parse_hex, "08FE3D59D1D3027E5281E0", %{}, {
          %{
            acc: 256,
            battery_state: 100.0,
            battery_voltage: 3.9,
            button: "not pushed",
            gnss: "no fix",
            latitude: 47.436121,
            longitude: 8.475262
          },
          [location: {8.475262, 47.436121}]
        }
      },
      {
        :parse_hex, "086E3E36D2D302D1508180", %{}, {
          %{
            acc: 64,
            battery_state: 40.0,
            battery_voltage: 3.9,
            button: "not pushed",
            gnss: "no fix",
            latitude: 47.436342,
            longitude: 8.474833
          },
          [location: {8.474833, 47.436342}]
        }
      },
      {
        :parse_hex, "005D4076CED302434A8180", %{}, {
          %{
            acc: 64,
            battery_state: 33.33333333333333,
            battery_voltage: 3.8,
            button: "not pushed",
            gnss: "has fix",
            latitude: 47.435382,
            longitude: 8.473155
          },
          [location: {8.473155, 47.435382}]
        }
      },
    ]
  end

end
