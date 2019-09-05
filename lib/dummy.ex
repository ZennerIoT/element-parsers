defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # Dummy Data parser for ELEMENT IoT.
  #
  # This parser can be used with a "Dummy Driver" with a expected value range of 1..100
  #
  # Changelog:
  #   2019-09-05 [jb]: Initial implementation supporting reading location.
  #

  # Add a reading location if this function returns true.
  defp add_location?(), do: true


  def parse(%{"payload" => value}, _meta) do
    %{
      type: :dummy,
      value: value,
    }
    |> add_location(value)
  end
  def parse(payload, _meta) do
    Logger.warn("Could not parse payload #{inspect payload}, expected dummy data.")
    []
  end

  def fields() do
    [
      %{
        field: "type",
        display: "Typ",
      },
      %{
        field: "value",
        display: "Value",
      },
    ]
  end

  defp add_location(reading, value) do
    case add_location?() do
      true ->
        # Box around Hamburg
        lat_min = 9.670835
        lat_max = 10.471977
        lon_min = 53.324266
        lon_max = 53.779132

        lat = lat_min + (((lat_max - lat_min) / 100) * value)
        lon = lon_min + (((lon_max - lon_min) / 100) * value)

        {reading, [location: {lat, lon}]}
      _ ->
        {reading, []}
    end
  end

  def tests() do
    [
      {:parse, %{"payload" => 42}, %{}, {%{type: :dummy, value: 42}, [location: {10.00731464, 53.51530972}]}},
    ]
  end
end
