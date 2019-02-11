defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for Lobaro LoRaWAN GPS Tracker v5.0
  # According to documentation provided by Lobaro
  # Link: https://www.lobaro.com/portfolio/lorawan-gps-tracker/
  # Documentation: https://www.lobaro.com/download/7315/


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
end
