defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for ZIS Oskar 1.0
  # not commercially available
  
  def parse(<<distance::little-size(16), battery::little-size(16)>>, _meta) do
    height = 90;

    case distance < height do
      true ->
        %{
          distance_cm: distance,
          distance_percent: height - distance,
          battery_volt: battery / 1024 * 3.3,
        }
      false ->
        %{
            distance_cm: distance,
            battery_volt: battery / 1024 * 3.3,
        }
    end
  end

  def parse(_, _), do: []

end
