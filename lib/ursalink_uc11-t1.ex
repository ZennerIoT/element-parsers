defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # Parser for Ursalink UC11-T1 LoRaWAN Temperature Sensor.
  #
  # According to documentation: https://resource.ursalink.com/document/t1_payload_structure_en.pdf
  #
  # Changelog:
  #   2020-04-27 [jb]: Initial version for payload structure v1.4
  #

  def parse(payload, %{meta: %{frame_port: 85}}) do
    parse_part(payload, %{})
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  # Channel 1, Temperature
  def parse_part(<<0x01, 0x67, temp::little-16-signed, rest::binary>>, row) do
    rest
    |> parse_part(row)
    |> Map.merge(%{
      temperature: temp/10,
    })
  end

  # Channel 2, Humidity
  def parse_part(<<0x02, 0x68, humi, rest::binary>>, row) do
    rest
    |> parse_part(row)
    |> Map.merge(%{
      humidity: humi/2,
    })
  end

  # Channel 3, Battery
  def parse_part(<<0x03, 0x75, battery, rest::binary>>, row) do
    rest
    |> parse_part(row)
    |> Map.merge(%{
      battery: battery,
    })
  end

  # Channel 255, Device restart
  def parse_part(<<0xFF, 0x0b, 0xff, rest::binary>>, row) do
    rest
    |> parse_part(row)
    |> Map.merge(%{
      device_restart: 1,
    })
  end

  # Channel 255, Device version
  def parse_part(<<0xFF, 0x01, version, rest::binary>>, row) do
    rest
    |> parse_part(row)
    |> Map.merge(%{
      device_version: version,
    })
  end

  # Channel 255, Device SN
  def parse_part(<<0xFF, 0x08, sn::binary-6, rest::binary>>, row) do
    rest
    |> parse_part(row)
    |> Map.merge(%{
      device_sn: Base.encode16(sn),
    })
  end

  # Channel 255, Device Hardware Version
  def parse_part(<<0xFF, 0x09, v1::binary-1, v2::binary-1, rest::binary>>, row) do
    rest
    |> parse_part(row)
    |> Map.merge(%{
      hardware_version: "#{Base.encode16(v1)}.#{Base.encode16(v2)}",
    })
  end

  # Channel 255, Device Software Version
  def parse_part(<<0xFF, 0x0a, v1::binary-1, v2::binary-1, rest::binary>>, row) do
    rest
    |> parse_part(row)
    |> Map.merge(%{
      software_version: "#{Base.encode16(v1)}.#{Base.encode16(v2)}",
    })
  end

  # Channel 255, Temperature Alarm
  def parse_part(<<0xFF, 0x0d, mode, lower_tres::little-16-signed, upper_tres::little-16-signed, temp::little-16-signed, rest::binary>>, row) do
    rest
    |> parse_part(row)
    |> Map.merge(%{
      temperature_alarm: mode,
      temperature_alarm_lower: lower_tres,
      temperature_alarm_upper: upper_tres/10,
      temperature: temp/10,
    })
  end

  # Channel 255, ? undocumented ?
  def parse_part(<<0xFF, 0x13, _down_know, rest::binary>>, row) do
    rest
    |> parse_part(row)
  end

  def parse_part(<<>>, row), do: row
  def parse_part(rest, row), do: Map.merge(row, %{error: :invalid_payload, payload_rest: Base.encode16(rest)})

  def fields do
    [
      %{
        "field" => "temperature",
        "display" => "Temperature",
        "unit" => "°C",
      },
      %{
        "field" => "humidity",
        "display" => "Humidity",
        "unit" => "%",
      },
      %{
        "field" => "battery",
        "display" => "Battery",
        "unit" => "%",
      },

      %{
        "field" => "device_restart",
        "display" => "Device Restart",
      },
      %{
        "field" => "device_version",
        "display" => "Device Version",
      },
      %{
        "field" => "device_sn",
        "display" => "Device Serial",
      },

      %{
        "field" => "hardware_version",
        "display" => "Hardware Version",
      },
      %{
        "field" => "software_version",
        "display" => "Software Version",
      },
    ]
  end

  def tests() do
    [
      # From docs

      {
        :parse_hex,
        "01671301026873",
        %{meta: %{frame_port: 85}},
        %{
          humidity: 57.5,
          temperature: 27.5
        },
      },

      {
        :parse_hex,
        "0167130102687303755a",
        %{meta: %{frame_port: 85}},
        %{
          humidity: 57.5,
          temperature: 27.5,
          battery: 90,
        },
      },

      {
        :parse_hex,
        "ff0bffff0101",
        %{meta: %{frame_port: 85}},
        %{device_restart: 1, device_version: 1},
      },

      {
        :parse_hex,
        "ff08612291363479",
        %{meta: %{frame_port: 85}},
        %{device_sn: "612291363479"},
      },

      {
        :parse_hex,
        "ff090120ff0a0110",
        %{meta: %{frame_port: 85}},
        %{hardware_version: "01.20", software_version: "01.10"},
      },

      {
        :parse_hex,
        "ff0d0a0f27c8002d01",
        %{meta: %{frame_port: 85}},
        %{
          temperature: 30.1,
          temperature_alarm: 10,
          temperature_alarm_lower: 9999,
          temperature_alarm_upper: 20.0
        },
      },

      # From real device

      {
        :parse_hex,
        "037500",
        %{meta: %{frame_port: 85}},
        %{battery: 0},
      },

      {
        :parse_hex,
        "FF0BFFFF0101",
        %{meta: %{frame_port: 85}},
        %{device_restart: 1, device_version: 1},
      },

      {
        :parse_hex,
        "FF08641094890519",
        %{meta: %{frame_port: 85}},
        %{device_sn: "641094890519"},
      },

      {
        :parse_hex,
        "FF090130FF0A0123FF1302",
        %{meta: %{frame_port: 85}},
        %{hardware_version: "01.30", software_version: "01.23"},
      },

      {
        :parse_hex,
        "01670E01026841",
        %{meta: %{frame_port: 85}},
        %{humidity: 32.5, temperature: 27.0},
      },
    ]
  end
end
