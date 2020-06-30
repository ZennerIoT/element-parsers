defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for abeeway Industrial Tracker
  #
  # Changelog
  #   2018-12-04: [jb] Initial Parser for Firmware 1.7 according to "Abeeway Industrial Tracker_Reference_Guide_FW1.7.pdf"
  #

  # Each message is composed by:
  # - A common header
  # - A specific data part
  # Exception is the Frame pending message

  def parse(<<0::8, ack_token::8>>, _meta) do
    # Frame pending message
    # When additional messages are available on a gateway,
    # this uplink message is sent to trigger the gateway sending (if no other messages are pending).
    %{
      message_type: :frame_pending,
      ack_token: ack_token
    }
  end

  def parse(
        <<
          type,
          status::1-binary,
          battery_encoded,
          temperature_encoded,
          ack_opt::1-binary,
          data::binary
        >>,
        _meta
      ) do
    <<
      operating_mode::3,
      is_sos::1,
      is_tracking::1,
      is_moving::1,
      periodic_position::1,
      position_on_demand::1
    >> = status

    <<ack_token::4, optional::4>> = ack_opt

    battery = mt_value_decode(battery_encoded, 2.8, 4.2, 8, 2)
    temperature = mt_value_decode(temperature_encoded, -44, 85, 8, 0)

    # Handling specific data part
    parsed_data =
      case type do
        # Frame pending
        0x00 ->
          %{}

        # Not handled here.
        # Position message
        0x03 ->
          parse_position(data, optional)

        # Energy status message
        0x04 ->
          parse_energy_status(data)

        # Heartbeat message
        0x05 ->
          parse_heartbeat(data)

        # Activity Status message / Configuration message
        0x07 ->
          parse_activity_or_configuration(data)

        type ->
          Logger.info("Unknown message type: #{inspect(type)}")
          %{}
      end

    reading =
      Map.merge(
        %{
          operating_mode: operating_mode(operating_mode),
          sos: is_sos,
          moving: is_moving,
          periodic_position: periodic_position,
          position_on_demand: position_on_demand,
          tracker_state: if(is_tracking, do: :tracking, else: :idle),
          battery: battery,
          temperature: temperature,
          ack_token: ack_token
        },
        parsed_data
      )

    case reading do
      %{location_lat: lat, location_lon: lon} ->
        {reading, [location: {lon, lat}]}

      _ ->
        reading
    end
  end

  # Catchall for reparsing
  def parse(payload, meta) do
    Logger.info(
      "Unknown payload #{inspect(payload)} on frame-port: #{
        inspect(get(meta, [:meta, :frame_port]))
      }"
    )

    []
  end

  def parse_heartbeat(<<cause::8, fw_version::24>>),
      do: %{message_type: :heartbeat, reset_cause: cause, firmware_version: fw_version}

  def parse_heartbeat(<<cause::8>>), do: %{message_type: :heartbeat, reset_cause: cause}

  def parse_heartbeat(payload) do
    Logger.info("Unknown heartbeat payload: #{inspect(payload)}")
    %{}
  end

  def parse_position(data, position_type_id) do
    position_type = position_type(position_type_id)

    reading = %{
      message_type: :position,
      position_type: position_type
    }

    case {position_type, data} do
      {:gps_fix, <<age_enc::8, lat_enc::24, lon_enc::24, ehpe::8, encrypted::binary>>} ->
        Map.merge(
          reading,
          %{
            location_age: mt_value_decode(age_enc, 0, 2040, 8, 0),
            location_lat: byte_to_gps(lat_enc),
            location_lon: byte_to_gps(lon_enc),
            # Estimated Horizontal Position Error, expressed in meters
            location_ehpe: mt_value_decode(ehpe, 0, 1000, 8, 0),
            location_encrypted: Base.encode16(encrypted)
          }
        )

      {:gps_timeout, _ignored} ->
        reading

      {:wifi_timeout, _ignore} ->
        reading

      {:wifi_failure, _ignore} ->
        reading

      {:wifi_bssid, _ignore} ->
        reading

      _ ->
        Logger.info("Unknown position type #{inspect(position_type)} or data #{inspect(data)}.")
        reading
    end
  end

  def parse_heartbeat(payload, _) do
    Logger.info("Unknown position payload: #{inspect(payload)}")
    %{}
  end

  def parse_energy_status(<<gps_on::32, gps_standby::32, wifi_scan::32>>) do
    %{
      message_type: :energy_status,
      # Seconds
      gps_on: gps_on,
      # Seconds
      gps_standby: gps_standby,
      # Times
      wifi_scan: wifi_scan
    }
  end

  def parse_energy_status(payload) do
    Logger.info("Unknown energy_status payload: #{inspect(payload)}")
    %{}
  end

  def parse_activity_or_configuration(<<1, activity::32>>) do
    %{
      message_type: :activity,
      activity_counter: activity
    }
  end

  def parse_activity_or_configuration(<<
    2,
    p0_id::8,
    p0_val::32,
    p1_id::8,
    p1_val::32,
    p2_id::8,
    p2_val::32,
    p3_id::8,
    p3_val::32,
    p4_id::8,
    p4_val::32
  >>) do
    %{
      message_type: :configuration,
      parame0_id: p0_id,
      parame0_value: p0_val,
      parame1_id: p1_id,
      parame1_value: p1_val,
      parame2_id: p2_id,
      parame2_value: p2_val,
      parame3_id: p3_id,
      parame3_value: p3_val,
      parame4_id: p4_id,
      parame4_value: p4_val
    }
  end

  def parse_activity_or_configuration(payload) do
    Logger.info("Unknown activity_or_configuration payload: #{inspect(payload)}")
    %{}
  end

  # --- Internals ---

  def position_type(0), do: :gps_fix
  def position_type(1), do: :gps_timeout
  def position_type(2), do: :no_more_used
  def position_type(3), do: :wifi_timeout
  def position_type(4), do: :wifi_failure
  def position_type(5), do: :lp_gps
  def position_type(6), do: :lp_gps
  def position_type(7), do: :ble_beacon_scan
  def position_type(8), do: :ble_beacon_failure
  def position_type(9), do: :wifi_bssid
  def position_type(_), do: :unknown

  def operating_mode(0), do: :standby
  def operating_mode(1), do: :motion_tracking
  def operating_mode(2), do: :permanent_tracking
  def operating_mode(3), do: :motion_startend_tracking
  def operating_mode(4), do: :activity_tracking
  def operating_mode(5), do: :unknown

  def byte_to_gps(coord) do
    use Bitwise
    coord = coord <<< 8

    cond do
      coord > 0x7FFFFFFF -> coord - 0x10000000
      true -> coord
    end
    |> Kernel./(10_000_000)
  end

  def _step_size(lo, hi, nbits, nresv) do
    use Bitwise
    1.0 / (((1 <<< nbits) - 1 - nresv) / (hi - lo))
  end

  def mt_value_decode(value, lo, hi, nbits, nresv) do
    (value - nresv / 2) * _step_size(lo, hi, nbits, nresv) + lo
  end

  def fields() do
    [
      %{
        "field" => "battery",
        "unit" => "V",
        "display" => "Battery"
      },
      %{
        "field" => "location_age",
        "unit" => "s",
        "display" => "LocationAge"
      },
      %{
        "field" => "location_ehpe",
        "unit" => "m",
        "display" => "LocationError"
      },
      %{
        "field" => "message_type",
        "display" => "MessageType"
      },
      %{
        "field" => "tracker_state",
        "display" => "TrackerState"
      },
      %{
        "field" => "operating_mode",
        "display" => "OperationMode"
      },
      %{
        "field" => "temperature",
        "unit" => "°C",
        "display" => "Temperature"
      }
    ]
  end

  def tests() do
    [
      # Frame pending
      {
        :parse_hex,
        "0042",
        %{
          meta: %{
            frame_port: 1
          }
        },
        %{ack_token: 66, message_type: :frame_pending}
      },

      # Position
      {
        :parse_hex,
        "03480089100219FFA80433E7050083AE",
        %{
          meta: %{
            frame_port: 1
          }
        },
        {%{
          ack_token: 1,
          battery: 2.794466403162055,
          location_age: 16.0,
          location_ehpe: 19.6078431372549,
          location_encrypted: "0083AE",
          location_lat: 43.6185088,
          location_lon: 7.0510336,
          message_type: :position,
          moving: 0,
          operating_mode: :permanent_tracking,
          periodic_position: 0,
          position_on_demand: 0,
          position_type: :gps_fix,
          sos: 0,
          temperature: 25.30588235294117,
          tracker_state: :tracking
        }, [location: {7.0510336, 43.6185088}]}
      },

      # Energy Status
      {
        :parse_hex,
        "04609E7910000123456712345671234567",
        %{
          meta: %{
            frame_port: 1
          }
        },
        %{
          ack_token: 1,
          battery: 3.6687747035573124,
          gps_on: 74565,
          gps_standby: 1_729_246_294,
          message_type: :energy_status,
          moving: 0,
          operating_mode: :motion_startend_tracking,
          periodic_position: 0,
          position_on_demand: 0,
          sos: 0,
          temperature: 17.211764705882352,
          tracker_state: :tracking,
          wifi_scan: 1_898_136_935
        }
      },

      # Heartbeat
      {
        :parse_hex,
        "05609E791001",
        %{
          meta: %{
            frame_port: 1
          }
        },
        %{
          ack_token: 1,
          battery: 3.6687747035573124,
          message_type: :heartbeat,
          moving: 0,
          operating_mode: :motion_startend_tracking,
          periodic_position: 0,
          position_on_demand: 0,
          reset_cause: 1,
          sos: 0,
          temperature: 17.211764705882352,
          tracker_state: :tracking
        }
      },

      # Activity Status
      {
        :parse_hex,
        "07609E79000199887766",
        %{
          meta: %{
            frame_port: 1
          }
        },
        %{
          ack_token: 0,
          activity_counter: 2_575_857_510,
          battery: 3.6687747035573124,
          message_type: :activity,
          moving: 0,
          operating_mode: :motion_startend_tracking,
          periodic_position: 0,
          position_on_demand: 0,
          sos: 0,
          temperature: 17.211764705882352,
          tracker_state: :tracking
        }
      },

      # Configuration Message
      {
        :parse_hex,
        "07609E79000299887766559988776656998877665799887766589988776659",
        %{
          meta: %{
            frame_port: 1
          }
        },
        %{
          ack_token: 0,
          battery: 3.6687747035573124,
          message_type: :configuration,
          moving: 0,
          operating_mode: :motion_startend_tracking,
          parame0_id: 153,
          parame0_value: 2_289_526_357,
          parame1_id: 153,
          parame1_value: 2_289_526_358,
          parame2_id: 153,
          parame2_value: 2_289_526_359,
          parame3_id: 153,
          parame3_value: 2_289_526_360,
          parame4_id: 153,
          parame4_value: 2_289_526_361,
          periodic_position: 0,
          position_on_demand: 0,
          sos: 0,
          temperature: 17.211764705882352,
          tracker_state: :tracking
        }
      },

      # GPS Fix with longer encrypted-data
      {
        :parse_hex,
        "0348848820001D364804F9410A",
        %{
          meta: %{
            frame_port: 1
          }
        },
        {%{
          ack_token: 2,
          battery: 3.524901185770751,
          location_age: 0.0,
          location_ehpe: 39.2156862745098,
          location_encrypted: "",
          location_lat: 49.009664,
          location_lon: 8.3443968,
          message_type: :position,
          moving: 0,
          operating_mode: :permanent_tracking,
          periodic_position: 0,
          position_on_demand: 0,
          position_type: :gps_fix,
          sos: 0,
          temperature: 24.799999999999997,
          tracker_state: :tracking
        }, [location: {8.3443968, 49.009664}]}
      },
    ]
  end
end
