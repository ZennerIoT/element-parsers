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
  #

  def parse(<<parking_slot_status::1, battery_state::1, _reserved::2, frame_type::4, frame_counter::8, rest::binary>>, _meta) do

    data = %{
      parking_slot_changed: 0,
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
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  # Info Frame
  def parse_frame_rest(0, <<temperature::8-signed, x_axis::16, y_axis::16, z_axis::16, _reserved::8, battery_level::8>>, data) do
    Map.merge(data, %{
      parking_slot_changed: 1,
      frame_type_name: "info",
      temperature: temperature,
      x_axis: x_axis,
      y_axis: y_axis,
      z_axis: z_axis,
      battery_level: ((battery_level*4) + 2800),  # Battery voltage in millivolts
    })
  end
  # Keep Alive Frame
  def parse_frame_rest(1, <<hours::8, minutes::8, temperature::8-signed, x_axis::16, y_axis::16, z_axis::16>>, data) do
    Map.merge(data, %{
      frame_type_name: "keep_alive",
      hours: hours,
      minutes: minutes,
      temperature: temperature,
      x_axis: x_axis,
      y_axis: y_axis,
      z_axis: z_axis,
    })
  end
  # Daily update Frame
  def parse_frame_rest(2, <<_reserved1::48, resets::8, config_id::8, _reserved2::8>>, data) do
    Map.merge(data, %{
      frame_type_name: "daily_update",
      resets: resets,         # Number of resets generated in the last 24 hours
      config_id: config_id,   # Value of the configuration version loaded into the node
    })
  end
  # Error Frame
  def parse_frame_rest(3, <<_reserved::2, error_sigfox::1, error_lorawan::1, error_rtc::1, error_xaxis::1, error_yaxis::1, error_zaxis::1, temperature::8-signed, x_axis::16, y_axis::16, z_axis::16, battery_level::8>>, data) do
    Map.merge(data, %{
      frame_type_name: "error",
      error_sigfox: error_sigfox,
      error_lorawan: error_lorawan,
      error_rtc: error_rtc,
      error_xaxis: error_xaxis,
      error_yaxis: error_yaxis,
      error_zaxis: error_zaxis,
      temperature: temperature,
      x_axis: x_axis,
      y_axis: y_axis,
      z_axis: z_axis,
      battery_level: ((battery_level*4) + 2800),  # Battery voltage in millivolts
    })
  end
  # Start 1 Frame
  def parse_frame_rest(4, <<temperature::8-signed, x_axis::16, y_axis::16, z_axis::16, battery_voltage::16>>, data) do
    Map.merge(data, %{
      frame_type_name: "start1",
      temperature: temperature,
      x_axis: x_axis,
      y_axis: y_axis,
      z_axis: z_axis,
      battery_level: battery_voltage,  # Battery voltage in millivolts
    })
  end
  # Start 2 Frame
  def parse_frame_rest(5, <<firmware_version::8, nm_start::8, nm_period::8, nm_sleep_time::8, nm_keep_alive::8, radio_mode::8, sleep_time::8, keep_alive::8, threshold::8>>, data) do
    Map.merge(data, %{
      frame_type_name: "start2",
      firmware_version: firmware_version,
      nm_start: nm_start,
      nm_period: nm_period,
      nm_sleep_time: nm_sleep_time,
      nm_keep_alive: nm_keep_alive,
      radio_mode: radio_mode,
      sleep_time: sleep_time,
      keep_alive: keep_alive,
      threshold: threshold,
    })
  end
  # Service / Downlink / RSSI frame
  def parse_frame_rest(frame_type, <<hours::8, minutes::8, temperature::8-signed, x_axis::16, y_axis::16, z_axis::16>>, data) when frame_type in 6..8 do
    Map.merge(data, %{
      frame_type_name: %{6 => "service", 7 => "downlink", 8 => "rssi"}[frame_type],
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

      # Info Frame
      {:parse_hex, "80041E01AD109393EE00C7", %{}, %{
        battery_level: 3596,
        battery_state: 0,
        battery_state_name: "good",
        frame_counter: 4,
        frame_type: 0,
        frame_type_name: "info",
        parking_slot_changed: 1,
        parking_slot_status: 1,
        parking_slot_status_name: "occupied",
        temperature: 30,
        x_axis: 429,
        y_axis: 4243,
        z_axis: 37870
      }},

      # Keep Alive Frame
      {:parse_hex, "8114160011F35A1095F3B5", %{}, %{
        battery_state: 0,
        battery_state_name: "good",
        frame_counter: 20,
        frame_type: 1,
        frame_type_name: "keep_alive",
        hours: 22,
        minutes: 0,
        parking_slot_changed: 0,
        parking_slot_status: 1,
        parking_slot_status_name: "occupied",
        temperature: 17,
        x_axis: 62298,
        y_axis: 4245,
        z_axis: 62389
      }},

      # Daily update Frame
      {:parse_hex, "829F665700000D9F00FF00", %{}, %{
        battery_state: 0,
        battery_state_name: "good",
        config_id: 255,
        frame_counter: 159,
        frame_type: 2,
        frame_type_name: "daily_update",
        parking_slot_changed: 0,
        parking_slot_status: 1,
        parking_slot_status_name: "occupied",
        resets: 0
      }},

      # Error Frame (From v2, in v3 its reserved)
      {:parse_hex, "0303071E01921085853AC6", %{}, %{
        battery_level: 3592,
        battery_state: 0,
        battery_state_name: "good",
        error_lorawan: 0,
        error_rtc: 0,
        error_sigfox: 0,
        error_xaxis: 1,
        error_yaxis: 1,
        error_zaxis: 1,
        frame_counter: 3,
        frame_type: 3,
        frame_type_name: "error",
        parking_slot_changed: 0,
        parking_slot_status: 0,
        parking_slot_status_name: "empty",
        temperature: 30,
        x_axis: 402,
        y_axis: 4229,
        z_axis: 34106
      }},

      # Start 1 Frame
      {:parse_hex, "04001E0E7CF2D9F91E0DDF", %{}, %{
        battery_level: 3551,
        battery_state: 0,
        battery_state_name: "good",
        frame_counter: 0,
        frame_type: 4,
        frame_type_name: "start1",
        parking_slot_changed: 0,
        parking_slot_status: 0,
        parking_slot_status_name: "empty",
        temperature: 30,
        x_axis: 3708,
        y_axis: 62169,
        z_axis: 63774
      }},

      # Start 2 Frame
      {:parse_hex, "050106160801010100014B", %{}, %{
        battery_state: 0,
        battery_state_name: "good",
        firmware_version: 6,
        frame_counter: 1,
        frame_type: 5,
        frame_type_name: "start2",
        keep_alive: 1,
        nm_keep_alive: 1,
        nm_period: 8,
        nm_sleep_time: 1,
        nm_start: 22,
        parking_slot_changed: 0,
        parking_slot_status: 0,
        parking_slot_status_name: "empty",
        radio_mode: 1,
        sleep_time: 0,
        threshold: 75
      }},

      # Service / Downlink / RSSI Frame
      {:parse_hex, "060A00001F00C60561ED91", %{}, %{
        battery_state: 0,
        battery_state_name: "good",
        frame_counter: 10,
        frame_type: 6,
        frame_type_name: "service",
        hours: 0,
        minutes: 0,
        parking_slot_changed: 0,
        parking_slot_status: 0,
        parking_slot_status_name: "empty",
        temperature: 31,
        x_axis: 198,
        y_axis: 1377,
        z_axis: 60817
      }},
      {:parse_hex, "070A00001F00C60561ED91", %{}, %{
        battery_state: 0,
        battery_state_name: "good",
        frame_counter: 10,
        frame_type: 7,
        frame_type_name: "downlink",
        hours: 0,
        minutes: 0,
        parking_slot_changed: 0,
        parking_slot_status: 0,
        parking_slot_status_name: "empty",
        temperature: 31,
        x_axis: 198,
        y_axis: 1377,
        z_axis: 60817
      }},
      {:parse_hex, "080A00001F00C60561ED91", %{}, %{
        battery_state: 0,
        battery_state_name: "good",
        frame_counter: 10,
        frame_type: 8,
        frame_type_name: "rssi",
        hours: 0,
        minutes: 0,
        parking_slot_changed: 0,
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
        parking_slot_changed: 0,
        parking_slot_status: 0,
        parking_slot_status_name: "empty"
      }},
    ]
  end
end