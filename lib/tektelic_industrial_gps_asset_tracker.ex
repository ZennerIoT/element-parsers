defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # Parser for Tektelic Industrial GPS Asset Tracker.
  #
  # Implemented:
  #   Real-time sensor data on port 15
  # Not implemented:
  #   GNSS logged data response on port 20
  #   BLE  logged data response on port 25
  #   Configuration and Control command responses on port 100
  #
  # Changelog:
  #   2020-06-11 [jb]: Initial implementation according to "T0006279_TRM_ver0.6.r1.pdf"
  #   2020-06-16 [jb]: Fixed call to add_location. Always creating locations ignoring gps_valid flag.
  #

  # Real-time sensor data from the MCU, GNSS receiver, and accelerometer, port 10
  def parse(payload, %{meta: %{frame_port: 10}}) do
    reading = payload
      |> parse_frames([type: :realtime_sensor_data])
      |> Enum.into(%{})
    {reading, []}
    |> add_location
    # TODO: add measured_at from %{utc_timestamp} ?
  end

  # Report GNSS logged (historical) time and position, port 15
  def parse(_payload, %{meta: %{frame_port: 15}}) do
    %{type: :gnss_logged, todo: :not_implemented}
  end

  # Report discovered BLE devices, port 25
  def parse(_payload, %{meta: %{frame_port: 25}}) do
    %{type: :ble_logged, todo: :not_implemented}
  end

  # Response to Configuration and Control Commands, port 100
  def parse(_payload, %{meta: %{frame_port: 100}}) do
    %{type: :control_commands, todo: :not_implemented}
  end

  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  defp add_location({%{gps_lat: gps_lat, gps_lon: gps_lon} = reading, opts}) do
    # Always adding location, because the gps_valid flag will be in the NEXT message, which is not intelligent.
    {reading, [{:location, {gps_lon, gps_lat}} |opts]}
  end
  defp add_location(other), do: other


  def parse_frames(<<0x01, 0xBA, battery, rest::binary>>, frames) do
    parse_frames(rest, [{:battery_1, 2.5+(battery*0.01)}|frames])
  end
  def parse_frames(<<0x02, 0xBA, battery, rest::binary>>, frames) do
    parse_frames(rest, [{:battery_2, 2.5+(battery*0.01)}|frames])
  end

  def parse_frames(<<0x00, 0x85, timestamp::binary-7, rest::binary>>, frames) do
    <<year::16, month::8, day::8, hour::8, minute::8, second::8>> = timestamp

    iso8601 = {{year, month, day}, {hour, minute, second}}
      |> NaiveDateTime.from_erl!()
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.to_iso8601

    parse_frames(rest, [{:utc_timestamp, iso8601}|frames])
  end

  def parse_frames(<<0x00, 0x88, lat::24-signed, lon::32-signed, alt::16-signed, rest::binary>>, frames) do
    parse_frames(rest, [{:gps_lat, lat*0.0000125}, {:gps_lon, lon*0.0000001}, {:gps_alt, alt*0.5}|frames])
  end

  def parse_frames(<<0x00, 0x04, fsm_state, rest::binary>>, frames) do
    fsm_state_name = case fsm_state do
      0 -> :gnss_disabled
      1 -> :gnss_search
      2 -> :stillness
      3 -> :mobility
      state -> "unknown_#{state}"
    end
    parse_frames(rest, [{:fsm_state, fsm_state}, {:fsm_state_name, fsm_state_name}|frames])
  end

  def parse_frames(<<0x00, 0x06, bitmap::binary-1, rest::binary>>, frames) do
    <<_::6, utc_valid::1, gps_valid::1>> = bitmap
    parse_frames(rest, [{:utc_valid, utc_valid}, {:gps_valid, gps_valid}|frames])
  end

  def parse_frames(<<0x00, 0x00, alarm, rest::binary>>, frames) do
    parse_frames(rest, [{:acceleration_alarm, digital(alarm)}|frames])
  end

  def parse_frames(<<0x00, 0x71, x::16, y::16, z::16, rest::binary>>, frames) do
    parse_frames(rest, [{:acceleration_x, x/1000}, {:acceleration_y, y/1000}, {:acceleration_z, z/1000}|frames])
  end

  def parse_frames(<<0x00, 0x67, temperature::16-signed, rest::binary>>, frames) do
    temperature_c = temperature/10 # Conversion from 0.1°C to °C
    parse_frames(rest, [{:temperature, temperature_c}|frames])
  end

  def parse_frames(<<>>, frames), do: Enum.reverse(frames)
  def parse_frames(payload, frames) do
    Logger.warn("Tektelic.Parser: Unknown frame found: #{inspect payload}")
    frames
  end

  def digital(0x00), do: 0
  def digital(_), do: 1

  # Define fields with human readable name and a SI unit if available.
  def fields() do
    [
      %{
        field: "temperature",
        display: "Temperature",
        unit: "°C"
      },

      %{
        field: "battery_1",
        display: "Battery 1",
        unit: "V"
      },

      %{
        field: "acceleration_x",
        display: "Acc. X",
        unit: "mg"
      },
      %{
        field: "acceleration_y",
        display: "Acc. Y",
        unit: "mg"
      },
      %{
        field: "acceleration_z",
        display: "Acc. Z",
        unit: "mg"
      },

      %{
        field: "gps_lat",
        display: "GPS Lat",
        unit: "°"
      },
      %{
        field: "gps_lon",
        display: "GPS Lon",
        unit: "°"
      },
      %{
        field: "gps_alt",
        display: "GPS Alt",
        unit: "m"
      },

      %{
        field: "acceleration_alarm",
        display: "Acceleration Alarm"
      },

      %{
        field: "utc_valid",
        display: "UTC Valid"
      },

      %{
        field: "gps_valid",
        display: "GPS Valid"
      },

      %{
        field: "fsm_state_name",
        display: "Status"
      },

      %{
        field: "utc_timestamp",
        display: "UTC Zeit"
      },

      %{
        field: "type",
        display: "Type"
      },
    ]
  end

  def tests() do
    [
      # Timestamp
      {
        :parse_hex,
        "00 85 07E4 06 0B 01 02 03",
        %{meta: %{frame_port: 10}},
        {%{type: :realtime_sensor_data, utc_timestamp: "2020-06-11T01:02:03Z"}, []}
      },

      # FSM state and fix status
      {
        :parse_hex,
        "00 04 01   00 06 03",
        %{meta: %{frame_port: 10}},
        {%{
          fsm_state: 1,
          fsm_state_name: :gnss_search,
          gps_valid: 1,
          type: :realtime_sensor_data,
          utc_valid: 1
        }, []}
      },

      # Acceleartion alarm
      {
        :parse_hex,
        "00 00 00",
        %{meta: %{frame_port: 10}},
        {%{acceleration_alarm: 0, type: :realtime_sensor_data}, []}
      },

      # Examples from docs
      {
        :parse_hex,
        "00 67 00 EC",
        %{meta: %{frame_port: 10}},
        {%{temperature: 23.6, type: :realtime_sensor_data}, []}
      },

      {
        :parse_hex,
        "00 67 FF FF 01 BA 63",
        %{meta: %{frame_port: 10}},
        {%{battery_1: 3.49, temperature: -0.1, type: :realtime_sensor_data}, []}
      },

      {
        :parse_hex,
        "00 06 00 00 71 02 44 00 46 03 3E",
        %{meta: %{frame_port: 10}},
        {%{
          acceleration_x: 0.58,
          acceleration_y: 0.07,
          acceleration_z: 0.83,
          gps_valid: 0,
          type: :realtime_sensor_data,
          utc_valid: 0
        }, []}
      },

      {
        :parse_hex,
        "00 88 3E 50 B0 BC 02 2D 60 08 2A",
        %{meta: %{frame_port: 10}},
        {%{
          gps_alt: 1045.0,
          gps_lat: 51.0486,
          gps_lon: -114.07079999999999,
          type: :realtime_sensor_data
        }, [location: {-114.07079999999999, 51.0486}]}
      },

      {
        :parse_hex,
        "00 88 3E 50 B0 BC 02 2D 60 08 2A  00 06 03",
        %{meta: %{frame_port: 10}},
        {%{
          gps_alt: 1045.0,
          gps_lat: 51.0486,
          gps_lon: -114.07079999999999,
          gps_valid: 1,
          type: :realtime_sensor_data,
          utc_valid: 1
        }, [location: {-114.07079999999999, 51.0486}]}
      },
    ]
  end
end
