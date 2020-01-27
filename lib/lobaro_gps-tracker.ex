defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Lobaro LoRaWAN GPS Tracker v5.0
  # According to documentation provided by Lobaro
  # Link: https://www.lobaro.com/portfolio/lorawan-gps-tracker/
  # Documentation: https://www.lobaro.com/download/7315/
  #
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #   2020-01-10 [tr]: Added Payload Version 5.0
  #

  # parsing packet if GPS fix available
  def parse(<<type::big-8, temp::big-16, vbat::big-16, lat_deg::big-8, lat_min::big-8, lat_10000::big-16, long_deg::big-8, long_min::big-8, long_10000::big-16, 0x01, sat_cnt::8>>, _meta) do

    # calculate the GPS coordinates
    gpslatitude = lat_deg + (lat_min/60) + (lat_10000/600000)
    gpslongitude = long_deg + (long_min/60) + (long_10000/600000)

    mode = case type do
      0 -> "alive"
      1 -> "active"
      _ -> "unknown"
    end

    # return value map
    {%{
      mode: mode,  # active/alive
      temp: temp/10,   # Temperature in °C
      vbat: vbat/1000, # Battery level in V
      sat_cnt: sat_cnt, # received Sattelites
      position: "GPS fix"
      },
    [
      location: {gpslongitude, gpslatitude}, # GPS coordinates as GEO Point for showing in map
    ]}
  end

  # parsing packet if GPS fix available (V 5.0)
  def parse(<<temp::big-16, vbat::big-16, lat_deg::big-32, long_deg::big-32, alt_cm::big-24, status::binary-1, sat_cnt::8>>, _meta) do
    <<last_measurement_isvalid::1, op_mode::1, _::6>> = status
    # calculate the GPS coordinates
    gpslatitude = lat_deg/100000
    gpslongitude = long_deg/100000
    alt_m = alt_cm/100

    last_measurement_isvalid = case last_measurement_isvalid do
      0 -> "false"
      1 -> "true"
      _ -> "unknown"
    end

    op_mode = case op_mode do
      0 -> "alive"
      1 -> "active"
      _ -> "unknown"
    end

    # return value map
    {%{
      alt_m: alt_m,
      last_measurement_isvalid: last_measurement_isvalid,
      op_mode: op_mode,  # active/alive
      temp: temp/10,   # Temperature in °C
      vbat: vbat/1000, # Battery level in V
      sat_cnt: sat_cnt, # received Sattelites
      position: "GPS fix"
      },
    [
      location: {gpslongitude, gpslatitude}, # GPS coordinates as GEO Point for showing in map
    ]}
  end


  #parsing packet if no GPS fix
  def parse(<<type::big-8, temp::big-16, vbat::big-16, _lat_deg::big-8, _lat_min::big-8, _lat_10000::big-16, _long_deg::big-8, _long_min::big-8, _long_10000::big-16, 0x00, sat_cnt::8>>, _meta) do

    mode = case type do
      0 -> "Scheduled"
      1 -> "Unscheduled"
      _ -> "unknown"
    end
    # return value map
    %{
      mode: mode,  # active/alive
      temp: temp/10,   # Temperature in °C
      vbat: vbat/1000, # Battery level in V
      sat_cnt: sat_cnt, # received Sattelites
      position: "no GPS fix"
      }
  end

  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  def tests() do
    [
      {:parse_hex, "00940C3E00528187000F332600030C0304", %{},{%{
        alt_m: 7.8,
        last_measurement_isvalid: "false",
        op_mode: "alive",
        position: "GPS fix",
        sat_cnt: 4,
        temp: 14.8,
        vbat: 3.134
        }, [location: {9.96134, 54.07111}]}
      },

      {:parse_hex, "00940C3C00528189000F3322000C890304", %{},{%{
        alt_m: 32.09,
        last_measurement_isvalid: "false",
        op_mode: "alive",
        position: "GPS fix",
        sat_cnt: 4,
        temp: 14.8,
        vbat: 3.132
        }, [location: {9.9613, 54.07113}]}
      },

      {:parse_hex, "00940C3C00528179000F3327000F960303", %{},{%{
        alt_m: 39.9,
        last_measurement_isvalid: "false",
        op_mode: "alive",
        position: "GPS fix",
        sat_cnt: 3,
        temp: 14.8,
        vbat: 3.132
        }, [location: {9.96135, 54.07097}]}
        },
    ]
  end

end
