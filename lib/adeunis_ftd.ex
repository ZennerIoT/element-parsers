defmodule Parser do
  use Platform.Parsing.Behaviour
  
    
  # ELEMENT IoT Parser for Adeunis Field Test Device
  # According to documentation provided by Adeunis
  # Link: https://www.adeunis.com/en/produit/ftd-868-915-2/
  # Documentation: https://www.adeunis.com/wp-content/uploads/2017/08/FTD_LoRaWAN_EU863-870_UG_FR_GB_V1.2.1.pdf
  
  # Changelog 18-09-03: AS: added fields for export functionality

  def parse(event, meta) do
    << status :: binary-1, rest :: binary >> = event
    {fields, status_data} = parse_status(status)
    field_data = parse_field(fields, rest, [])
    
    data = 
      Map.merge(status_data, field_data) 
      |> Map.put(:gw_rssi, get_best_rssi(meta))
    case data do
      %{latitude: lat, longitude: lng} -> {data, location: {lng, lat}}
      data -> data
    end
  end
  
  def parse_field([{_, false} | fields], payload, acc) do
    parse_field(fields, payload, acc)
  end
  
  def parse_field([{:has_temperature, true} | fields], << temperature :: signed-8, rest :: binary >>, _acc) do
    parse_field(fields, rest, [{:temperature, temperature}])
  end
  
  def parse_field([{:has_gps, true} | fields], << latitude :: binary-4, longitude :: binary-4, gps_quality :: binary-1, rest :: binary>>, acc) do
    << lat_deg :: bitstring-8, lat_min :: bitstring-20, _ :: 3, lat_hemi :: 1 >> = latitude
    << long_deg :: bitstring-12, long_min :: bitstring-16, _ :: 3, long_hemi :: 1 >> = longitude
    lat_deg = parse_bcd(lat_deg, 0)
    lat_min = parse_bcd(lat_min, 0)
  
    long_deg = parse_bcd(long_deg, 0)
    long_min = parse_bcd(long_min, 0)
    
    lat = hemi_to_sign(lat_hemi) * (lat_deg + (lat_min / 1000 / 60.0))
    long = hemi_to_sign(long_hemi) * (long_deg + (long_min / 100 / 60.0))
    
    << gps_reception_scale :: 4, gps_satellites :: 4 >> = gps_quality
    
    acc = Enum.concat([
      latitude: lat, 
      longitude: long,
      gps_reception_scale: gps_reception_scale,
      gps_satellites: gps_satellites
    ], acc)
    
    parse_field(fields, rest, acc)
  end
  
  def parse_field([{:has_up_fcnt, true} | fields], << up_fcnt :: 8, rest :: binary>>, acc) do
    parse_field(fields, rest, [{:up_fcnt, up_fcnt} | acc])
  end
  
  def parse_field([{:has_down_fcnt, true} | fields], << down_fcnt :: 8, rest :: binary>>, acc) do
    parse_field(fields, rest, [{:down_fcnt, down_fcnt} | acc])
  end
  
  def parse_field([{:has_battery_level, true} | fields], << level :: 16, rest :: binary >>, acc) do
    parse_field(fields, rest, [{:battery_voltage, level} | acc])
  end
  
  def parse_field([{:has_rssi_and_snr, true} | fields], << rssi :: 8, snr :: signed-8, rest :: binary >>, acc) do
    acc = Enum.concat([
      rssi: rssi * -1,
      snr: snr
    ], acc)
    parse_field(fields, rest, acc)
  end
  
  def parse_field([_ | fields], rest, acc) do
    # should not happen
    parse_field(fields, rest, acc)
  end
  
  def parse_field([], _, acc), do: Enum.into(acc, %{})
  
  def parse_status(<< has_temperature :: 1,
                      trigger_accelerometer :: 1,
                      trigger_push_button :: 1,
                      has_gps :: 1,
                      has_up_fcnt :: 1,
                      has_down_fcnt :: 1,
                      has_battery_level :: 1,
                      has_rssi_and_snr :: 1 >>) do
    {[
      has_temperature: has_temperature == 1,
      has_gps: has_gps == 1,
      has_up_fcnt: has_up_fcnt == 1,
      has_down_fcnt: has_down_fcnt == 1,
      has_battery_level: has_battery_level == 1,
      has_rssi_and_snr: has_rssi_and_snr == 1
    ], %{
      trigger_accelerometer: trigger_accelerometer == 1,
      trigger_push_button: trigger_push_button == 1
    }}
  end
  
  def parse_bcd(<< num::4, rest::bitstring>>, acc) do
    parse_bcd(rest, acc * 10 + num)
  end
  def parse_bcd("", acc), do: acc
  
  def hemi_to_sign(0), do: 1
  def hemi_to_sign(1), do: -1
  
  def fields do
  [
  %{
    field: "battery_voltage",
    display: "Battery Voltage",
    unit: "mV"
  },
  %{
    field: "gw_rssi",
    display: "GW RSSI",
    unit: "dBm"
  },
  %{
    field: "rssi",
    display: "RSSI",
    unit: "dBm"
  },
  %{
    field: "snr",
    display: "SNR",
    unit: "dB"
  },
  %{
    field: "latitude",
    display: "Latitude",
    unit: ""
  },
  %{
    field: "longitude",
    display: "Longitude",
    unit: ""
  },
  %{
    field: "temperature",
    display: "Temperatur",
    unit: "°C"
  }
  ]
  end
  
  def get_best_rssi(meta) do
    meta
    |> Map.get(:meta, %{})
    |> Map.get(:gateway_stats, [])
    |> Enum.map(&Map.get(&1, "rssi"))
    |> Enum.max(fn -> nil end)
  end
end
