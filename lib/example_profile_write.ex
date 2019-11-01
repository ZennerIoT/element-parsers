defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # Example parser for writing values to device profile
  #
  # A profile has a "technical name" and each field has its own "technical name".
  # These are needed here, NOT the display name!
  #

  # Not needed to preload a profile when writing to it.

  def parse(<<value::16>>, %{meta: %{frame_port: 42}}) do
    {
      %{
        value: value,
      },
      [
        fields: %{
          my_profile: %{
            my_field: "new_value",
          }
        },
      ]
    }
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  def tests() do
    [
      {
        # No profile given, default factor =1 will be used.
        :parse_hex, "1337", %{meta: %{frame_port: 42}}, {%{value: 4919}, [fields: %{my_profile: %{my_field: "new_value"}}]},
      },
    ]
  end
end
