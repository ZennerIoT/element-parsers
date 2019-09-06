defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Libelium Smart Cities Device
  # According to documentation provided by Libelium
  # Link: http://www.libelium.com/development/plug-sense
  # Documentation: http://www.libelium.com/downloads/documentation/waspmote_plug_and_sense_technical_guide.pdf
  #
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #

  def parse(<<temp::big-16, hum::big-16, pres::big-16, range::big-16, lum::big-16, noise::big-16, batt::big-16>>, _meta) do
    # return value map
    %{
      temperature: temp/10,  # Temperature in °C
      humidity: hum/10,    # Humidity in %
      pressure: pres/10,  # Pressure in hPa
      range: range/100, # distance in m
      luminosity: lum, # luminosity in lux
      noise_level: noise/10, # noise in dBa
      battery: batt    # Battery level in %
    }
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

end
