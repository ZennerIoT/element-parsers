defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for RFI Remote Power Switch
  #
  # Test hex payload: "01"
  #
  # Changelog:
  #   2020-03-17 [as]: Initial implementation
  #

  def parse(<<status::8>>, %{meta: %{frame_port: 1}}) do
    %{
      relais_state: status,
      status: if(status==0, do: "off", else: "on"),
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
      field: "relais_state",
      display: "Relais state",
    },
    %{
      field: "status",
      display: "Status"
    }
  ]
  end

  # Test case and data for automatic testing
  def tests() do
    [
      {
        :parse_hex, "01", %{meta: %{frame_port: 1}},
         %{
          relais_state: 01,
          status: "on",
        }
      },
    ]
  end
end
