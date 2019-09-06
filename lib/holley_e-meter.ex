defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Holley e-meter
  # According to documentation provided by Holley
  #
  # Test hex payload: "03000005"
  #
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #

  def parse(<<version::2, qualifier::5, status::1, register_value::24>>, _meta) do
    %{
      register_value: register_value,
      version: version,
      version_name: if(version==0, do: "v1", else: "rfu"),
      status: status,
      error: (status == 0),
      qualifier: qualifier,
    }
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end


  # defining fields for visualisation
  def fields do
  [
    %{
      "field" => "register_value",
      "display" => "A+",
      "unit" => "kWh"
    }
  ]
  end

  # Test case and data for automatic testing
  def tests() do
    [
      {
        :parse_hex, "03000005", %{}, %{
          error: false,
          qualifier: 1,
          register_value: 5,
          version: 0,
          version_name: "v1",
          status: 1
        }
      },
    ]
  end
end
