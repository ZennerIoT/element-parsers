defmodule Parser do
  use Platform.Parsing.Behaviour

  require Logger

  # ELEMENT IoT Parser for Netvox Sensors
  # According to documentation provided by Netvox:
  #
  # Netvox LoRaWAN Application Command V1.8.2 / V1.8.5
  #
  # Online Decoder:
  #   http://www.netvox.com.cn:8888/page/index
  #
  # Payload documentation:
  #   https://www.alliot.co.uk/wp-content/uploads/2019/08/Netvox-LoRaWAN-Application-Command-V1.9.2-for-public.pdf
  #
  # Changelog:
  #   2019-04-30 [kr]: initial version (Light Sensors: R311G, R311B,  Water Leak Sensors: R311W, R718WB, R718WA, R718WA2, R718WB2)
  #   2019-06-05 [gw]: refactoring. Checked with v1.8.5
  #   2019-07-01 [gw]: fix bug
  #   2020-01-09 [as]: added some sensor types
  #   2020-04-28 [as]: added some more sensor types
  #   2020-06-16 [as]: added 3 phase current meter (BROKEN)
  #   2020-11-19 [jb]: Added support for R711/R718A/R718AB/R720A temperature/humidity sensors.
  #   2020-12-22 [jb]: Added support for R311FA/RA02C/RA0716 sensor. Formatted code.

  def parse(<<version::8, device_type::8, report_type::8, rest::binary>>, %{
        meta: %{frame_port: 6}
      }) do
    %{
      # Protocol Version
      version: version,
      # Device Type
      device_type: device_type,
      # Device Type Text
      device_type_name: device_type_name(device_type),
      # Report Type: 0 for Status (All Sensors)
      report_type: report_type
    }
    |> Map.merge(parse_payload(device_type, report_type, rest))
  end

  def parse(payload, meta) do
    Logger.info(
      "Unhandled meta.frame_port: #{inspect(get_in(meta, [:meta, :frame_port]))} with payload #{
        inspect(payload)
      }"
    )

    []
  end

  # All Sensors (Reporttype 0x00)
  defp parse_payload(
         _device_type,
         0x00,
         <<sw_version::8, hw_version::8, date_code::binary-4, _rfu::binary-2>>
       ) do
    %{
      # Software Version
      sw_version: "V#{sw_version / 10}",
      # Hardware Version
      hw_version: "V#{hw_version / 10}",
      # Manufacture Date
      date_code: Base.encode16(date_code)
    }
  end

  defp parse_payload(device_type, 0x01, <<battery::binary-1, status::8, _rfu::binary-6>>)
       when device_type in [
              0x1A,
              0x1B,
              0x21,
              0x25,
              0x27,
              0x4F,
              0x5B,
              0x82,
              0x89,
              0x8B,
              0x8D,
              0x97,
              0xA8,
              0xA9,
              0xB7
            ] do
    %{
      # Status Flag 0=off, 1=on
      status: status
    }
    |> Map.merge(parse_battery_info(battery))
  end

  defp parse_payload(
         device_type,
         0x01,
         <<battery::binary-1, status1::8, status2::8, _rfu::binary-5>>
       )
       when device_type in [
              0x2F,
              0x3D,
              0x3E,
              0x43,
              0x45,
              0x4C,
              0x56,
              0x7E,
              0x8A,
              0x8C,
              0x8E,
              0x6C
            ] do
    %{
      # Status Flag 0=off, 1=on
      status1: status1,
      # Status Flag 0=off, 1=on
      status2: status2
    }
    |> Map.merge(parse_battery_info(battery))
  end

  defp parse_payload(
         device_type,
         0x01,
         <<battery::binary-1, temperature::binary-2, humditiy::binary-2, pm2_5::16,
           _rfu::binary-1>>
       )
       when device_type in [0x35, 0x36, 0x37, 0x5D, 0x5E, 0x5F, 0x6A] do
    %{
      # 1ug/m3
      pm2_5: pm2_5
    }
    |> Map.merge(parse_humidity(humditiy))
    |> Map.merge(parse_temperature(temperature))
    |> Map.merge(parse_battery_info(battery))
  end

  # RA02C
  defp parse_payload(
         0x11,
         0x01,
         <<battery::binary-1, co2_alarm, high_temp_alarm, _rfu::binary-5>>
       ) do
    %{
      co2_alarm: co2_alarm,
      high_temp_alarm: high_temp_alarm
    }
    |> Map.merge(parse_battery_info(battery))
  end

  # R311G/R311B Light Sensor (Devicetype 0x04, 0x4B)
  defp parse_payload(device_type, 0x01, <<battery::binary-1, lux::16, _rfu::binary-5>>)
       when device_type in [0x04, 0x4B] do
    %{
      # Illuminance
      lux: lux
    }
    |> Map.merge(parse_battery_info(battery))
  end

  # R311W Water leak Sensor (Devicetype 0x06)
  # R718WA2 2-Gang Water Leak Detector (Devicetype 0x46)
  # R718WB2 2-Gang Water Leak Detector with Rope Sensor (Devicetype 0x47)
  defp parse_payload(
         0x06,
         0x01,
         <<battery::binary-1, water_leak_1::binary-1, water_leak_2::binary-1, _rfu::binary-5>>
       ) do
    %{}
    |> Map.merge(parse_water_leak(1, water_leak_1))
    |> Map.merge(parse_water_leak(2, water_leak_2))
    |> Map.merge(parse_battery_info(battery))
  end

  # R718WB Water Leak Detector with Rope Sensor (Devicetype 0x12)
  # R718WA Water Leak Detector (Devicetype 0x32)
  defp parse_payload(
         device_type,
         0x01,
         <<battery::binary-1, water_leak_1::binary-1, _rfu::binary-6>>
       )
       when device_type in [0x12, 0x32] do
    %{}
    |> Map.merge(parse_water_leak(1, water_leak_1))
    |> Map.merge(parse_battery_info(battery))
  end

  # R718WB Water Leak Detector with Rope Sensor (Devicetype 0x12)
  # R718WA Water Leak Detector (Devicetype 0x32)
  defp parse_payload(
         device_type,
         0x01,
         <<battery::binary-1, water_leak_1::binary-1, water_leak_2::binary-1, _rfu::binary-5>>
       )
       when device_type in [0x46, 0x47] do
    %{}
    |> Map.merge(parse_water_leak(1, water_leak_1))
    |> Map.merge(parse_water_leak(2, water_leak_2))
    |> Map.merge(parse_battery_info(battery))
  end

  # RB02I Emergency Push Button (Devicetype 0x10)
  # R718T Push Button Interface(Devicetype 0x31)
  # R312A R312A Emergency Button(Devicetype 0x4D)
  # R312 Door Bell Button(Devicetype 0x55)
  defp parse_payload(device_type, 0x01, <<battery::binary-1, alarm_1::binary-1, _rfu::binary-6>>)
       when device_type in [0x10, 0x31, 0x4D, 0x55] do
    %{}
    |> Map.merge(parse_alarm(1, alarm_1))
    |> Map.merge(parse_battery_info(battery))
  end

  # RB11E Occupancy/Light/Temperature Sensor (Devicetype 0x03)
  # RB11E1 (Devicetype 0x07)
  defp parse_payload(
         device_type,
         0x01,
         <<battery::binary-1, temperature::signed-16, lux::16, occupy_1::binary-1,
           alarm_1::binary-1, _rfu::binary-1>>
       )
       when device_type in [0x03, 0x07] do
    %{
      lux: lux,
      temperature: temperature / 100
    }
    |> Map.merge(parse_occupy(1, occupy_1))
    |> Map.merge(parse_alarm(1, alarm_1))
    |> Map.merge(parse_battery_info(battery))
  end

  # RA02A Smoke Detector (Devicetype 0x0A)
  defp parse_payload(
         device_type,
         0x01,
         <<battery::binary-1, firealarm_1::binary-1, hightempalarm_1::binary-1, _rfu::binary-5>>
       )
       when device_type in [0x0A] do
    %{}
    |> Map.merge(parse_firealarm(1, firealarm_1))
    |> Map.merge(parse_hightempalarm(1, hightempalarm_1))
    |> Map.merge(parse_battery_info(battery))
  end

  # R718NX 1-Phase Current Meter (Devicetype 0x49)
  defp parse_payload(
         device_type,
         0x01,
         <<battery::binary-1, current_t::16, multiplier::8, _rfu::binary-4>>
       )
       when device_type in [0x49] do
    %{
      current: current_t * multiplier
    }
    |> Map.merge(parse_battery_info(battery))
  end

  # TODO: This is broken
  #  # R718NX 3-Phase Current Meter (Devicetype 0x4A)
  #  defp parse_payload(device_type, 0x01, <<battery::binary-1, current1_t::16, current2_t::16, current3_t::16, multiplier::8>>) when device_type in [0x4A] do
  #    %{
  #      current1: current1_t*multiplier,
  #      current2: current2_t*multiplier,
  #      current3: current3_t*multiplier,
  #    }
  #    |> Map.merge(parse_battery_info(battery))
  #  end
  #  defp parse_payload(device_type, 0x02, <<battery::binary-1, _current1_t::16, _current2_t::16, _current3_t::16, _multiplier::8>>) when device_type in [0x4A] do
  #    %{
  #      error: :missing_multiplier,
  #    }
  #    |> Map.merge(parse_battery_info(battery))
  #  end

  # R711/R718A/R718AB/R720A
  defp parse_payload(
         device_type,
         0x01,
         <<battery::binary-1, temperature::binary-2, humidity::binary-2, _rest::binary>>
       )
       when device_type in [0x01, 0x0B, 0x13, 0x6E] do
    %{}
    |> Map.merge(parse_humidity(humidity))
    |> Map.merge(parse_temperature(temperature))
    |> Map.merge(parse_battery_info(battery))
  end

  # Catchall
  defp parse_payload(_device_type, _report_type, payload) do
    %{
      unknown_payload: Base.encode16(payload)
    }
  end

  defp parse_battery_info(<<lowbat::1, battery_voltage::7>>) do
    %{
      # Battery Low Indicator (0: Battery OK, 1: low Battery)
      low_battery: lowbat,
      # Battery voltage in V
      battery: battery_voltage / 10
    }
  end

  defp parse_temperature(<<temperature::signed-16>>) do
    %{
      temperature: temperature / 100
    }
  end

  defp parse_humidity(<<humidity::16>>) do
    %{
      humidity: humidity / 100
    }
  end

  defp parse_water_leak(i, <<water_leak::8>>) do
    %{
      "water_leak_#{i}" => water_leak,
      "water_leak_#{i}_text" => water_leak_text(water_leak)
    }
  end

  defp parse_alarm(i, <<alarm::8>>) do
    %{
      "alarm_#{i}" => alarm,
      "alarm_#{i}_text" => alarm_text(alarm)
    }
  end

  defp parse_firealarm(i, <<firealarm::8>>) do
    %{
      "firealarm_#{i}" => firealarm,
      "firealarm_#{i}_text" => firealarm_text(firealarm)
    }
  end

  defp parse_hightempalarm(i, <<hightempalarm::8>>) do
    %{
      "hightempalarm_#{i}" => hightempalarm,
      "hightempalarm_#{i}_text" => hightempalarm_text(hightempalarm)
    }
  end

  defp parse_occupy(i, <<occupy::8>>) do
    %{
      "occupy_#{i}" => occupy,
      "occupy_#{i}_text" => occupy_text(occupy)
    }
  end

  defp water_leak_text(0), do: "No Leak"
  defp water_leak_text(1), do: "Leak"
  defp alarm_text(0), do: "No Alarm"
  defp alarm_text(1), do: "Alarm"
  defp firealarm_text(0), do: "No Alarm"
  defp firealarm_text(1), do: "Alarm"
  defp hightempalarm_text(0), do: "No Alarm"
  defp hightempalarm_text(1), do: "Alarm"
  defp occupy_text(0), do: "Unoccupied"
  defp occupy_text(1), do: "Occupied"

  def device_type_name(0x01), do: "R711 Indoor Temperature Humidity Sensor"
  def device_type_name(0x02), do: "R311A Door/Window Sensor"
  def device_type_name(0x03), do: "RB11E Occupancy/Light/Temperature Sensor"
  def device_type_name(0x04), do: "R311G Light Sensor"
  def device_type_name(0x05), do: "RA07"
  def device_type_name(0x06), do: "R311W Water Leak Sensor"
  def device_type_name(0x07), do: "RB11E1"
  def device_type_name(0x08), do: "R801A Temperature Sensor with a Thermocouple"
  def device_type_name(0x09), do: "R726"
  def device_type_name(0x0A), do: "RA02A Smoke Detector"

  def device_type_name(0x0B),
    do: "R718A Temperature and Humidity Sensor for Low Temperature Environment"

  def device_type_name(0x0C), do: "RA07W Water Leak Detection & Location Sensor"
  def device_type_name(0x0D), do: "R727"
  def device_type_name(0x0E), do: "R809A Plug-and-Play Power Outlet with Consumption Monitoring"
  def device_type_name(0x0F), do: "R211 IR Blaster"
  def device_type_name(0x10), do: "RB02I Emergency Push Button"
  def device_type_name(0x11), do: "RA02C CO Detector"
  def device_type_name(0x12), do: "R718WB Water Leak Detector with Rope Sensor"
  def device_type_name(0x13), do: "R718AB Temperature and Humidity Sensor"
  def device_type_name(0x14), do: "R718B2 2-Gang Temperature Sensor"
  def device_type_name(0x15), do: "R718CJ Thermocouple Interface for J Type Thermocouple"
  def device_type_name(0x16), do: "R718CK Thermocouple Interface for K Type Thermocouple"
  def device_type_name(0x17), do: "R718CT Thermocouple Interface for T Type Thermocouple"
  def device_type_name(0x18), do: "R718CR Thermocouple Interface for R Type Thermocouple"
  def device_type_name(0x19), do: "R718CE Thermocouple Interface for E Type Thermocouple"
  def device_type_name(0x1A), do: "R718DA Vibration Sensor, Rolling Ball Type"
  def device_type_name(0x1B), do: "R718DB Vibration Sensor, Spring Type"
  def device_type_name(0x1C), do: "R718E Three-Axis Digital Accelerometer & NTC Thermistor"
  def device_type_name(0x1D), do: "R718F Reed Switch Open/Close Detection Sensor"
  def device_type_name(0x1E), do: "R718G Light Sensor"
  def device_type_name(0x1F), do: "R718H Pulse Counter Interface"
  def device_type_name(0x20), do: "R718IA 0-5V ADC Sampling Interface"
  def device_type_name(0x21), do: "R718J Dry Contact Interface"
  def device_type_name(0x22), do: "R718KA mA Current Meter Interface, 4~20mA"
  def device_type_name(0x23), do: "R718KB"
  def device_type_name(0x24), do: "R718LA"
  def device_type_name(0x25), do: "R718LB Hall Type Open/Close Detection Sensor"
  def device_type_name(0x26), do: "R718MA Asset Sensor"
  def device_type_name(0x27), do: "R718MBA Activity Detection Sensor"
  def device_type_name(0x28), do: "R718MC"
  def device_type_name(0x29), do: "R718N Current Meter"
  def device_type_name(0x2A), do: "R718IB 0-10V ADC Sampling Interface"
  def device_type_name(0x2B), do: "R718MBB Activity Event Counter"
  def device_type_name(0x2C), do: "R718MBC Activity Timer"
  def device_type_name(0x2D), do: "R7185N"
  def device_type_name(0x2E), do: "R718B4"
  def device_type_name(0x2F), do: "R718DA2 2-Gang Vibration Sensor Rolling Ball Type"
  def device_type_name(0x30), do: "R718S"
  def device_type_name(0x31), do: "R718T Push Button Interface"
  def device_type_name(0x32), do: "R718WA Water Leak Detector"
  def device_type_name(0x33), do: "R718WD Liquid Level Sensor"
  def device_type_name(0x34), do: "R718X"
  def device_type_name(0x35), do: "RA0716 PM2.5/Temperature/Humidity Sensor"
  def device_type_name(0x36), do: "R72616"
  def device_type_name(0x37), do: "R72716 Outdoor PM2.5/Temperature/Humidity Sensor"
  def device_type_name(0x38), do: "R718CJ4"
  def device_type_name(0x39), do: "R718CK4"
  def device_type_name(0x3A), do: "R718CT4"
  def device_type_name(0x3B), do: "R718CR4"
  def device_type_name(0x3C), do: "R718CE4"
  def device_type_name(0x3D), do: "R718DB2 2-Gang Vibration Sensor, Spring Type"
  def device_type_name(0x3E), do: "R718F2 2-Gang Reed Switch Open/Close Detection Sensor"
  def device_type_name(0x3F), do: "R718H2 2-Input Pulse Counter Interface"
  def device_type_name(0x40), do: "R718H4"
  def device_type_name(0x41), do: "R718IA2 2-Input 0-5V ADC Sampling Interface"
  def device_type_name(0x42), do: "R718IB2 2-Input 0-10V ADC Sampling Interface"
  def device_type_name(0x43), do: "R718J2 2-Input Dry Contact Interface"
  def device_type_name(0x44), do: "R718KA2 2-Input mA Current Meter Interface, 4~20 mA"
  def device_type_name(0x45), do: "R718LB2 2-Gang Hall Type Open/Close Detection Sensor"
  def device_type_name(0x46), do: "R718WA2 2-Gang Water Leak Detector"
  def device_type_name(0x47), do: "R718WB2 2-Gang Water Leak Detector with Rope Sensor"
  def device_type_name(0x48), do: "R718T2 2-Input Push Button Interface"
  def device_type_name(0x49), do: "R718N1 1-Phase Current Meter with 1 x 30A CT"
  def device_type_name(0x4A), do: "R718N3 3-Phase Current Meter with 3 x 60A CT"
  def device_type_name(0x4B), do: "R311B Light Sensor"
  def device_type_name(0x4C), do: "R311CA 2-Gang Dry Contact Sensor"
  def device_type_name(0x4D), do: "R312A Emergency Button"
  def device_type_name(0x4E), do: "R311D Simple Location Device"
  def device_type_name(0x4F), do: "R311FA Activity Detection Sensor"
  def device_type_name(0x50), do: "R311FB Activity Event Detection"
  def device_type_name(0x51), do: "R311FC Activity Timer"
  def device_type_name(0x52), do: "RA07A (indoor PM2.5, ambient temperature and humidity)"
  def device_type_name(0x53), do: "R726A"
  def device_type_name(0x54), do: "R727A"
  def device_type_name(0x55), do: "R312 Door Bell Button"
  def device_type_name(0x56), do: "R311CB Window/Door Sensor and Wireless Glass Sensor"
  def device_type_name(0x57), do: "R718PA Series"
  def device_type_name(0x58), do: "R718PB Series"
  def device_type_name(0x59), do: "R719A"
  def device_type_name(0x5A), do: "R311WA(R313WA)"
  def device_type_name(0x5B), do: "R718Q(R718PQ)"
  def device_type_name(0x5C), do: "R718IJK"
  def device_type_name(0x5D), do: "R718SA"
  def device_type_name(0x5E), do: "R728SA"
  def device_type_name(0x5F), do: "R729SA"
  def device_type_name(0x60), do: "R718R Series"
  def device_type_name(0x61), do: "R718U Series"
  def device_type_name(0x62), do: "R718S Series"
  def device_type_name(0x63), do: "R728R Series"
  def device_type_name(0x64), do: "R728U Series"
  def device_type_name(0x65), do: "R728S Series"
  def device_type_name(0x66), do: "R729R Series"
  def device_type_name(0x67), do: "R729U Series"
  def device_type_name(0x68), do: "R729S Series"
  def device_type_name(0x69), do: "R602A"
  def device_type_name(0x6A), do: "RA0716A(R72616A)"
  def device_type_name(0x6B), do: "R718WBA"
  def device_type_name(0x6C), do: "R311CC(R313CC)"
  def device_type_name(0x6D), do: "R306"
  def device_type_name(0x6E), do: "R720A"
  def device_type_name(0x6F), do: "R720B"
  def device_type_name(0x70), do: "R720C"
  def device_type_name(0x71), do: "RA10"
  def device_type_name(0x72), do: "R718PC"
  def device_type_name(0x73), do: "R816(R816B/R816B01)"
  def device_type_name(0x74), do: "R730IA"
  def device_type_name(0x75), do: "R730IB"
  def device_type_name(0x76), do: "R730IA2"
  def device_type_name(0x77), do: "R730IB2"
  def device_type_name(0x78), do: "R730CJ2"
  def device_type_name(0x79), do: "R730CK2"
  def device_type_name(0x7A), do: "R730CT2"
  def device_type_name(0x7B), do: "R730CR2"
  def device_type_name(0x7C), do: "R730CE2"
  def device_type_name(0x7D), do: "R730F"
  def device_type_name(0x7E), do: "R730F2"
  def device_type_name(0x7F), do: "R730H"
  def device_type_name(0x80), do: "R730H2"
  def device_type_name(0x81), do: "R730MA"
  def device_type_name(0x82), do: "R730MBA"
  def device_type_name(0x83), do: "R730MBB"
  def device_type_name(0x84), do: "R730MBC"
  def device_type_name(0x85), do: "R730WA"
  def device_type_name(0x86), do: "R730WA2"
  def device_type_name(0x87), do: "R730WB"
  def device_type_name(0x88), do: "R730WB2"
  def device_type_name(0x89), do: "R730DA"
  def device_type_name(0x8A), do: "R730DA2"
  def device_type_name(0x8B), do: "R730DB"
  def device_type_name(0x8C), do: "R730DB2"
  def device_type_name(0x8D), do: "R730LB"
  def device_type_name(0x8E), do: "R730LB2"
  def device_type_name(0x8F), do: "R718WE"
  def device_type_name(0x90), do: "R718CJ"
  def device_type_name(0x91), do: "R718CK"
  def device_type_name(0x92), do: "R718CT"
  def device_type_name(0x93), do: "R718CR"
  def device_type_name(0x94), do: "R718CE"
  def device_type_name(0x95), do: "R718B"
  def device_type_name(0x96), do: "R718PD"
  def device_type_name(0x97), do: "R718QA(R718PQA)"
  def device_type_name(0x98), do: "R718NL1"
  def device_type_name(0x99), do: "R718NL3"
  def device_type_name(0x9A), do: "R718EA"
  def device_type_name(0x9B), do: "R718PA22"
  def device_type_name(0x9C), do: "R718AD"
  def device_type_name(0x9D), do: "R720D"
  def device_type_name(0x9E), do: "R311K(R313K)"
  def device_type_name(0x9F), do: "R718VA(R718VB)"
  def device_type_name(0xA0), do: "R731A Series(R731A01-R731A21)"
  def device_type_name(0xA1), do: "R731BC Series(R731BC01-R731BC21)"
  def device_type_name(0xA2), do: "R731BD Series(R731BD01-R731BD21)"
  def device_type_name(0xA3), do: "R731BE Series(R731BE01-R731BE21)"
  def device_type_name(0xA4), do: "R960"
  def device_type_name(0xA5), do: "R720E"
  def device_type_name(0xA6), do: "RB02B"
  def device_type_name(0xA7), do: "RB02C"
  def device_type_name(0xA8), do: "R311DA(R313DA)"
  def device_type_name(0xA9), do: "R311DB(R313DB)"
  def device_type_name(0xAA), do: "R311LA(R313LA)"
  def device_type_name(0xAB), do: "R311LB(R313LB)"
  def device_type_name(0xAC), do: "R718Y"
  def device_type_name(0xAD), do: "R831C"
  def device_type_name(0xAE), do: "R731A22/R731BC22/R731BD22/R731BE22"
  def device_type_name(0xAF), do: "R719B"
  def device_type_name(0xB0), do: "R831D"
  def device_type_name(0xB1), do: "R718PE"
  def device_type_name(0xB2), do: "R831A"
  def device_type_name(0xB3), do: "R831B"
  def device_type_name(0xB4), do: "R832"
  def device_type_name(0xB5), do: "R720G"
  def device_type_name(0xB6), do: "R718Z"
  def device_type_name(0xB7), do: "R720F"
  # Add new devices here.
  def device_type_name(0xFF), do: "ALL devices"
  def device_type_name(_), do: "reserved/unknown"

  def fields() do
    [
      # all sensors
      %{
        field: "version",
        display: "Protocol Version"
      },
      %{
        field: "device_type",
        display: "Device Type"
      },
      %{
        field: "device_type_name",
        display: "Device Type Name"
      },
      %{
        field: "report_type",
        display: "Report Type"
      },
      %{
        field: "low_battery",
        display: "Low Battery"
      },
      %{
        field: "battery",
        display: "Battery Voltage",
        unit: "V"
      },
      %{
        field: "sw_version",
        display: "Software Version"
      },
      %{
        field: "hw_version",
        display: "Hardware Version"
      },
      %{
        field: "date_code",
        display: "Manufacture Date"
      },

      # Light Sensors: R311G, R311B
      # Occupancy Sensors: RB11E, RB11E1
      %{
        field: "lux",
        display: "Illuminance",
        unit: "lux"
      },

      # Occupancy Sensors: RB11E, RB11E1
      %{
        field: "temperature",
        display: "Temperature",
        unit: "°C"
      },

      # Water Leak Sensors: R311W, R718WB, R718WA, R718WA2, R718WB2
      %{
        field: "water_leak_1",
        display: "Water Leak 1"
      },
      %{
        field: "water_leak_2",
        display: "Water Leak 2"
      },

      # Emergency Button Sensors: RB02I, R718T, R312A R312A, R3125
      # Occupancy Sensors: RB11E, RB11E1
      %{
        field: "alarm_1",
        display: "Alarm 1"
      },

      # Occupancy Sensors: RB11E, RB11E1
      %{
        field: "occupy_1",
        display: "Occupation"
      },

      # Smoke Alarm: RA02A
      %{
        field: "firealarm_1",
        display: "Fire Alarm"
      },
      %{
        field: "hightempalarm_1",
        display: "High Temperature Alarm"
      },

      # Current Meter
      %{
        field: "current",
        display: "Current",
        unit: "mA"
      },

      # RA0716
      %{
        field: "pm2_5",
        display: "PM2.5",
        unit: "ug/m3"
      }
    ]
  end

  def tests() do
    [
      # Rep Type 0
      {
        :parse_hex,
        "0104000A0B201811190000",
        %{meta: %{frame_port: 6}},
        %{
          date_code: "20181119",
          device_type: 4,
          device_type_name: "R311G Light Sensor",
          hw_version: "V1.1",
          report_type: 0,
          sw_version: "V1.0",
          version: 1
        }
      },

      # Rep Type 1 (R311G)
      {
        :parse_hex,
        "0104012000360000000000",
        %{meta: %{frame_port: 6}},
        %{
          battery: 3.2,
          device_type: 4,
          device_type_name: "R311G Light Sensor",
          low_battery: 0,
          lux: 54,
          report_type: 1,
          version: 1
        }
      },

      # Rep Type 1 (R311W)
      {
        :parse_hex,
        "0106012000010000000000",
        %{meta: %{frame_port: 6}},
        %{
          "water_leak_1" => 0,
          "water_leak_1_text" => "No Leak",
          "water_leak_2" => 1,
          "water_leak_2_text" => "Leak",
          report_type: 1,
          version: 1,
          battery: 3.2,
          device_type: 6,
          device_type_name: "R311W Water Leak Sensor",
          low_battery: 0
        }
      },

      # R711
      {
        :parse_hex,
        "01010123087711F7000000",
        %{meta: %{frame_port: 6}},
        %{
          battery: 3.5,
          device_type: 1,
          device_type_name: "R711 Indoor Temperature Humidity Sensor",
          humidity: 45.99,
          low_battery: 0,
          report_type: 1,
          temperature: 21.67,
          version: 1
        }
      }
    ]
  end
end
