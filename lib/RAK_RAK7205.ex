defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # Parser for RAK7205 GPS-Tracker
  #
  # Changelog:
  #   2021-05-04 [Felix Wolf (AO-T)]: Initial implementation according to https://docs.rakwireless.com/Product-Categories/WisTrio/RAK7205-5205/Quickstart/#_1-gps-data
  #   2021-05-05 [Felix Wolf (AO-T)]: Cleanup, added test

  def parse(payload, %{meta: %{frame_port: 8}}) do
    payload
    |> parse_frames([])
    |> Enum.into(%{})
    |> case do
      %{latitude: lat, longitude: lon} = row ->
        {row, [location: {lon, lat}]}
      row -> 
        row
    end
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  def parse_frames(<<0x01, 0x88, lat::24-signed,long::24-signed,alt::24-signed, rest::binary>>, frames) do
    latitude = (lat*0.0001)
    longitude = (long*0.0001)
    altitude = (alt*0.0001)
    parse_frames(rest, [
      {:latitude, latitude}, 
      {:longitude, longitude}, 
      {:altitude, altitude}
    |frames])
  end
  def parse_frames(<<0x08, 0x02, bat::16-signed, rest::binary>>, frames) do
    battery = bat*0.01
    parse_frames(rest, [{:battery, battery}|frames])
  end
  def parse_frames(<<0x07, 0x68, relative_humidity, rest::binary>>, frames) do
    relative_humidity_percent = relative_humidity / 2 # Conversion from 0.5% to %
    parse_frames(rest, [{:relative_humidity, relative_humidity_percent}|frames])
  end
  def parse_frames(<<0x06, 0x73, pressure::16, rest::binary>>, frames) do
    pressure = pressure*0.1
    parse_frames(rest, [{:pressure, pressure}|frames])
  end
  def parse_frames(<<0x02, 0x67, temp::16-signed, rest::binary>>, frames) do
    temperature = temp * 0.1
    parse_frames(rest, [{:temperature, temperature}|frames])
  end
  def parse_frames(<<0x04, 0x02, gas::16-signed, rest::binary>>, frames) do
    gas_resistance = gas * 0.01
    parse_frames(rest, [{:gas_resistance, gas_resistance}|frames])
  end
  def parse_frames(<<0x03, 0x71, accelero::binary-6, rest::binary>>, frames) do
    <<x::16-signed, y::16-signed, z::16-signed>> = accelero
    parse_frames(rest, [
      {:acceleration_x, x * 0.001}, # g
      {:acceleration_y, y * 0.001}, # g
      {:acceleration_z, z * 0.001} # g
    |frames])
  end
  def parse_frames(<<>>, frames), do: Enum.reverse(frames)
  def parse_frames(payload, frames) do
    Logger.warn("RAK7205.Parser: Unknown frame found: #{inspect payload}")
    frames
  end

  # Define fields with human readable name and a SI unit if available.
  def fields() do
    [
      %{
        field: "battery",
        display: "Battery",
        unit: "V",
      },
      %{
        field: "temperature",
        display: "Temperature",
        unit: "°C",
      },
      %{
        field: "relative_humidity",
        display: "Relative Humidity",
        unit: "%",
      },
      %{
        field: "acceleration_x",
        display: "Acceleration X",
        unit: "g",
      },
      %{
        field: "acceleration_y",
        display: "Acceleration Y",
        unit: "g",
      },
      %{
        field: "acceleration_z",
        display: "Acceleration Z",
        unit: "g",
      },
      %{
        field: "gas_resistance",
        display: "Gas Sensor Resistance",
        unit: "kOhm",
      },
      %{
        field: "pressure",
        display: "Air Pressure",
        unit: "hPa",
      }
    ]
  end
  def tests() do
    [
      # Real payload
      {:parse_hex, "0188082E280182F5000CA80802016E076862067326B3026700440402020603710007FC080037", %{meta: %{frame_port: 8}}, data: %{
       acceleration_x: 0.007,
       acceleration_y: -1.016,
       acceleration_z: 0.055,
       altitude: 0.324,
       battery: 3.66,
       gas_resistance: 5.18,
       latitude: 53.610400000000006,
       longitude: 9.9061,
       pressure: 990.7,
       relative_humidity: 49.0,
       temperature: 6.800000000000001
     }},
    ]
  end
end