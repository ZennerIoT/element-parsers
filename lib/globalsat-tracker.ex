defmodule Parser do
  use Platform.Parsing.Behaviour

  def parse(event, _meta) do
    <<foo::size(8), fix::size(8), bat::size(8), lat::size(32), lon::size(32)>> = event
    {
      %{
        battery: bat
      },
      [
        location: {  lon*0.000001, lat*0.000001 }
      ]
    }
  end
end
