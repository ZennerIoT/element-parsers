defmodule Parser do
  use Platform.Parsing.Behaviour

  # Example parser for matching a frame_port (FPort) of a LoRaWAN message.
  #
  # In the LoRaWAN protocol the fport is a value designed to differentiate types of messages.
  #
  # Changelog:
  #   2018-06-07 [jb]: Initial version for demonstrating purposes.
  #

  # The second argument is a map containing metadata that include the frame_port.
  def parse(<<1,2,3>>, %{meta: %{frame_port: 42}}) do
    %{
      success: 1
    }
  end

  def tests() do
    [
      {
        :parse_hex, "010203", %{meta: %{frame_port: 42}}, %{success: 1},
      },
    ]
  end
end
