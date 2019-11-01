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
  def parse(<<1,2,3>>, %{device: %{location: %{coordinates: {lon, lat}}}} = _meta) do
    %{
      gps_lat: lat,
      gps_lon: lon,
    }
  end
  # Using get()
  def parse(<<1,2,3>>, meta) do
    %{
      gps_lat: get(meta, [:device, :location, :coordinates, 1]),
      gps_lon: get(meta, [:device, :location, :coordinates, 0]),
    }
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  def tests() do
    [
      {:parse_hex, "010203", %{device: %{location: %{coordinates: {9.99, 53.55}}}}, %{gps_lat: 53.55, gps_lon: 9.99}},
    ]
  end
end
