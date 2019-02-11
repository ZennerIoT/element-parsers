defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for SensoNeo Single Sensor
  # According to documentation provided by Sensoneo
  # Link: https://sensoneo.com/product/smart-sensors/

  #
  # Changelog
  #   2018-09-13 [as]: Initial version.
  #   2018-09-17 [as]: fixed position value, was switched
  #



  def parse(<<_uprefix::16, v::binary-4, _tprefix::8, t::binary-3, _dprefix::8, d::binary-3, _pprefix::8, p::binary-1, _rest::binary>>, _meta) do
    voltage = String.to_float(v)
    temperature = String.to_integer(t)
    distance = String.to_integer(d)
    position = String.to_integer(p)

    position = case position do
      1 -> "normal"
      0 -> "tilt"
    end

    %{
      voltage: voltage,
      temperature: temperature,
      distance: distance,
      position: position
    }
  end

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
    ]
  end

  def tests() do
    [
      {
        :parse_hex, "2855332e3539542b323144323534503029", %{}, %{distance: 254, position: "tilt", temperature: 21, voltage: 3.59}
      }
    ]
  end
end
