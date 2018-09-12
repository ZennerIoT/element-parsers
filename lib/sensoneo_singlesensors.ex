defmodule Parser do
  use Platform.Parsing.Behaviour

  def parse(<<_uprefix::16, v::binary-4, _tprefix::8, t::binary-3, _dprefix::8, d::binary-3, _pprefix::8, p::binary-1, _rest::binary>>, _meta) do
    voltage = String.to_float(v)
    temperature = String.to_integer(t)
    distance = String.to_integer(d)
    position = String.to_integer(p)

    position = case position do
      0 -> "normal"
      1 -> "tilt"
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
        :parse_hex, "2855332e3539542b323144323534503029", %{}, %{
          voltage: 3.59,
          temperature: 21,
          distance: 254,
          position: "normal"
        }
      }
    ]
  end
end
