defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # ELEMENT IoT Parser for PNI PlacePod parksensor devices.
  #
  # Link: https://www.pnicorp.com/placepod/
  #
  # Changelog:
  #   2019-12-10 [jb]: Initial implementation according to "PNI PlacePod Sensor - Communications Protocol.pdf"
  #

  def parse(payload, _meta) when is_binary(payload) do
    _parse(payload, %{})
  end

  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  #--- Internals ---

  # Recalibrate Response
  defp _parse(<<0x01, 0x01, data, rest::binary>>, reading) do
    _parse(rest, Map.merge(reading, %{recalibrate_success: data}))
  end

  # Temperature Sensor
  defp _parse(<<0x02, 0x67, data::16-signed, rest::binary>>, reading) do
    temperature = round_float(data * 0.1) # 0.1 °C Signed MSB
    _parse(rest, Map.merge(reading, %{temperature: temperature}))
  end

  # Battery Sensor
  defp _parse(<<0x03, 0x02, data::16-signed, rest::binary>>, reading) do
    battery = round_float(data * 0.01) # 0.01 Volt MSB
    _parse(rest, Map.merge(reading, %{battery: battery}))
  end

  # Parking Status
  defp _parse(<<0x15, 0x66, data::8, rest::binary>>, reading) do
    _parse(rest, Map.merge(reading, %{
      parking_status: data,
      parking_status_name: parking_status_name(data),
    }))
  end

  # Deactivate Response
  defp _parse(<<0x1C, 0x01, data::8, rest::binary>>, reading) do
    deactivate_response = data # 1 = done
    _parse(rest, Map.merge(reading, %{deactivate_response: deactivate_response}))
  end

  # Vehicle Count
  defp _parse(<<0x21, 0x00, count::8, rest::binary>>, reading) do
    _parse(rest, add_vehicle_count(reading, count))
  end

  # Keep-Alive
  defp _parse(<<0x37, 0x66, data::8, rest::binary>>, reading) do
    _parse(rest, Map.merge(reading, %{
      keep_alive: 1,
      parking_status: data,
      parking_status_name: parking_status_name(data),
    }))
  end
  defp _parse(<<0x37, 0x00, count::8, rest::binary>>, reading) do
    reading = reading
      |> Map.merge(%{keep_alive: 1})
      |> add_vehicle_count(count)
    _parse(rest, reading)
  end

  # Reboot Response
  defp _parse(<<0x3F, 0x01, payload::8, rest::binary>>, reading) do
    _parse(rest, Map.merge(reading, %{reboot_response: payload}))
  end

  defp _parse(<<>>, data), do: data

  defp _parse(unparseable, data) do
    _parse(<<>>, Map.merge(data, %{unparseable: "#{Base.encode16 unparseable}"}))
  end

  defp parking_status_name(0), do: :vacant
  defp parking_status_name(1), do: :occupied
  defp parking_status_name(_), do: :unknown

  defp add_vehicle_count(data, count) when count > 0x80, do: Map.merge(data, %{event: :reboot_or_recalibration})
  defp add_vehicle_count(data, count), do: Map.merge(data, %{vehicle_count: count})

  defp round_float(val) do
    Float.round(val/1, 4)
  end


  def fields do
    [
      %{
        field: "parking_status",
        display: "Parkstatus"
      },
      %{
        field: "vehicle_count",
        display: "Vehicle Count",
      },
      %{
        field: "battery",
        display: "Battery",
        unit: "V"
      },
      %{
        field: "temperature",
        display: "Temperature",
        unit: "°C"
      },
    ]
  end

  def tests() do
    [
      # All fields from docs
      {:parse_hex, "3F0101 376600 210020 1C0101 156601 0302015E 026700F0 010101 CAFEBABE", %{}, %{

        parking_status: 1,
        parking_status_name: :occupied,

        vehicle_count: 32,

        battery: 3.5, # V
        temperature: 24.0, # °C

        keep_alive: 1,

        reboot_response: 1,
        recalibrate_success: 1,
        deactivate_response: 1,

        unparseable: "CAFEBABE",
      }},

      # Real payloads
      {:parse_hex, "376601", %{}, %{
        keep_alive: 1,
        parking_status: 1,
        parking_status_name: :occupied
      }},

      {:parse_hex, "156601", %{}, %{
        parking_status: 1,
        parking_status_name: :occupied
      }},

      {:parse_hex, "026700C3376601", %{}, %{
        keep_alive: 1,
        parking_status: 1,
        parking_status_name: :occupied,
        temperature: 19.5
      }},

      {:parse_hex, "0302016D026700E1156600", %{}, %{
        battery: 3.65,
        parking_status: 0,
        parking_status_name: :vacant,
        temperature: 22.5
      }},
    ]
  end

end