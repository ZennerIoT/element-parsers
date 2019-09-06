defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for ZIS Temperature and Humidity Device
  # Not commercially available!
  
  def parse(event, _meta) do
    << temp::little-integer-16, hum::integer-16>> = event
    %{
        temperature: temp/1000,
        humidity: hum/1000
    }
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

end
