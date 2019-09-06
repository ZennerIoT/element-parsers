defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for GlobalsSat GPS Tracker
  # According to documentation provided by GlobalSat
  # Link: http://www.globalsat.com.tw/en/product-199335/LoRaWAN%E2%84%A2-Compliant-GPS-Tracker-LT-100-Series.html#a
  #
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #

  def parse(event, _meta) do
    <<_foo::size(8), _fix::size(8), bat::size(8), lat::size(32), lon::size(32)>> = event
    {
      %{
        battery: bat
      },
      [
        location: {  lon*0.000001, lat*0.000001 }
      ]
    }
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

end
