defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # Parser for Siconia sensor according to standard AOT program
  # Author F. Wolf fw@alpha-omega-technology.de
  #
  # Changelog:
  #   2019-xx-xx [fw]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #

  def parse(<<temp::signed-little-32, humid::little-32, bat::little-32>>, _meta) do

  %{
    temperature: temp/100,
    humidity: humid/100,
    battery: bat,
  }
  end

  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  def fields do
    [
      %{
        "field" => "battery",
        "display" => "Batterieladezustand",
        "unit" => "%"
      },
      %{
        "field" => "temperature",
        "display" => "Temperature",
        "unit" => "°C"
      },
      %{
        "field" => "humidity",
        "display" => "Relative humidity",
        "unit" => "%"
      }
    ]
  end
end
