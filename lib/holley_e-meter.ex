defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Holley e-meter.
  # According to documentation provided by Holley.
  #
  # Name: Holley E-Meter
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #   2021-04-08 [jb]: Added new payload format.
  #

  # Original Payload
  def parse(<<version::2, qualifier::5, status::1, register_value::24>>, _meta) do
    %{
      register_value: register_value,
      version: version,
      version_name: if(version == 0, do: "v1", else: "rfu"),
      status: status,
      error: status == 0,
      qualifier: qualifier
    }
  end

  # New Format 2021 (?)
  def parse(
        <<
          _undocumented::8,
          obis180::40,
          obis181::40,
          obis182::40,
          obis280::40,
          obis281::40,
          obis282::40,
          summeleistung::24,
          phase1::24,
          phase2::24,
          phase3::24,
          status::binary-4,
          sekundeindex::32
        >>,
        _meta
      ) do
    # Byte-Länge: Inhalt
    # 5: Verbrauch 1.8.0
    # 5: Verbrauch 1.8.1
    # 5: Verbrauch 1.8.2
    # 5: Verbrauch 2.8.0
    # 5: Verbrauch 2.8.1
    # 5: Verbrauch 2.8.2
    # 3: Summeleistung
    # 3: Momentanleistung von Phase-1
    # 3: Momentanleistung von Phase-2
    # 3: Momentanleistung von Phase-3
    # 4: Statuswort
    # 4: Sekundeindex
    %{
      # kWh
      "1-0:1.8.0" => obis180 / 10000,
      "1-0:1.8.1" => obis181 / 10000,
      "1-0:1.8.2" => obis182 / 10000,
      "1-0:2.8.0" => obis280 / 10000,
      "1-0:2.8.1" => obis281 / 10000,
      "1-0:2.8.2" => obis282 / 10000,
      # w
      summeleistung: summeleistung,
      phase1: phase1,
      phase2: phase2,
      phase3: phase3,
      sekundeindex: sekundeindex,
      status: Base.encode16(status)
    }
  end

  def parse(payload, meta) do
    Logger.warn(
      "Could not parse payload #{inspect(payload)} with frame_port #{
        inspect(get_in(meta, [:meta, :frame_port]))
      }"
    )

    []
  end

  # defining fields for visualisation
  def fields do
    Enum.map(
      [
        "1-0:1.8.0",
        "1-0:1.8.1",
        "1-0:1.8.2",
        "1-0:2.8.0",
        "1-0:2.8.1",
        "1-0:2.8.2"
      ],
      fn o ->
        %{
          "field" => o,
          "display" => o,
          "unit" => "kWh"
        }
      end
    ) ++
    [
      %{
        "field" => "register_value",
        "display" => "A+",
        "unit" => "kWh"
      }
    ]
  end

  # Test case and data for automatic testing
  def tests() do
    [
      {
        :parse_hex,
        "03000005",
        %{
          _comment: "original payload"
        },
        %{
          error: false,
          qualifier: 1,
          register_value: 5,
          version: 0,
          version_name: "v1",
          status: 1
        }
      },
      {
        :parse_hex,
        "
        11
        00000025BD
        00000025BD
        0000000000
        0000000000
        0000000000
        0000000000
        000000
        000000
        000000
        000000
        00100204
        00C4C73D
        ",
        %{
          _comment: "New payload (?)"
        },
        %{
          :phase1 => 0,
          :phase2 => 0,
          :phase3 => 0,
          :sekundeindex => 12_896_061,
          :status => "00100204",
          :summeleistung => 0,
          "1-0:1.8.0" => 0.9661,
          "1-0:1.8.1" => 0.9661,
          "1-0:1.8.2" => 0.0,
          "1-0:2.8.0" => 0.0,
          "1-0:2.8.1" => 0.0,
          "1-0:2.8.2" => 0.0
        }
      }
    ]
  end
end
