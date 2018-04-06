defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for Libelium Smart Parking Sensor with Firmware v3
  # Link: http://www.libelium.com/development/smart-parking/documentation/plug-sense-smart-parking-technical-guide/
  # Docs: http://www.libelium.com/downloads/documentation/smart_parking_technical_guide.pdf

  def parse(<<parking_slot_status::1, battery_state::1, _reserved::2, frame_type::4, frame_counter::8, rest::binary>>, _meta) do

    data = %{
      parking_slot_status: parking_slot_status,
      parking_slot_status_name: %{0 => "empty", 1 =>"occupied"}[parking_slot_status],

      frame_type: frame_type,
      frame_type_name: "unknown", # Will be set by parse_frame_rest()
      frame_counter: frame_counter, # This byte can be used to detect lost frames (sent by the node but not received).

      battery_state: battery_state,
      battery_state_name: %{0 => "good", 1 =>"change"}[battery_state],
    }

    parse_frame_rest(frame_type, rest, data)
  end

  # RSSI frame
  def parse_frame_rest(8, <<hours::8, minutes::8, temperature::8-signed, x_axis::16, y_axis::16, z_axis::16>>, data) do
    Map.merge(data, %{
      frame_type_name: "rssi_frame",
      hours: hours,
      minutes: minutes,
      temperature: temperature,
      x_axis: x_axis,
      y_axis: y_axis,
      z_axis: z_axis,
    })
  end
  def parse_frame_rest(_, _, data), do: data


  # Test cases and data for automatic testing.
  def tests() do
    [
      # RSSI Frame
      {:parse_hex, "080A00001F00C60561ED91", %{}, %{
        battery_state: 0,
        battery_state_name: "good",
        frame_counter: 10,
        frame_type: 8,
        frame_type_name: "rssi_frame",
        hours: 0,
        minutes: 0,
        parking_slot_status: 0,
        parking_slot_status_name: "empty",
        temperature: 31,
        x_axis: 198,
        y_axis: 1377,
        z_axis: 60817
      }},


      # Invalid frame_type
      {:parse_hex, "090A00001F00C60561ED91", %{}, %{
        battery_state: 0,
        battery_state_name: "good",
        frame_counter: 10,
        frame_type: 9,
        frame_type_name: "unknown",
        parking_slot_status: 0,
        parking_slot_status_name: "empty"
      }},
    ]
  end
end