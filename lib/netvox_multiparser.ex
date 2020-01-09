defmodule Parser do
  use Platform.Parsing.Behaviour

  require Logger

  # ELEMENT IoT Parser for Netvox Sensors
  # According to documentation provided by Netvox:
  #
  # Netvox LoRaWAN Application Command V1.8.2 / V1.8.5
  #
  # Changelog:
  #   2019-04-30: [kr] initial version (Light Sensors: R311G, R311B,  Water Leak Sensors: R311W, R718WB, R718WA, R718WA2, R718WB2)
  #   2019-06-05: [gw] refactoring. Checked with v1.8.5
  #   2019-07-01: [gw] fix bug
  #   2020-01-09: [as] added some sensor types

  def parse(<<version::8, device_type::8, report_type::8, rest::binary>>, %{meta: %{frame_port: 6}}) do
    %{
      version: version,                                 # Protocol Version
      device_type: device_type,                         # Device Type
      device_type_name: device_type_name(device_type),  # Device Type Text
      report_type: report_type,                         # Report Type: 0 for Status (All Sensors)
    }
    |> Map.merge(parse_payload(device_type, report_type, rest))
  end

  def parse(payload, meta) do
    Logger.info("Unhandled meta.frame_port: #{inspect get_in(meta, [:meta, :frame_port])} with payload #{inspect payload}")
    []
  end

  # All Sensors (Reporttype 0x00)
  defp parse_payload(_device_type, 0x00, <<sw_version::8, hw_version::8, date_code::binary-4, _rfu::binary-2>>) do
    %{
      sw_version: "V#{sw_version/10}",      # Software Version
      hw_version: "V#{hw_version/10}",      # Hardware Version
      date_code: Base.encode16(date_code),  # Manufacture Date
    }
  end

  # R311G/R311B Light Sensor (Devicetype 0x04/0x4B)
  defp parse_payload(device_type, 0x01, <<battery::binary-1, lux::16, _rfu::binary-5>>) when device_type in [0x04, 0x4B] do
    %{
      lux: lux # Illuminance
    }
    |> Map.merge(parse_battery_info(battery))
  end

  # R311W Water leak Sensor (Devicetype 0x06)
  # R718WA2 2-Gang Water Leak Detector (Devicetype 0x46)
  # R718WB2 2-Gang Water Leak Detector with Rope Sensor (Devicetype 0x47)
  defp parse_payload(0x06, 0x01, <<battery::binary-1, water_leak_1::binary-1, water_leak_2::binary-1, _rfu::binary-5>>) do
    %{}
    |> Map.merge(parse_water_leak(1, water_leak_1))
    |> Map.merge(parse_water_leak(2, water_leak_2))
    |> Map.merge(parse_battery_info(battery))
  end

  # R718WB Water Leak Detector with Rope Sensor (Devicetype 0x12)
  # R718WA Water Leak Detector (Devicetype 0x32)
  defp parse_payload(device_type, 0x01, <<battery::binary-1, water_leak_1::binary-1, _rfu::binary-6>>) when device_type in [0x12, 0x32] do
    %{}
    |> Map.merge(parse_water_leak(1, water_leak_1))
    |> Map.merge(parse_battery_info(battery))
  end

  # RB02I Emergency Push Button (Devicetype 0x10)
  # R718T Push Button Interface(Devicetype 0x31)
  # R312A R312A Emergency Button(Devicetype 0x4D)
  # R312 Door Bell Button(Devicetype 0x55)
  defp parse_payload(device_type, 0x01, <<battery::binary-1, alarm_1::binary-1, _rfu::binary-6>>) when device_type in [0x10, 0x31, 0x4D, 0x55] do
    %{
    }
    |> Map.merge(parse_alarm(1, alarm_1))
    |> Map.merge(parse_battery_info(battery))
  end

  # RB11E Occupancy/Light/Temperature Sensor (Devicetype 0x03)
  # RB11E1 (Devicetype 0x07)
  defp parse_payload(device_type, 0x01, <<battery::binary-1, temperature::signed-16, lux::16, occupy_1::binary-1, alarm_1::binary-1, _rfu::binary-1>>) when device_type in [0x03, 0x07] do
    %{
      lux: lux,
      temperature: temperature/100
    }
    |> Map.merge(parse_occupy(1, occupy_1))
    |> Map.merge(parse_alarm(1, alarm_1))
    |> Map.merge(parse_battery_info(battery))
  end

  # RA02A Smoke Detector (Devicetype 0x0A)
  defp parse_payload(device_type, 0x01, <<battery::binary-1, firealarm_1::binary-1, hightempalarm_1::binary-1, _rfu::binary-5>>) when device_type in [0x0A] do
    %{
    }
    |> Map.merge(parse_firealarm(1, firealarm_1))
    |> Map.merge(parse_hightempalarm(1, hightempalarm_1))
    |> Map.merge(parse_battery_info(battery))
  end


  defp parse_battery_info(<<lowbat::1, battery_voltage::7>>) do
    %{
      low_battery: lowbat,          # Battery Low Indicator (0: Battery OK, 1: low Battery)
      battery: battery_voltage/10,  # Battery voltage in V
    }
  end

  defp parse_water_leak(i, <<water_leak::8>>) do
    %{
      "water_leak_#{i}" => water_leak,
      "water_leak_#{i}_text" => water_leak_text(water_leak),
    }
  end

  defp parse_alarm(i, <<alarm::8>>) do
    %{
      "alarm_#{i}" => alarm,
      "alarm_#{i}_text" => alarm_text(alarm),
    }
  end

  defp parse_firealarm(i, <<firealarm::8>>) do
    %{
      "firealarm_#{i}" => firealarm,
      "firealarm_#{i}_text" => firealarm_text(firealarm),
    }
  end

  defp parse_hightempalarm(i, <<hightempalarm::8>>) do
    %{
      "hightempalarm_#{i}" => hightempalarm,
      "hightempalarm_#{i}_text" => hightempalarm_text(hightempalarm),
    }
  end

  defp parse_occupy(i, <<occupy::8>>) do
    %{
      "occupy_#{i}" => occupy,
      "occupy_#{i}_text" => occupy_text(occupy),
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
  def device_type_name(0x0B), do: "R718A Temperature and Humidity Sensor for Low Temperature Environment"
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

  def fields() do
    [
      # all sensors
      %{
        field: "version",
        display: "Protocol Version",
      },
      %{
        field: "device_type",
        display: "Device Type",
      },
      %{
        field: "device_type_name",
        display: "Device Type Name",
      },
      %{
        field: "report_type",
        display: "Report Type",
      },
      %{
        field: "low_battery",
        display: "Low Battery",
      },
      %{
        field: "battery",
        display: "Battery Voltage",
        unit: "V",
      },
      %{
        field: "sw_version",
        display: "Software Version",
      },
      %{
        field: "hw_version",
        display: "Hardware Version",
      },
      %{
        field: "date_code",
        display: "Manufacture Date",
      },

      # Light Sensors: R311G, R311B
      # Occupancy Sensors: RB11E, RB11E1
      %{
        field: "lux",
        display: "Illuminance",
        unit: "lux",
      },

      # Occupancy Sensors: RB11E, RB11E1
      %{
        field: "temperature",
        display: "Temperature",
        unit: "°C",
      },

      # Water Leak Sensors: R311W, R718WB, R718WA, R718WA2, R718WB2
      %{
        field: "water_leak_1",
        display: "Water Leak 1",
      },
      %{
        field: "water_leak_2",
        display: "Water Leak 2",
      },

      # Emergency Button Sensors: RB02I, R718T, R312A R312A, R3125
      # Occupancy Sensors: RB11E, RB11E1
      %{
        field: "alarm_1",
        display: "Alarm 1",
      },

      # Occupancy Sensors: RB11E, RB11E1
      %{
        field: "occupy_1",
        display: "Occupation",
      },

      # Smoke Alarm: RA02A
      %{
        field: "firealarm_1",
        display: "Fire Alarm",
      },

      %{
        field: "hightempalarm_1",
        display: "High Temperature Alarm",
      },

    ]
  end

  def tests() do
    [
      # Rep Type 0
      {
        :parse_hex, "0104000A0B201811190000", %{meta: %{frame_port: 6}}, %{
        date_code: "20181119",
        device_type: 4,
        device_type_name: "R311G Light Sensor",
        hw_version: "V1.1",
        report_type: 0,
        sw_version: "V1.0",
        version: 1
      },
      },

      # Rep Type 1 (R311G)
      {
        :parse_hex, "0104012000360000000000", %{meta: %{frame_port: 6}}, %{
        battery: 3.2,
        device_type: 4,
        device_type_name: "R311G Light Sensor",
        low_battery: 0,
        lux: 54,
        report_type: 1,
        version: 1
      },
      },

      # Rep Type 1 (R311W)
      {
        :parse_hex, "0106012000010000000000", %{meta: %{frame_port: 6}}, %{
        "water_leak_1" => 0,
        "water_leak_1_text" => "No Leak",
        "water_leak_2" => 1,
        "water_leak_2_text" => "Leak",
        report_type: 1,
        version: 1,
        battery: 3.2,
        device_type: 6,
        device_type_name: "R311W Water Leak Sensor",
        low_battery: 0,
      },
      },
    ]
  end

end
