defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # Example parser for using device location in reading.
  #
  # Changelog:
  #   2019-09-30 [jb]: Initial implementation
  #

  # Using matching
  def parse(_payload, %{device: %{location: %{coordinates: {lon, lat}}}} = _meta) do
    %{
      gps_lat: lat,
      gps_lon: lon,
    }
  end
  # Using get()
  def parse(_payload, meta) do
    %{
      gps_lat: get(meta, [:device, :location, :coordinates, 1]),
      gps_lon: get(meta, [:device, :location, :coordinates, 0]),
    }
  end

  def tests() do
    [
      {:parse_hex, "", %{device: %{location: %{coordinates: {9.99, 53.55}}}}, %{gps_lat: 53.55, gps_lon: 9.99}},
    ]
  end
end
