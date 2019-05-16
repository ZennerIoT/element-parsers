defmodule Parser do
  use Platform.Parsing.Behaviour

  require Logger

  # ELEMENT IoT Parser for ZIS Oskar 1.0
  # not commercially available
  #
  # Changelog:
  #   2019-05-09 [gw]: Added tests/0 and fields/0. Defining unit in fields/0. Refactored parse functions.
  
  def parse(<<distance::little-16, battery::little-16>>, _meta) do
    height = 90

    case distance < height do
      true ->
        %{
          distance: distance,
          fill_level: Float.round(distance / height, 2),
          remaining_distance: height - distance,
          battery: battery / 1024 * 3.3,
        }
      false ->
        %{
          distance: distance,
          fill_level: 100,
          battery: battery / 1024 * 3.3,
        }
    end
  end

  def parse(payload, meta) do
    Logger.info("Could not match payload #{inspect payload} on fPort #{get_in(meta, [:meta, :frame_port])}")
    []
  end

  def fields() do
    [
      %{
        field: "type",
        display: "Typ",
      },
      %{
        field: "distance",
        display: "Distanz",
        unit: "cm",
      },
      %{
        field: "fill_level",
        display: "Füllstand",
        unit: "%",
      },
      %{
        field: "remaining_distance",
        display: "Verbleibende Höhe",
        unit: "cm",
      },
      %{
        field: "battery",
        display: "Batterie",
        unit: "V",
      },
    ]
  end

  def tests() do
    [
      {
        :parse_hex, "5800F002", %{meta: %{frame_port: 1}}, %{
          battery: 2.4234375,
          distance: 88,
          fill_level: 0.98,
          remaining_distance: 2,
        }
      }
    ]
  end

end
