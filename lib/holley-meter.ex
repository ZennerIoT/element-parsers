defmodule Parser do
  use Platform.Parsing.Behaviour

  # Test hex payload: "03000005"
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

  def parse(_event, _meta) do
    # Expecting binary values, no maps.
    [] # Empty result
  end
end
