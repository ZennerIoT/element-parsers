defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # Parser for Cayenne LPP Protocol from mydevices.com
  #
  # Documentation: https://developers.mydevices.com/cayenne/docs/lora/#lora-cayenne-low-power-payload
  #
  # Changelog:
  #   2019-12-02 [jb]: Initial implementation.
  #

  def parse(payload, _meta) when is_binary(payload) do
    payload
    |> _parse([], [])
    |> apply_options
  end

  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  #--- Internals ---

  defp apply_options({rows, opts}) do
    Enum.map(rows, fn(row) ->
      {row, opts}
    end)
  end

  # Digital Input
  defp _parse(<<channel, 0x00, data, rest::binary>>, list, opts) do
    data = %{
      digital_input: data,
      channel: channel,
    }
    _parse(rest, [data | list], opts)
  end

  # Digital Output
  defp _parse(<<channel, 0x01, data, rest::binary>>, list, opts) do
    data = %{
      digital_output: data,
      channel: channel,
    }
    _parse(rest, [data | list], opts)
  end

  # Analog Input
  defp _parse(<<channel, 0x02, data::16-signed, rest::binary>>, list, opts) do
    data = %{
      analog_input: round_float(data * 0.01), # 0.01 Signed
      channel: channel,
    }
    _parse(rest, [data | list], opts)
  end

  # Analog Output
  defp _parse(<<channel, 0x03, data::16-signed, rest::binary>>, list, opts) do
    data = %{
      analog_output: round_float(data * 0.01), # 0.01 Signed
      channel: channel,
    }
    _parse(rest, [data | list], opts)
  end

  # Illuminance Sensor
  defp _parse(<<channel, 0x65, data::16, rest::binary>>, list, opts) do
    data = %{
      illuminance: data, # 1 Lux Unsigned MSB
      channel: channel,
    }
    _parse(rest, [data | list], opts)
  end

  # Presence Sensor
  defp _parse(<<channel, 0x66, data, rest::binary>>, list, opts) do
    data = %{
      presence: data, # 1
      channel: channel,
    }
    _parse(rest, [data | list], opts)
  end

  # Temperature Sensor
  defp _parse(<<channel, 0x67, data::16-signed, rest::binary>>, list, opts) do
    data = %{
      temperature: round_float(data * 0.1), # 0.1 °C Signed MSB
      channel: channel,
    }
    _parse(rest, [data | list], opts)
  end

  # Humidity Sensor
  defp _parse(<<channel, 0x68, data, rest::binary>>, list, opts) do
    data = %{
      humidity: round_float(data * 0.5), # 0.5 % Unsigned
      channel: channel,
    }
    _parse(rest, [data | list], opts)
  end

  # Accelerometer
  defp _parse(<<channel, 0x71, data_x::16-signed, data_y::16-signed, data_z::16-signed, rest::binary>>, list, opts) do
    data = %{
      accelerometer_x: round_float(data_x * 0.001), # 0.001 G Signed MSB per axis
      accelerometer_y: round_float(data_y * 0.001),
      accelerometer_z: round_float(data_z * 0.001),
      channel: channel,
    }
    _parse(rest, [data | list], opts)
  end

  # Barometer
  defp _parse(<<channel, 0x73, data::16, rest::binary>>, list, opts) do
    data = %{
      barometer: round_float(data * 0.1), # 0.1 hPa Unsigned MSB
      channel: channel,
    }
    _parse(rest, [data | list], opts)
  end

  # Gyrometer
  defp _parse(<<channel, 0x86, data_x::16-signed, data_y::16-signed, data_z::16-signed, rest::binary>>, list, opts) do
    data = %{
      gyrometer_x: round_float(data_x * 0.01), # 0.01 °/s Signed MSB per axis
      gyrometer_y: round_float(data_y * 0.01),
      gyrometer_z: round_float(data_z * 0.01),
      channel: channel,
    }
    _parse(rest, [data | list], opts)
  end

  # GPS Location
  defp _parse(<<channel, 0x88, data_x::24-signed, data_y::24-signed, data_z::24-signed, rest::binary>>, list, opts) do
    lat = data_x * 0.0001 # Latitude : 0.0001 ° Signed MSB
    lon = data_y * 0.0001 # Longitude : 0.0001 ° Signed MSB
    alt = data_z * 0.01 # Altitude : 0.01 meter Signed MSB
    data = %{
      gps_lat: lat,
      gps_lon: lon,
      gps_alt: alt,
      channel: channel,
    }
    _parse(rest, [data | list], [{:location, {lon, lat}} | opts])
  end

  defp _parse(<<>>, list, opts), do: {list, opts}

  defp _parse(unparseable, list, opts) do
    data = %{
      unparseable: "#{Base.encode16 unparseable}",
      error: 1
    }
    _parse(<<>>, [data | list], opts)
  end


  defp round_float(val) do
    Float.round(val/1, 4)
  end



  # Define fields with human readable name and a SI unit if available.
  def fields() do
    [
      # The first field should be a numeric value, so it can be used for graphs.
      %{
        field: "temperature",
        display: "Temperature",
        unit: "°C",
      },

      %{
        field: "channel",
        display: "Channel",
      },

      %{
        field: "digital_input",
        display: "Digital Input",
      },
      %{
        field: "digital_output",
        display: "Digital Output",
      },
      %{
        field: "analog_input",
        display: "Analog Input",
      },
      %{
        field: "analog_output",
        display: "Analog Output",
      },
      %{
        field: "illuminance",
        display: "Illuminance",
        unit: "Lux",
      },
      %{
        field: "presence",
        display: "Presence",
      },
      %{
        field: "humidity",
        display: "Humidity",
        unit: "%",
      },

      %{
        field: "accelerometer_x",
        display: "Accelerometer X",
        unit: "G",
      },
      %{
        field: "accelerometer_y",
        display: "Accelerometer Y",
        unit: "G",
      },
      %{
        field: "accelerometer_z",
        display: "Accelerometer Z",
        unit: "G",
      },

      %{
        field: "barometer",
        display: "Barometer",
        unit: "hPa",
      },

      %{
        field: "gyrometer_x",
        display: "Gyrometer X",
        unit: "°/s",
      },
      %{
        field: "gyrometer_y",
        display: "Gyrometer Y",
        unit: "°/s",
      },
      %{
        field: "gyrometer_z",
        display: "Gyrometer Z",
        unit: "°/s",
      },

      %{
        field: "gps_lat",
        display: "GPS Lat",
        unit: "°",
      },
      %{
        field: "gps_lon",
        display: "GPS Lon",
        unit: "°",
      },
      %{
        field: "gps_alt",
        display: "GPS ALt",
        unit: "m",
      },
    ]
  end


  def tests() do
    [
      # From official docs
      {:parse_hex, "03 67 01 10 05 67 00 FF", nil, [
        {%{channel: 5, temperature: 25.5}, []}, {%{channel: 3, temperature: 27.2}, []}
      ]},
      {:parse_hex, "01 67 FF D7", nil, [
        {%{channel: 1, temperature: -4.1}, []}
      ]},
      {:parse_hex, "06 71 04 D2 FB 2E 00 00", nil, [
        {%{
          accelerometer_x: 1.234,
          accelerometer_y: -1.234,
          accelerometer_z: 0.0,
          channel: 6
        }, []}
      ]},
      {:parse_hex, "01 88 06 76 5f f2 96 0a 00 03 e8", nil, [
        {%{channel: 1, gps_alt: 10.0, gps_lat: 42.3519, gps_lon: -87.9094},
          [location: {-87.9094, 42.3519}]}
      ]},
      {:parse_hex, "01 00 64", nil, [
        {%{channel: 1, digital_input: 100}, []}
      ]},

      # From: https://github.com/aabadie/cayenne-lpp/blob/master/tests/check_cayenne_lpp.c
      {:parse_hex, "00 00 0A", nil, [
        {%{channel: 0, digital_input: 10}, []}
      ]},
      {:parse_hex, "01 01 19", nil, [
        {%{channel: 1, digital_output: 25}, []}
      ]},
      {:parse_hex, "00 02 02 08", nil, [
        {%{analog_input: 5.2, channel: 0}, []}
      ]},
      {:parse_hex, "01 03 09 CE", nil, [
        {%{analog_output: 25.1, channel: 1}, []}
      ]},
      {:parse_hex, "0A 65 00 7B", nil, [
        {%{channel: 10, illuminance: 123}, []}
      ]},
      {:parse_hex, "05 66 01", nil, [
        {%{channel: 5, presence: 1}, []}
      ]},
      {:parse_hex, "01 67 FF D7", nil, [
        {%{channel: 1, temperature: -4.1}, []}
      ]},
      {:parse_hex, "03 68 61", nil, [
        {%{channel: 3, humidity: 48.5}, []}
      ]},
      {:parse_hex, "0A 73 26 EA", nil, [
        {%{barometer: 996.2, channel: 10}, []}
      ]},
      {:parse_hex, "06 71 04 D2 FB 2E 00 00", nil, [
        {%{
          accelerometer_x: 1.234,
          accelerometer_y: -1.234,
          accelerometer_z: 0.0,
          channel: 6
        }, []}
      ]},
      {:parse_hex, "02 86 02 12 01 A3 FF 1A", nil, [
        {%{channel: 2, gyrometer_x: 5.3, gyrometer_y: 4.19, gyrometer_z: -2.3}, []}
      ]},
      {:parse_hex, "01 88 06 76 5E F2 96 0A 00 03 E8", nil, [
        {%{channel: 1, gps_alt: 10.0, gps_lat: 42.351800000000004, gps_lon: -87.9094},
          [location: {-87.9094, 42.351800000000004}]}
      ]},

      # Customer Payloads
      {:parse_hex, "066700E607684A038807D3060118C10051A40403021C050303C0", nil, [
        {%{analog_output: 9.6, channel: 5}, [location: {7.1873000000000005, 51.2774}]},
        {%{analog_output: 5.4, channel: 4}, [location: {7.1873000000000005, 51.2774}]},
        {%{channel: 3, gps_alt: 209.0, gps_lat: 51.2774, gps_lon: 7.1873000000000005},
          [location: {7.1873000000000005, 51.2774}]},
        {%{channel: 7, humidity: 37.0}, [location: {7.1873000000000005, 51.2774}]},
        {%{channel: 6, temperature: 23.0}, [location: {7.1873000000000005, 51.2774}]}
      ]},
      {:parse_hex, "066700E607684A038807D3070118C10055D2040302580503058C", nil, [
        {%{analog_output: 14.2, channel: 5},
          [location: {7.1873000000000005, 51.2775}]},
        {%{analog_output: 6.0, channel: 4}, [location: {7.1873000000000005, 51.2775}]},
        {%{
          channel: 3,
          gps_alt: 219.70000000000002,
          gps_lat: 51.2775,
          gps_lon: 7.1873000000000005
        }, [location: {7.1873000000000005, 51.2775}]},
        {%{channel: 7, humidity: 37.0}, [location: {7.1873000000000005, 51.2775}]},
        {%{channel: 6, temperature: 23.0}, [location: {7.1873000000000005, 51.2775}]}
      ]},
      {:parse_hex, "066700E6076848038807D3070118C1005208040301FE050303C0", nil, [
        {%{analog_output: 9.6, channel: 5}, [location: {7.1873000000000005, 51.2775}]},
        {%{analog_output: 5.1, channel: 4}, [location: {7.1873000000000005, 51.2775}]},
        {%{channel: 3, gps_alt: 210.0, gps_lat: 51.2775, gps_lon: 7.1873000000000005},
          [location: {7.1873000000000005, 51.2775}]},
        {%{channel: 7, humidity: 36.0}, [location: {7.1873000000000005, 51.2775}]},
        {%{channel: 6, temperature: 23.0}, [location: {7.1873000000000005, 51.2775}]}
      ]},
      {:parse_hex, "066700E6076848038807D3070118C1004D4E040301FE05030456", nil, [
        {%{analog_output: 11.1, channel: 5},
          [location: {7.1873000000000005, 51.2775}]},
        {%{analog_output: 5.1, channel: 4}, [location: {7.1873000000000005, 51.2775}]},
        {%{channel: 3, gps_alt: 197.9, gps_lat: 51.2775, gps_lon: 7.1873000000000005},
          [location: {7.1873000000000005, 51.2775}]},
        {%{channel: 7, humidity: 36.0}, [location: {7.1873000000000005, 51.2775}]},
        {%{channel: 6, temperature: 23.0}, [location: {7.1873000000000005, 51.2775}]}
      ]},
      {:parse_hex, "066700E607684A038807D3080118C10053A204030276050304CE", nil, [
        {%{analog_output: 12.3, channel: 5},
          [location: {7.1873000000000005, 51.2776}]},
        {%{analog_output: 6.3, channel: 4}, [location: {7.1873000000000005, 51.2776}]},
        {%{channel: 3, gps_alt: 214.1, gps_lat: 51.2776, gps_lon: 7.1873000000000005},
          [location: {7.1873000000000005, 51.2776}]},
        {%{channel: 7, humidity: 37.0}, [location: {7.1873000000000005, 51.2776}]},
        {%{channel: 6, temperature: 23.0}, [location: {7.1873000000000005, 51.2776}]}
      ]},
    ]
  end

end