defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Libelium Smart Parking Sensor with Firmware v3
  # According to documentation, the v3 protocol seems to be compatible with v2, but not with protocol v1.
  # Link: http://www.libelium.com/development/smart-parking/documentation/plug-sense-smart-parking-technical-guide/
  # Docs: http://www.libelium.com/downloads/documentation/smart_parking_technical_guide.pdf
  #
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #   2019-11-29 [jb]: Removed all reverse engineered fields because they changed.
  #

  # Parsing v2 payloads only.
  def parse(<<parking_slot_status::1, battery_state::1, config_up_ack::1, sensor_recalibration::1, frame_type::4, frame_counter::8, rest::binary>> = payload, _meta) when byte_size(payload) == 11 do

    data = %{
      parking_slot_changed: 0,
      parking_slot_status: parking_slot_status,
      parking_slot_status_name: %{0 => "empty", 1 =>"occupied"}[parking_slot_status],

      config_up: %{0 => "ack", 1 =>"nack"}[config_up_ack],
      sensor_recalibration: sensor_recalibration,

      frame_type: frame_type,
      frame_type_name: "unknown", # Will be set by parse_frame_rest()
      frame_counter: frame_counter, # This byte can be used to detect lost frames (sent by the node but not received).

      battery_state: battery_state,
      battery_state_name: %{0 => "good", 1 =>"change"}[battery_state],
    }

    parse_frame_rest(frame_type, rest, data)
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  # Info Frame
  def parse_frame_rest(0, <<sensor_error::8, temperature::8-signed, _rest::binary>>, data) do
    Map.merge(data, %{
      parking_slot_changed: 1,
      frame_type_name: "info",
      sensor_error: sensor_error,
      temperature: temperature,
    })
  end
  # Keep Alive Frame
  def parse_frame_rest(1, <<sensor_error::8, temperature::8-signed, _rest::binary>>, data) do
    Map.merge(data, %{
      frame_type_name: "keep_alive",
      sensor_error: sensor_error,
      temperature: temperature,
    })
  end
  # Daily update Frame
  def parse_frame_rest(2, <<_rest::binary>>, data) do
    Map.merge(data, %{
      frame_type_name: "daily_update",
    })
  end
  # Error Frame
  def parse_frame_rest(3, <<_rest::binary>>, data) do
    Map.merge(data, %{
      frame_type_name: "error",
    })
  end
  # Start 1 Frame
  def parse_frame_rest(4, <<firmware_version, _rest::binary>>, data) do
    Map.merge(data, %{
      frame_type_name: "start1",
      firmware_version: firmware_version,
    })
  end
  # Start 2 Frame
  def parse_frame_rest(5, <<_rest::binary>>, data) do
    Map.merge(data, %{
      frame_type_name: "start2",
    })
  end
  # Service / Downlink / RSSI frame
  def parse_frame_rest(frame_type, <<_rest::binary>>, data) when frame_type in 6..8 do
    Map.merge(data, %{
      frame_type_name: %{6 => "service", 7 => "downlink", 8 => "rssi"}[frame_type]
    })
  end
  def parse_frame_rest(_, _, data), do: data


  # Test cases and data for automatic testing.
  def tests() do
    [

      # Info frame
      {:parse_hex, "006E000900390000000000", %{}, %{
        battery_state: 0,
        battery_state_name: "good",
        config_up: "ack",
        frame_counter: 110,
        frame_type: 0,
        frame_type_name: "info",
        parking_slot_changed: 1,
        parking_slot_status: 0,
        parking_slot_status_name: "empty",
        sensor_error: 0,
        sensor_recalibration: 0,
        temperature: 9
      }},

      # Info Frame
      {:parse_hex, "805B0009001400DE0A0801", %{}, %{
        battery_state: 0,
        battery_state_name: "good",
        config_up: "ack",
        frame_counter: 91,
        frame_type: 0,
        frame_type_name: "info",
        parking_slot_changed: 1,
        parking_slot_status: 1,
        parking_slot_status_name: "occupied",
        sensor_error: 0,
        sensor_recalibration: 0,
        temperature: 9
      }},

      # Keep Alive Frame
      {:parse_hex, "81C60014053300D90C80C8", %{}, %{
        battery_state: 0,
        battery_state_name: "good",
        config_up: "ack",
        frame_counter: 198,
        frame_type: 1,
        frame_type_name: "keep_alive",
        parking_slot_changed: 0,
        parking_slot_status: 1,
        parking_slot_status_name: "occupied",
        sensor_error: 0,
        sensor_recalibration: 0,
        temperature: 20
      }},

      # Daily update Frame
      {:parse_hex, "829F665700000D9F00FF00", %{}, %{
        battery_state: 0,
        battery_state_name: "good",
        config_up: "ack",
        frame_counter: 159,
        frame_type: 2,
        frame_type_name: "daily_update",
        parking_slot_changed: 0,
        parking_slot_status: 1,
        parking_slot_status_name: "occupied",
        sensor_recalibration: 0
      }},

      # Error Frame (From v2, in v3 its reserved)
      {:parse_hex, "0303071E01921085853AC6", %{}, %{
        battery_state: 0,
        battery_state_name: "good",
        config_up: "ack",
        frame_counter: 3,
        frame_type: 3,
        frame_type_name: "error",
        parking_slot_changed: 0,
        parking_slot_status: 0,
        parking_slot_status_name: "empty",
        sensor_recalibration: 0
      }},

      # Start 1 Frame
      {:parse_hex, "04001E0E7CF2D9F91E0DDF", %{}, %{
        battery_state: 0,
        battery_state_name: "good",
        config_up: "ack",
        firmware_version: 30,
        frame_counter: 0,
        frame_type: 4,
        frame_type_name: "start1",
        parking_slot_changed: 0,
        parking_slot_status: 0,
        parking_slot_status_name: "empty",
        sensor_recalibration: 0
      }},

      # Start 2 Frame
      {:parse_hex, "050106160801010100014B", %{}, %{
        battery_state: 0,
        battery_state_name: "good",
        config_up: "ack",
        frame_counter: 1,
        frame_type: 5,
        frame_type_name: "start2",
        parking_slot_changed: 0,
        parking_slot_status: 0,
        parking_slot_status_name: "empty",
        sensor_recalibration: 0
      }},

      # Service / Downlink / RSSI Frame
      {:parse_hex, "060A00001F00C60561ED91", %{}, %{
        battery_state: 0,
        battery_state_name: "good",
        config_up: "ack",
        frame_counter: 10,
        frame_type: 6,
        frame_type_name: "service",
        parking_slot_changed: 0,
        parking_slot_status: 0,
        parking_slot_status_name: "empty",
        sensor_recalibration: 0
      }},
      {:parse_hex, "070A00001F00C60561ED91", %{}, %{
        battery_state: 0,
        battery_state_name: "good",
        config_up: "ack",
        frame_counter: 10,
        frame_type: 7,
        frame_type_name: "downlink",
        parking_slot_changed: 0,
        parking_slot_status: 0,
        parking_slot_status_name: "empty",
        sensor_recalibration: 0
      }},
      {:parse_hex, "07AD0013001D00000000C8", %{}, %{
        battery_state: 0,
        battery_state_name: "good",
        config_up: "ack",
        frame_counter: 173,
        frame_type: 7,
        frame_type_name: "downlink",
        parking_slot_changed: 0,
        parking_slot_status: 0,
        parking_slot_status_name: "empty",
        sensor_recalibration: 0
      }},
      {:parse_hex, "080A00001F00C60561ED91", %{}, %{
        battery_state: 0,
        battery_state_name: "good",
        config_up: "ack",
        frame_counter: 10,
        frame_type: 8,
        frame_type_name: "rssi",
        parking_slot_changed: 0,
        parking_slot_status: 0,
        parking_slot_status_name: "empty",
        sensor_recalibration: 0
      }},

      # Invalid frame_type
      {:parse_hex, "090A00001F00C60561ED91", %{}, %{
        battery_state: 0,
        battery_state_name: "good",
        config_up: "ack",
        frame_counter: 10,
        frame_type: 9,
        frame_type_name: "unknown",
        parking_slot_changed: 0,
        parking_slot_status: 0,
        parking_slot_status_name: "empty",
        sensor_recalibration: 0
      }},
    ]
  end
end