defmodule Parser do
  use Platform.Parsing.Behaviour

  # Example parser for reading values from device profile
  #
  # A profile has a "technical name" and each field has its own "technical name".
  # These are needed here, NOT the display name!
  #

  def preloads do
    [device: [profile_data: [:profile]]]
  end

  def parse(<<value::16>>, %{meta: %{frame_port: 42}} = meta) do
    factor = get(meta, [:device, :fields, :my_profile, :my_field], 1)
    %{
      value: value * factor,
    }
  end

  def tests() do
    [
      {
        # No profile given, default factor =1 will be used.
        :parse_hex, "1337", %{meta: %{frame_port: 42}}, %{value: 4919},
      },
      {
        # Profile has factor value =2.
        :parse_hex, "1337", %{meta: %{frame_port: 42}, fields: %{my_profile: %{my_field: 2}}}, %{value: 9838},
      },
    ]
  end
end
