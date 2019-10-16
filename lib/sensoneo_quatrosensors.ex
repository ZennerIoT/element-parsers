defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for SensoNeo Quatro Sensor
  # According to documentation provided by Sensoneo
  # Link: https://sensoneo.com/product/smart-sensors/

  #
  # Changelog
  #   2019-10-16 [jb]: Initial implementation according to "sensoneo_quatro_QS_Payload_v2.pdf".
  #

  # Standalone
  def parse(<<
    _header::binary-4,
    sensor_id::32-little,
    events,
    sonar0, sonar1, sonar2, sonar3,
    voltage, temp::signed, tilt,
    timestamp::32-little,
    lat::float-32-little, lat_dir,
    lon::float-32-little, lon_dir,
    events_count, _crc, tx_events>>, %{meta: %{frame_port: 2}}) do

    [
      event_measurement_ended: binary_and(events, 0x01),
      event_temperature_threshold: binary_and(events, 0x02),
      event_tilt_threshold: binary_and(events, 0x04),
      event_slave_device_tx: binary_and(events, 0x08),
      event_battery_low: binary_and(events, 0x10),
      event_gpsfix: binary_and(events, 0x20),
      event_startup: binary_and(events, 0x40),
    ]
    |> Enum.filter(fn({_, v}) -> v != 0 end)
    |> Enum.into(%{
      sensor_id: sensor_id,
      distance: (sonar0*2 + sonar1*2 + sonar2*2 + sonar3*2) / 4,
      sonar_0: sonar0*2, # cm
      sonar_1: sonar1*2, # cm
      sonar_2: sonar2*2, # cm
      sonar_3: sonar3*2, # cm
      voltage: (2500+voltage*10)/1000, # V
      temperature: temp, # C°
      tilt: tilt, # °
      tx_events: tx_events, # Number events
      events_count: events_count,
      timestamp: timestamp,
      lat: lat,
      lat_dir: lat_dir,
      lon: lon,
      lon_dir: lon_dir,
    })
    |> append_location()
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  defp append_location(%{lat: lat, lon: lon} = reading) do
    {reading, location: [lon, lat]}
  end

  defp binary_and(events, pattern) do
    require Bitwise
    case Bitwise.band(events, pattern) do
      0 -> 0
      _ -> 1
    end
  end

  def fields do
    [
      %{
        field: "distance",
        display: "Distance",
        unit: "cm"
      },
      %{
        field: "sonar_0",
        display: "Sonar0",
        unit: "cm"
      },
      %{
        field: "sonar_1",
        display: "Sonar1",
        unit: "cm"
      },
      %{
        field: "sonar_2",
        display: "Sonar2",
        unit: "cm"
      },
      %{
        field: "sonar_3",
        display: "Sonar3",
        unit: "cm"
      },
      %{
        field: "temperature",
        display: "Temperature",
        unit: "°C"
      },
      %{
        field: "tilt",
        display: "Tilt",
        unit: "°"
      },
      %{
        field: "voltage",
        display: "Voltage",
        unit: "V"
      },
    ]
  end

  def tests() do
    [
      {
        :parse_hex,
        "FFFF02A7540120020133333335720CCCB1A6A55D26BF3D424E8195074145603F01",
        %{meta: %{frame_port: 2}},
        {
          %{
            distance: 103.0,
            event_measurement_ended: 1,
            events_count: 96,
            lat: 47.436668395996094,
            lat_dir: 78,
            lon: 8.473999977111816,
            lon_dir: 69,
            sensor_id: 35651924,
            sonar_0: 102,
            sonar_1: 102,
            sonar_2: 102,
            sonar_3: 106,
            temperature: 12,
            tilt: 204,
            timestamp: 1571137201,
            tx_events: 1,
            voltage: 3.64
          },
          [
            location: [8.473999977111816, 47.436668395996094]
          ]
        }
      },
    ]
  end
end
