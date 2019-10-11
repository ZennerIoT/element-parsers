defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for SensoNeo Single Sensor
  # According to documentation provided by Sensoneo
  # Link: https://sensoneo.com/product/smart-sensors/

  #
  # Changelog
  #   2018-09-13 [as]: Initial version.
  #   2018-09-17 [as]: fixed position value, was switched
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #   2019-10-10 [jb]: New implementation for <= v2 payloads.
  #   2019-10-11 [jb]: Supporting v3 payloads.
  #

  def parse(<<"(", _::binary>> = payload, %{meta: %{frame_port: 1}}) do
    ~r/\(U([0-9.]+)T([0-9+-]+)D([0-9]+)P([0-9]+)\)/
    |> Regex.run(payload)
    |> case do
      [_, voltage, temp, distance, position] ->
        %{
          voltage: String.to_float(voltage),
          temperature: String.to_integer(temp),
          distance: String.to_integer(distance),
          position: position(position)
        }
      _ ->
        Logger.info("Sensoneo Parser: Unknown payload #{inspect payload}")
        []
    end
  end
  def parse(<<0xFF, 0xFF, header::binary-2, sensor_id::32-little, events, sonar0, sonar1, sonar2, sonar3, voltage, temp, tilt, tx_events>>, %{meta: %{frame_port: 2}}) do
    # Dont know what `qs` is, not documented ...
    <<_qs::4, type::4, firmware::8>> = header
    type = case type do
      0 -> :master
      1 -> :slave
      2 -> :standalone
      _ -> :unknown
    end

    [
      event_measurement_ended: binary_and(events, 0x01),
      event_temperature_threshold: binary_and(events, 0x02),
      event_tilt_threshold: binary_and(events, 0x04),
      event_slave_device_tx: binary_and(events, 0x08),
      event_battery_low: binary_and(events, 0x10),
      event_gpsfix: binary_and(events, 0x20),
      event_startup: binary_and(events, 0x20),
    ]
    |> Enum.filter(fn({_, v}) -> v != 0 end)
    |> Enum.into(%{
      type: type,
      firmware: firmware,
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
    })
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  #defp binary_and(events, pattern) when Bitwise.band(events, pattern), do: 1
  #defp binary_and(_events, _pattern), do: 0
  defp binary_and(events, pattern) do
    require Bitwise
    case Bitwise.band(events, pattern) do
      0 -> 0
      _ -> 1
    end
  end

  defp position("0"), do: "tilt"
  defp position("1"), do: "normal"
  defp position(_), do: "unknown"

  def fields do
    [
      %{
        field: "voltage",
        display: "Voltage",
        unit: "V"
      },
      %{
        field: "temperature",
        display: "Temperature",
        unit: "°C"
      },
      %{
        field: "distance",
        display: "Distance",
        unit: "cm"
      },
      %{
        field: "position",
        display: "Position"
      },
      %{
        field: "tilt",
        display: "Tilt",
        unit: "°"
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
    ]
  end

  def tests() do
    [
      # Version 1 or 2
      {
        :parse_hex,
        "2855332E3736542B313444323531503129",
        %{meta: %{frame_port: 1}},
        %{
          distance: 251,
          position: "normal",
          temperature: 14,
          voltage: 3.76
        }
      },

      # Version 3
      {
        :parse_hex,
        "FFFF22B39C009070017F7F7F7F6D15325D",
        %{meta: %{frame_port: 2}},
        %{
          distance: 254.0,
          event_measurement_ended: 1,
          firmware: 179,
          sensor_id: 1888485532,
          sonar_0: 254,
          sonar_1: 254,
          sonar_2: 254,
          sonar_3: 254,
          temperature: 21,
          tilt: 50,
          tx_events: 93,
          type: :standalone,
          voltage: 3.59
        }
      },
    ]
  end
end
