defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Libelium Smart Environment Device
  # According to documentation provided by Libelium
  # Link: http://www.libelium.com/development/plug-sense
  # Documentation: http://www.libelium.com/downloads/documentation/waspmote_plug_and_sense_technical_guide.pdf
  #
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #

  def parse(<<so2::big-16, o3::big-16, co::big-16, no2::big-16, temp::big-16-signed, hum::big-16, pres::big-16, pm1::big-16, pm25::big-16, pm10::big-16, power::big-16>>, _meta) do

    # return value map
    %{
      so2: so2/1000,  # Sulfur Dioxide SO2 in ppm
      o3: o3/1000,    # Ozone O3 in ppm
      co: co/1000,    # Carbon Monoxide CO in ppm
      no2: no2/1000,  # Nitric Dioxide NO2 in ppm
      temp: temp/10,  # Temperature in °C
      hum: hum/10,    # Humidity in %
      pres: pres/10,  # Pressure in hPa
      pm1: pm1/100,   # Particle Matter PM1 in µg/m³
      pm25: pm25/100, # Particle Matter PM2,5 in µg/m³
      pm10: pm10/100, # Particle Matter PM10 in µg/m³
      power: power    # Battery level in %
    }
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

end
