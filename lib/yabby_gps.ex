defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # Parser for yabby LoRaWAN GPS device that will provide GPS data.
  #
  # Changelog:
  #   2019-05-13 [as]: Initial implementation according to "Yabby_LoRaWAN_Integration_1.3.pdf", provided by ZENNER Connect
  #

  def parse(<<latitude::signed-little-32, longitude::signed-little-32, _rfu::5, down::1, failed::1, in_trip::1, speed::little-5, heading::little-3, battery::little-8>>, %{meta: %{frame_port: 1}}) do

    gpslatitude = latitude/10000000
    gpslongitude = longitude/10000000

    # no movement for configured period
    man_down = case down do
      0 -> "false"
      1 -> "true"
      _ -> "unknown"
    end

    # check if last check failed
    last_fix = case failed do
      0 -> "did not fail"
      1 -> "failed"
      _ -> "unknown"
    end

    #check if device is in trip
    trip = case in_trip do
      0 -> "Out of trip"
      1 -> "In-trip"
      _ -> "unknown"
    end

    {%{
      type: :record,
      man_down: man_down,
      last_fix: last_fix,
      trip: trip,
      heading: heading*45,
      speed: speed*5,
      battery: battery*25,
    },
    [
      location: {gpslongitude, gpslatitude}, # GPS coordinates as GEO Point for showing in map
    ]}
  end

  def parse(<<down_accept::1, seq_no::7, v1, v2>>, %{meta: %{frame_port: 2}}) do
    downlink = case down_accept do
      0 -> "rejected"
      1 -> "failed"
      _ -> "unknown"
    end

    %{
      type: :ack,
      downlink: downlink,
      seq_no: seq_no,
      version: "#{v1}.#{v2}",
    }
  end

  def parse(<<msg::88>>, %{meta: %{frame_port: 3}}) do
    <<uptime::9, wakeups::7, avg_gps_fresh::8, avg_gps_fail::9, avg_gps_fix::9, gps_fails::8, gps_success::10, trip_count::13, tx_count::11, initial_bat::4   >> = <<msg::little-88>>
    %{
      type: :statistics,
      initial_bat: initial_bat*0.1+4,
      tx_count: tx_count*32,
      trip_count: trip_count*32,
      gps_success: gps_success*32,
      gps_fails: gps_fails*32,
      avg_gps_fix: avg_gps_fix,
      avg_gps_fail: avg_gps_fail,
      avg_gps_fresh: avg_gps_fresh,
      wakeups: wakeups,
      uptime: uptime,
    }
  end

  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end


  # Define fields with human readable name and a SI unit if available.
  def fields() do
    [
      %{
        field: "type",
        display: "Typ",
      },
      %{
        field: "man_down",
        display: "Man down",
      },
      %{
        field: "last_fix",
        display: "Last fix",
      },
      %{
        field: "trip",
        display: "Trip",
      },
      %{
        field: "heading",
        display: "Heading",
        unit: "°",
      },
      %{
        field: "speed",
        display: "Speed",
        unit: "km/h",
      },
      %{
        field: "battery",
        display: "Battery",
        unit: "mV",
      },
      %{
        field: "seq_no",
        display: "Sequence number",
      },
      %{
        field: "downlink",
        display: "Downlink",
      },
      %{
        field: "version",
        display: "Firmware version",
      },
      %{
        field: "initial_bat",
        display: "Initial battery",
        unit: "V",
      },
      %{
        field: "tx_count",
        display: "Transmissions",
      },
      %{
        field: "trip_count",
        display: "Trips",
      },
      %{
        field: "gps_success",
        display: "GPS fixes",
      },
      %{
        field: "gps_fails",
        display: "GPS failures",
      },
      %{
        field: "avg_gps_fix",
        display: "Time per GPS fix",
        unit: "s"
      },
      %{
        field: "avg_gps_fail",
        display: "Time per failed GPS fix attempt",
        unit: "s"
      },
      %{
        field: "avg_gps_fresh",
        display: "Time spent refreshening GPS location",
        unit: "s"
      },
      %{
        field: "wakeups",
        display: "Wakeups per trip",
      },
      %{
        field: "uptime",
        display: "Uptime",
        unit: "Weeks"
      },
    ]
  end

  def tests() do
    [
      # Test format:
      # {:parse_hex, received_payload_as_hex, meta_map, expected_result},

      {:parse_hex, "53AB783C0421F98E04CAB3", %{meta: %{frame_port: 1}}, {%{type: :record, man_down: "true", last_fix: "did not fail", trip: "Out of trip", heading: 90, speed: 125, battery: 4475},[location: {-189.6275708, 101.4541139}]}},

      {:parse_hex, "D30102", %{meta: %{frame_port: 2}}, %{type: :ack, downlink: "accepted", seq_no: 83, version: "1.2"}},

      {:parse_hex, "8BF3DC7B9438984278B85E", %{meta: %{frame_port: 2}}, %{type: :statistics, initial_bat: 5.1, tx_count: 59136, trip_count: 194336, gps_success: 10464, gps_fails: 7232, avg_gps_fix: 96, avg_gps_fail: 133, avg_gps_fresh: 120, wakeups: 56, uptime: 189}}
    ]
  end
end
