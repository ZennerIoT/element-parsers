defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #(<<temperature::8, counter::15>>, %{meta: %{frame_port: 1}})
  def parse(<<battery::8,value::16-big,status::8,error::8,alarm::8,brightness::16-little>>, %{meta: %{frame_port: 25}}) do
    %{
      battery: battery,
      value: value,
      #status verarbeiten,
      #error verarbeiten,
      #alarm verarbeiten,
      brightness: brightness
    }

  end

  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  def fields() do

  end

  def tests() do
    [
      {
        :parse_hex, "642710E1007F1027", %{meta: %{frame_port1}}, %{
          alerttype: "Alarm",
          battery: 100,
          brightness: 100000,
          button_pressed: true,
          door_open: true,
          external: false,
          internal: false,
          interrupt: true,
          movement: true,
          movement_counter: 15,
          normal: true,
          startup: true,
          value: 10000
        }
      }
    ]
  end
end
