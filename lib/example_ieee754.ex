defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # Example parser for a floating point value (IEEE-754) as part of a LoRaWAN message.
  #
  # Name: Example parser for parsing float payloads
  # Changelog:
  #   2019-03-04 [as]: Initial version for demonstrating purposes.
  #

  def parse(<<data::float-32>>, _meta) do
    # Also possible: float-signed-32 or float-signed-little-32
    %{
      value: data
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

  def tests() do
    [
      {
        :parse_hex,
        "41500000",
        %{},
        %{value: 13.0}
      }
    ]
  end
end
