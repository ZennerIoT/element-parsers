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

  def parse(
        <<temp::big-16, hum::big-16, pres::big-16, range::big-16, lum::big-16, noise::big-16,
          batt::big-16>>,
        _meta
      ) do
    # return value map
    %{
      # Temperature in °C
      temperature: temp / 10,
      # Humidity in %
      humidity: hum / 10,
      # Pressure in hPa
      pressure: pres / 10,
      # distance in m
      range: range / 100,
      # luminosity in lux
      luminosity: lum,
      # noise in dBa
      noise_level: noise / 10,
      # Battery level in %
      battery: batt
    }
  end

  def parse(payload, meta) do
    Logger.warn(
      "Could not parse payload #{inspect(payload)} with frame_port #{
        inspect(get_in(meta, [:meta, :frame_port]))
      }"
    )

    []
  end
end
