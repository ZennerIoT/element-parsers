defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # ELEMENT IoT Parser for device EXAMPLE that will provide EXAMPLE data.
  #
  # Changelog:
  #   2019-05-09 [jb]: Initial implementation according to "Example-Payload-v1.pdf"
  #

  def parse(<<v1, v2, v3>>, %{meta: %{frame_port: 1}}) do
    %{
      type: :boot,
      version: "#{v1}.#{v2}.#{v3}"
    }
  end

  def parse(<<distance::32>>, %{meta: %{frame_port: 2}}) do
    %{
      type: :measurement,
      distance: distance
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

  # Define fields with human readable name and a SI unit if available.
  def fields() do
    [
      # The first field should be a numeric value, so it can be used for graphs.
      %{
        field: "distance",
        display: "Distanz",
        unit: "cm"
      },
      %{
        field: "type",
        display: "Typ"
      }
    ]
  end

  def tests() do
    [
      # Test format:
      # {:parse_hex, received_payload_as_hex, meta_map, expected_result},

      {:parse_hex, "010203", %{meta: %{frame_port: 1}}, %{type: :boot, version: "1.2.3"}},
      {:parse_hex, "12345678", %{meta: %{frame_port: 2}},
       %{type: :measurement, distance: 305_419_896}}
    ]
  end
end
