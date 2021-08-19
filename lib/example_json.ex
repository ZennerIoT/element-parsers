defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # ELEMENT IoT Example parser for parsing json from a packet
  #
  # Changelog:
  #   2020-12-10 [jb]: Initial implementation for payload_encoding=json
  #   2021-08-10 [jb]: Added handling of "utf8" payload encodings, like from MQTT driver.
  #

  # Using matching
  def parse(json, %{payload_encoding: encoding} = meta) do
    case to_string(encoding) do
      "json" ->
        # Already parsed to data. Not a string anymore.
        json

      "utf8" ->
        json
        |> to_string
        |> json_decode
        |> case do
          {:ok, data} -> data
          {:error, error} -> %{json_error: error}
        end

      other ->
        %{error: "unknown payload_encoding: #{other}"}
    end
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
        %{payload_encoding: "json"},
        %{"a" => 42, "b" => true, "c" => "hello"}
      },
      {
        :parse,
        "{\"a\":42,\"b\":true,\"c\":\"hello\"}",
        %{payload_encoding: "utf8"},
        %{"a" => 42, "b" => true, "c" => "hello"}
      },
      {
        :parse,
        "{invalid_json+-%&/(",
        %{payload_encoding: "utf8"},
        %{json_error: {:invalid, "i", 1}}
      },
      {
        :parse,
        "42",
        %{payload_encoding: "hey"},
        %{error: "unknown payload_encoding: hey"}
      }
    ]
  end
end
