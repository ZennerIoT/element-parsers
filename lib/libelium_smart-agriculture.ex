defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for Libelium Smart Agriculture Device
  # According to documentation provided by Libelium
  # Link: http://www.libelium.com/development/plug-sense
  # Documentation: http://www.libelium.com/downloads/documentation/waspmote_plug_and_sense_technical_guide.pdf

  def parse(<<pluv1::big-16, pluv2::big-16, pluv3::big-16, temp::big-16-signed, hum::big-16, pres::big-16, anemo::big-16, lux::big-16, vane::big-16, wm::big-16, power::big-16>>, _meta) do

    # define the value map for vane
    vane_map = %{
      1 => "N",
      2 => "NNE",
      3 => "NE",
      4 => "ENE",
      5 => "E",
      6 => "ESE",
      7 => "SE",
      8 => "SSE",
      9 => "S",
      10 => "SSW",
      11 => "SW",
      12 => "WSW",
      13 => "W",
      14 => "WNW",
      15 => "NW",
      16 => "NNW",
    }

    # return value map
    %{
      pluv1: pluv1/10,      # Current hour accumulated rainfall in mm/h
      pluv2: pluv2/10,      # Previous hour accumulated rainfall in mm/h
      pluv3: pluv3/10,      # Last 24h accumulated rainfall in mm/day
      temp: temp/10,        # Temperature in °C
      hum: hum,             # Humidity in %
      pres: pres/10,        # Pressure in hPa
      anemo: anemo/10,      # Anemometer in km/h
      lux: lux,             # Luxes in lux
      vane: vane_map[vane], # vane
      wm: (52117.7-(6.83636*(wm/8)))/((wm/8)-47.619)*(-10), # Soil Water Tension in hPa
      power: power          # Battery level in %
    }
  end
  def tests() do
    [
      {
        :parse_hex, "0000000000000097003D25E300400A7700094FB80064", %{meta: %{frame_port: 30}}, %{
          wm: -138.5252410240391,
          vane: "S",
          temp: 15.1,
          pres: 969.9,
          power: 100,
          pluv3: 0,
          pluv2: 0,
          pluv1: 0,
          lux: 2679,
          hum: 61,
          anemo: 6.4
        }
      },
    ]
  end
end
