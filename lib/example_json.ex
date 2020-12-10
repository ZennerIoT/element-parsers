defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # Example parser for parsing json from a packet
  #
  # Changelog:
  #   2020-12-10 [jb]: Initial implementation
  #

  # Using matching
  def parse(json, %{payload_encoding: :json} = meta) do
    # Already parsed to data. Not a string anymore.
    json
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
        :parse_json,
        "{\"a\":42,\"b\":true,\"c\":\"hello\"}",
        %{payload_encoding: :json},
        %{"a" => 42, "b" => true, "c" => "hello"}
      }
    ]
  end
end
