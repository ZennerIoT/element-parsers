defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Gupsy temperature and humidity sensor
  # According to documentation provided by Gupsy
  #
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #

  def parse(<<humid::big-16, temp::big-16, vbat::big-16>>, _meta) do
    %{
      humid: (125*humid)/(65536)-6,
      temp: (175.72*temp)/(65536)-46.85,
      vbat: 10027.008/vbat,
    }
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

end
