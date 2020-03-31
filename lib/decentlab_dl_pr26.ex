defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for DECENTLAB DL-PR26 Pressure Sensor
  # According to documentation:
  #   https://www.catsensors.com/media/Decentlab/DL-PR26-datasheet.pdf

  # Changelog
  #   2019-01-07/jb: Initial implementation for 359=KELLER_I2C_PRESSURE_SENSOR
  #   2020-03-31/jb: Allowing all device_ids now

  # Configuration
  # Can be found on the pressure sensor.
  def pressure_min(), do: 0.0 # bar
  def pressure_max(), do: 1.0 # bar

  # Pressure Sensor
  def parse(<<2::8, device_id::16, rest::binary>>, _meta), do: do_parse(device_id, rest)
  def parse(_payload, _meta), do: []


  def do_parse(device_id, <<_::14, sensor1::1, sensor0::1, payload::binary>>) do
    %{
      device_id: device_id,
      device_type: "pressure_sensor",
      sensor0_flag: sensor0,
      sensor1_flag: sensor1,
      payload: payload, # Will be removed later.
    }
    |> case do
      # Add data from sensor 0 if available
      %{sensor0_flag: 1, payload: <<pressure::16, temp::16, rest::binary>>} = reading ->
        Map.merge(reading, %{
          pressure: ((pressure - 16384) / 32768 *  (pressure_max() - pressure_min()) + pressure_min()),
          temperature: ((temp - 384) / 64000 * 200 - 50),
          payload: rest,
        })
      reading -> reading
    end
    |> case do
      # Add data from sensor 1 if available
      %{sensor1_flag: 1, payload: <<batt::16, rest::binary>>} = reading ->
        Map.merge(reading, %{
          battery_voltage: batt / 1000,
          payload: rest,
        })
      reading -> reading
    end
    |> Map.drop([:payload])
  end


  def fields do
    [
      %{
        "field" => "battery_voltage",
        "display" => "Battery",
        "unit" => "V"
      },
      %{
        "field" => "device_id",
        "display" => "Device-ID",
      },
      %{
        "field" => "device_type",
        "display" => "Device-Type",
      },
      %{
        "field" => "pressure",
        "display" => "Pressure",
        "unit" => "bar"
      },
      %{
        "field" => "temperature",
        "display" => "Temperature",
        "unit" => "°C"
      },
    ]
  end

  def tests() do
    [
      {
        # Value from docs
        :parse_hex, "02016700033e8060170c7f", %{}, %{
          battery_voltage: 3.199,
          device_id: 359,
          device_type: "pressure_sensor",
          pressure: -0.01171875,
          sensor0_flag: 1,
          sensor1_flag: 1,
          temperature: 25.671875
        }
      },
      {
        # Value from docs
        :parse_hex, "02016700020c7f", %{}, %{
          battery_voltage: 3.199,
          device_id: 359,
          device_type: "pressure_sensor",
          sensor0_flag: 0,
          sensor1_flag: 1
        }
      },
      {
        # Value from real device with undocumented device_id
        :parse_hex, "02016700033FD85D2E0C1C", %{}, %{
          battery_voltage: 3.1,
          device_id: 359,
          device_type: "pressure_sensor",
          pressure: -0.001220703125,
          sensor0_flag: 1,
          sensor1_flag: 1,
          temperature: 23.34375
        }
      },
    ]
  end

end
