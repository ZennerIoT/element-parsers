defmodule Parser do
  use Platform.Parsing.Behaviour
  use Bitwise

  require Logger

  #ELEMENT IoT Parser for TrackNet Tabs, including:
  #   * Door & Window Sensor
  #   * Healthy Home Sensor
  #   * Motion Sensor
  #   * Object Locator
  #   * Push Button
  #
  # According to documentation provided by TrackNet
  # Payload Description Version v1.3 (and 1.4 for the Push Button)

  # Changelog
  #   2019-04-04 [gw]: Initial version, combining 5 TrackNet Tabs devices.

  # Door & Window Sensor
  def parse(<<status::binary-1, battery::binary-1, temp::binary-1, time::little-16, count::little-24>>, %{meta: %{frame_port: 100}}) do
    {battery_state, battery_voltage} = read_battery(battery)

    %{
      battery_state: battery_state,
      battery_voltage: battery_voltage,
      temperature: read_temperature(temp),
      contact: get_contact_state(status),
      time_elapsed_since_trigger: time,
      total_count: count
    }
  end
  # Healthy Home Sensor
  def parse(<<_status, battery::binary-1, temp::binary-1, humidity::binary-1, co2::little-16, voc::little-16>>, %{meta: %{frame_port: 103}}) do
    {battery_state, battery_voltage} = read_battery(battery)
    <<_rfu::1, rhum::7>> = humidity

    %{
      battery_state: battery_state,
      battery_voltage: battery_voltage,
      temperature: read_temperature(temp),
      relative_humidity: rhum
    }
    |> add_value_or_skip(:co2, co2, [65535])
    |> add_value_or_skip(:voc, voc, [65535])
  end
  # Motion Sensor
  def parse(<<status::binary-1, battery::binary-1, temp::binary-1, _time::little-16, count::little-24>>, %{meta: %{frame_port: 102}}) do
    <<_rfu::7, state::1>> = status
    {battery_state, battery_voltage} = read_battery(battery)

    %{
      sensor_status: state,
      battery_voltage: battery_voltage,
      battery_state: battery_state,
      temperature: read_temperature(temp),
      count: count,
    }
  end
  # Object Locator
  def parse(<<status::binary-1, battery::binary-1, _temp::binary-1, lat::signed-little-32, lon::signed-little-32, _::binary>>, %{meta: %{frame_port: 136}}) do
    {battery_state, battery_voltage} = read_battery(battery)
    {acc, latitude, longitude} = read_location(<<lat::32>>, <<lon::32>>)
    {button, gnss_fix} = read_location_status(status)

    {
      %{
        battery_state: battery_state,
        battery_voltage: battery_voltage,
        # temperature: read_temperature(temp),
        gnss: gnss_fix,
        button: button,
        latitude: latitude,
        longitude: longitude,
        acc: acc
      },
      [
        location: {longitude, latitude}
      ]
    }
  end
  # Push Button
  def parse(<<status::binary-1, battery::binary-1, temp::binary-1, time::little-16, count::little-24, rest::binary>>, %{meta: %{frame_port: 147}}) do
    {battery_state, battery_voltage} = read_battery(battery)
    {button_1, button_0} = read_button_state(status)

    result = %{
      button_1_state: button_1,
      button_0_state: button_0,
      battery_state: battery_state,
      battery_voltage: battery_voltage,
      temperature: read_temperature(temp),
      time_elapsed_since_trigger: time,
      total_count: count
    }

    # additional functionality for v1.4
    case rest do
      <<count_1::little-24>> ->
        Map.merge(result, %{
          total_count: (count + count_1),
          button_0_count: count,
          button_1_count: count_1
        })
      _ -> result
    end
  end
  # not matched
  def parse(payload, meta) do
    Logger.info("Unhandled meta.frame_port: #{inspect get_in(meta, [:meta, :frame_port])} with payload #{inspect payload}")
    []
  end

  defp get_contact_state(<<_rfu::7, 0::1>>), do: "closed"
  defp get_contact_state(<<_rfu::7, 1::1>>), do: "open"

  defp read_battery(<<rem_cap::4, voltage::4>>) do
    battery_state = 100 * (rem_cap / 15)
    battery_voltage = (25 + voltage) / 10
    {battery_state, battery_voltage}
  end

  defp read_temperature(<<_rfu::1, temperature::7>>), do: temperature - 32

  defp read_location(<<_rfu::4, latitude::28>>, <<acc::3, longitude::29>>) do
    acc = case acc do
      7 -> 256
      _ -> 2<<<(acc+1)
    end
    {
      acc,
      latitude / 1000000,
      longitude / 1000000
    }
  end

  defp read_location_status(<<_rfu1::4, fix::1, _rfu2::2, btn::1>>) do
    button = case btn do
      0 -> "not pushed"
      1 -> "pushed"
    end

    gnss_fix = case fix do
      0 -> "has fix"
      1 -> "no fix"
    end
    {button, gnss_fix}
  end

  defp read_button_state(<<_rfu::6, state_1::1, state_0::1>>) do
    button_1 = case state_1 do
      0 -> "not pushed"
      1 -> "pushed"
    end

    button_0 = case state_0 do
      0 -> "not pushed"
      1 -> "pushed"
    end
    {button_1, button_0}
  end

  defp add_value_or_skip(map, key, value, skipped_values) do
    if Enum.member?(skipped_values, value) do
      map
    else
      Map.put(map, key, value)
    end
  end

  def fields() do
    [
      # common among all 5
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
      # doorwindow, motion, pushbutton
      %{
        "field" => "total_count",
        "display" => "Counter total"
      },
      # doornwindow only
      %{
        "field" => "contact",
        "display" => "Contact"
      },
      %{
        "field" => "time_elapsed_since_trigger",
        "display" => "Time elapsed since trigger"
      },
      # healthy-home only
      %{
        "field" => "relative_humidity",
        "display" => "Relative humidity",
        "unit" => "%"
      },
      %{
        "field" => "co2",
        "display" => "CO2",
        "unit" => "ppm"
      },
      %{
        "field" => "voc",
        "display" => "Volatile organic compounds",
        "unit" => "ppm"
      },
      # motion only
      %{
        "field" => "sensor_status",
        "display" => "Movement"
      },
      # object locator only
      %{
        "field" => "gnss",
        "display" => "GNSS"
      },
      %{
        "field" => "button",
        "display" => "Button",
        "unit" => ""
      },
      %{
        "field" => "longitude",
        "display" => "Longitude"
      },
      %{
        "field" => "latitude",
        "display" => "Latitude"
      },
      %{
        "field" => "acc",
        "display" => "Accuracy"
      },
      # pushbutton only
      %{
        "field" => "button_0_count",
        "display" => "Counter Button 0"
      },
      %{
        "field" => "button_1_count",
        "display" => "Counter Button 1"
      }
    ]
  end

  def tests() do
    tests_doornwindow() ++ tests_healthy_home() ++ tests_motion() ++ tests_object_locator() ++ tests_pushbutton()
  end

  defp tests_doornwindow() do
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

  defp tests_healthy_home() do
    [
      {
        :parse_hex, "00FB352555021E00", %{meta: %{frame_port: 103}},
        %{
          battery_state: 100.0,
          battery_voltage: 3.6,
          co2: 597,
          relative_humidity: 37,
          temperature: 21,
          voc: 30
        }
      },
      {
        :parse_hex, "08FB3525FFFFFFFF", %{meta: %{frame_port: 103}},
        %{
          battery_state: 100.0,
          battery_voltage: 3.6,
          relative_humidity: 37,
          temperature: 21,
          # voc and co2 are filtered because they are 65535
        }
      }
    ]
  end

  defp tests_motion() do
    [
      {
        :parse_hex, "01FB060000CC0E00", %{meta: %{frame_port: 102}},
        %{
          battery_state: 100.0,
          battery_voltage: 3.6,
          count: 3788,
          sensor_status: 1,
          temperature: -26
        }
      },
      {
        :parse_hex, "00FB340500AB0D00", %{meta: %{frame_port: 102}},
        %{
          battery_state: 100.0,
          battery_voltage: 3.6,
          count: 3499,
          sensor_status: 0,
          temperature: 20
        }
      }
    ]
  end

  defp tests_object_locator() do
    [
      {
        :parse_hex, "08FE3D59D1D3027E5281E0", %{meta: %{frame_port: 136}}, {
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
        :parse_hex, "086E3E36D2D302D1508180", %{meta: %{frame_port: 136}}, {
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
        :parse_hex, "005D4076CED302434A8180", %{meta: %{frame_port: 136}}, {
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
      }
    ]
  end

  defp tests_pushbutton() do
    [
      {
        :parse_hex, "01FE39EA000C0000000000", %{meta: %{frame_port: 147}},
        %{
          total_count: 12,
          time_elapsed_since_trigger: 234,
          button_1_state: "not pushed",
          button_1_count: 0,
          button_0_state: "pushed",
          button_0_count: 12,
          battery_voltage: 3.9,
          battery_state: 100.0,
          temperature: 25
        }
      },
      {
        :parse_hex, "01FE39EA000C0000", %{meta: %{frame_port: 147}},
        %{
          total_count: 12,
          time_elapsed_since_trigger: 234,
          button_1_state: "not pushed",
          button_0_state: "pushed",
          battery_voltage: 3.9,
          battery_state: 100.0,
          temperature: 25
        }
      }
    ]
  end

end