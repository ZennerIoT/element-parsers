defmodule Parser do
  use Platform.Parsing.Behaviour

  # Parser for conbee HybridTag L300
  # https://www.conbee.eu/wp-content/uploads/HybridTAG-L300-Infosheet_06-18-2.pdf
  #
  # Changelog
  #   2018-08-23 [jb]: Initial version implemented using HybridTAG-L300-Infosheet_06-18-2.pdf
  #

  def parse(data, %{meta: %{frame_port: 1}}) do
    data
    |> parse_packets([])
    |> map_packets
  end

  #----------------

  def map_packets(packets) do
    packets
    |> Enum.reduce(%{}, &map_packet/2)
    |> Enum.into(%{})
  end


  # Ambient Light
  def map_packet(<<0x01, 0x01, value::16>>, acc) do
    Map.merge(acc, %{ambient_light: value})
  end

  # Temperature Sensor
  def map_packet(<<0x02, 0x01, value::float-32>>, acc) do
    Map.merge(acc, %{temperature: value})
  end

  # Humidity Sensor
  def map_packet(<<0x03, 0x01, value::16>>, acc) do
    Map.merge(acc, %{humidity: value})
  end

  # Accelerometer
  def map_packet(<<0x04, 0x01, value::signed-16>>, acc) do
    Map.merge(acc, %{accelerate_x: value})
  end
  def map_packet(<<0x04, 0x02, value::signed-16>>, acc) do
    Map.merge(acc, %{accelerate_y: value})
  end
  def map_packet(<<0x04, 0x03, value::signed-16>>, acc) do
    Map.merge(acc, %{accelerate_z: value})
  end

  # Push Button
  def map_packet(<<0x05, 0x01, value::8>>, acc) do
    Map.merge(acc, %{button_1: value})
  end
  def map_packet(<<0x05, 0x02, value::8>>, acc) do
    Map.merge(acc, %{button_2: value})
  end

  # Proximity
  def map_packet(<<0x0b, 0x01, value::16>>, acc) do
    Map.merge(acc, %{proximity: value})
  end

  # Tracking
  def map_packet(<<0x0f, 0x01, value::16>>, acc) do
    Map.merge(acc, %{localisation_id: value})
  end

  # GPS
  def map_packet(<<0x50, 0x01, value::signed-32>>, acc) do
    Map.merge(acc, %{gps_lat: value / 1000000})
  end
  def map_packet(<<0x50, 0x02, value::signed-32>>, acc) do
    Map.merge(acc, %{gps_lon: value / 1000000})
  end

  # Battery
  def map_packet(<<0x51, 0x01, value::8>>, acc) do
    Map.merge(acc, %{battery_voltage: value/10})
  end
  def map_packet(<<0x51, 0x02, value::8>>, acc) do
    Map.merge(acc, %{battery_indicator: case value do
      0x01 -> "FRESH"
      0x02 -> "FIT"
      0x03 -> "USEABLE"
      0x04 -> "REPLACE"
      _    -> "UNKOWN"
    end})
  end

  # Bluetooth SIG
  def map_packet(<<0x2A, 0x25, value::binary-6>>, acc) do
    Map.merge(acc, %{serial_number: Base.encode16(value)})
  end

  def map_packet({:error, error}, acc) do
    Map.merge(acc, %{parsing_error: error})
  end
  def map_packet(invalid, acc) do
    Map.merge(acc, %{invalid_packet_payload: inspect(invalid)})
  end


  def parse_packets(<<>>, acc), do: acc
  def parse_packets(data, acc) do
    case next_packet(data) do
      {:ok, {packet, rest}} -> parse_packets(rest, acc ++ [packet])
      {:error, _} = error -> acc ++ [error]
    end
  end

  def next_packet(<<service_data_length, packet_payload::binary-size(service_data_length), rest::binary>>) do
    {:ok, {packet_payload, rest}}
  end
  def next_packet(_invalid), do: {:error, :invalid_payload}


  def fields do
    [
      %{
        "field" => "ambient_light",
        "display" => "Ambient Light",
        "unit" => "lux"
      },
      %{
        "field" => "temperature",
        "display" => "Temperature",
        "unit" => "C°"
      },
      %{
        "field" => "humidity",
        "display" => "Humidity",
        "unit" => "%"
      },
      %{
        "field" => "accelerate_x",
        "display" => "Accelerate-X",
        "unit" => "millig"
      },
      %{
        "field" => "accelerate_y",
        "display" => "Accelerate-Y",
        "unit" => "millig"
      },
      %{
        "field" => "accelerate_z",
        "display" => "Accelerate-Z",
        "unit" => "millig"
      },
      %{
        "field" => "button_1",
        "display" => "Button-1",
      },
      %{
        "field" => "button_2",
        "display" => "Button-2",
      },
      %{
        "field" => "proximity",
        "display" => "Proximity",
        "unit" => "mm"
      },
      %{
        "field" => "localisation_id",
        "display" => "Localisation-ID",
      },
      %{
        "field" => "gps_lat",
        "display" => "GPS-Lat",
      },
      %{
        "field" => "gps_lon",
        "display" => "GPS-Lon",
      },
      %{
        "field" => "battery_voltage",
        "display" => "Battery",
        "unit" => "V"
      },
      %{
        "field" => "battery_indicator",
        "display" => "Battery Indicator",
      },
      %{
        "field" => "serial_number",
        "display" => "Serial Number",
      },
    ]
  end

  def tests() do
    [
      {
        :parse_hex,  "04010109C0", %{meta: %{frame_port: 1}}, %{ambient_light: 2496},
      },
      {
        :parse_hex,  "06020141C40000", %{meta: %{frame_port: 1}}, %{temperature: 24.5},
      },
      {
        :parse_hex,  "0403010042", %{meta: %{frame_port: 1}}, %{humidity: 66}, # There was no example in documentation
      },
      {
        :parse_hex,  "0404010035", %{meta: %{frame_port: 1}}, %{accelerate_x: 53},
      },
      {
        :parse_hex,  "0404020000", %{meta: %{frame_port: 1}}, %{accelerate_y: 0},
      },
      {
        :parse_hex,  "0404030400", %{meta: %{frame_port: 1}}, %{accelerate_z: 1024},
      },
      {
        :parse_hex,  "040403FC00", %{meta: %{frame_port: 1}}, %{accelerate_z: -1024}, # This was not in documentation, they forgot to add a negative number.
      },
      {
        :parse_hex,  "03050100", %{meta: %{frame_port: 1}}, %{button_1: 0},
      },
      {
        :parse_hex,  "03050101", %{meta: %{frame_port: 1}}, %{button_1: 1},
      },
      {
        :parse_hex,  "040B0101F4", %{meta: %{frame_port: 1}}, %{proximity: 500},
      },
      {
        :parse_hex,  "040F011234", %{meta: %{frame_port: 1}}, %{localisation_id: 4660}, # Missing example in docs.
      },
      {
        :parse_hex,  "06500102FFAC48", %{meta: %{frame_port: 1}}, %{gps_lat: 50.310216},
      },
      {
        :parse_hex,  "0351012D", %{meta: %{frame_port: 1}}, %{battery_voltage: 4.5},
      },
      {
        :parse_hex,  "03510201", %{meta: %{frame_port: 1}}, %{battery_indicator: "FRESH"},
      },
      {
        :parse_hex,  "082A250102A2BDAA11", %{meta: %{frame_port: 1}}, %{serial_number: "0102A2BDAA11"},
      },

      {
        :parse_hex,  "040101026306020141DD83F30351011D", %{meta: %{frame_port: 1}}, %{ambient_light: 611, battery_voltage: 2.9, temperature: 27.689428329467773},
      },
    ]
  end
end
