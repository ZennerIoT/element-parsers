defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Netvox Sensors
  # According to documentation provided by Netvox:
  #
  # Netvox LoRaWAN Application Command V1.8.2
  #
  # Changelog
  #   2019-04-30: [kr] initial version (Light Sensors: R311G, R311B,  Water Leak Sensors: R311W, R718WB, R718WA, R718WA2, R718WB2)


  #----- Implementation

  # All Sensors (Reporttype 0x00)
  def parse(<<version::size(8), devtype::size(8), 0x00, sversion::size(8), hwversion::size(8), datecode::binary-4, _::binary>>, %{meta: %{frame_port: 6 }}) do
    %{
      version: version,                        # Protocol Version
      devtype: devtype,                        # Device Type
      devtype_name: device_type_name(devtype), # Device Type Text
      reptype: 0,                              # Report Type: 0 for Status (All Sensors)
      sversion: "V#{sversion/10}",             # Software Version
      hwversion: "V#{hwversion/10}",           # Hardware Version
      datecode: Base.encode16(datecode)        # Manufacture Date
    }
  end

  # R311G Light Sensor (Reporttype 0x04)
  def parse(<<version::size(8), 0x04, 0x01, lowbat::1, bat::size(7), lux::size(16), _::binary>>, %{meta: %{frame_port: 6 }}) do
    %{
      version: version,                        # Protocol Version
      devtype: 0x04,                           # Device Type
      devtype_name: device_type_name(0x04),    # Device Type Text
      reptype: 1,                              # Report Type (1: for Measurement Report)
      lowbat: lowbat,                          # Battery Low Indicator (0: Battery OK, 1: low Battery)
      bat: bat/10,                             # Battery voltage in V
      lux: lux                                 # Illuminance
    }
  end

  # R311B Lightsensor (Reporttype 0x4B)
  def parse(<<version::size(8), 0x4B, 0x01, lowbat::1, bat::size(7), lux::size(16), _::binary>>, %{meta: %{frame_port: 6 }}) do
    %{
      version: version,                        # Protocol Version
      devtype: 0x4B,                           # Device Type
      devtype_name: device_type_name(0x4B),    # Device Type Text
      reptype: 1,                              # Report Type (1: for Measurement Report)
      lowbat: lowbat,                          # Battery Low Indicator (0: Battery OK, 1: low Battery)
      bat: bat/10,                             # Battery voltage in V
      lux: lux                                 # Illuminance
    }
  end
  
  # R311W Water leak Sensor (Reporttype 0x06)
  def parse(<<version::size(8), 0x06, 0x01, lowbat::1, bat::size(7), water1leak::size(8), water2leak::size(8), _::binary>>, %{meta: %{frame_port: 6 }}) do
    %{
      version: version,                        # Protocol Version
      devtype: 0x06,                           # Device Type
      devtype_name: device_type_name(0x06),    # Device Type Text
      reptype: 1,                              # Report Type (1: for Measurement Report)
      lowbat: lowbat,                          # Battery Low Indicator (0: Battery OK, 1: low Battery)
      bat: bat/10,                             # Battery voltage in V
      water1leak: water1leak,                  # Water 1 Leak state (0: No Leak, 1: Leak)
      water1leak_text:                         # Water 1 Leak state text
        case water1leak do
          0 -> "No Leak"
          1 -> "Leak"
        end,
      water2leak: water2leak,                  # Water 2 Leak state (0: No Leak, 1: Leak)
      water2leak_text:                         # Water 2 Leak state text
        case water2leak do
          0 -> "No Leak"
          1 -> "Leak"
        end
    }
  end

  # R718WB Water Leak Detector with Rope Sensor (Reporttype 0x12)
  def parse(<<version::size(8), 0x12, 0x01, lowbat::1, bat::size(7), water1leak::size(8), _::binary>>, %{meta: %{frame_port: 6 }}) do
    %{
      version: version,                        # Protocol Version
      devtype: 0x12,                           # Device Type
      devtype_name: device_type_name(0x12),    # Device Type Text
      reptype: 1,                              # Report Type (1: for Measurement Report)
      lowbat: lowbat,                          # Battery Low Indicator (0: Battery OK, 1: low Battery)
      bat: bat/10,                             # Battery voltage in V
      water11eak: water1leak,                  # Water 1 Leak state (0: No Leak, 1: Leak)
      water11eak_text:                         # Water 1 Leak state text
        case water1leak do
          0 -> "No Leak"
          1 -> "Leak"
        end
    }
  end

  # R718WA Water Leak Detector (Reporttype 0x32)
  def parse(<<version::size(8), 0x32, 0x01, lowbat::1, bat::size(7), water1leak::size(8), _::binary>>, %{meta: %{frame_port: 6 }}) do
    %{
      version: version,                        # Protocol Version
      devtype: 0x32,                           # Device Type
      devtype_name: device_type_name(0x32),    # Device Type Text
      reptype: 1,                              # Report Type (1: for Measurement Report)
      lowbat: lowbat,                          # Battery Low Indicator (0: Battery OK, 1: low Battery)
      bat: bat/10,                             # Battery voltage in V
      water11eak: water1leak,                  # Water 1 Leak state (0: No Leak, 1: Leak)
      water11eak_text:                         # Water 1 Leak state text
        case water1leak do
          0 -> "No Leak"
          1 -> "Leak"
        end
    }
  end

  # R718WA2 2-Gang Water Leak Detector (Reporttype 0x46)
  def parse(<<version::size(8), 0x46, 0x01, lowbat::1, bat::size(7), water1leak::size(8), water2leak::size(8), _::binary>>, %{meta: %{frame_port: 6 }}) do
    %{
      version: version,                        # Protocol Version
      devtype: 0x46,                           # Device Type
      devtype_name: device_type_name(0x46),    # Device Type Text
      reptype: 1,                              # Report Type (1: for Measurement Report)
      lowbat: lowbat,                          # Battery Low Indicator (0: Battery OK, 1: low Battery)
      bat: bat/10,                             # Battery voltage in V
      water1leak: water1leak,                  # Water 1 Leak state (0: No Leak, 1: Leak)
      water1leak_text:                         # Water 1 Leak state text
        case water1leak do
          0 -> "No Leak"
          1 -> "Leak"
        end,
      water2leak: water2leak,                  # Water 2 Leak state (0: No Leak, 1: Leak)
      water2leak_text:                         # Water 2 Leak state text
        case water2leak do
          0 -> "No Leak"
          1 -> "Leak"
        end
    }
  end

  # R718WB2 2-Gang Water Leak Detector with Rope Sensor (Reporttype 0x47)
  def parse(<<version::size(8), 0x47, 0x01, lowbat::1, bat::size(7), water1leak::size(8), water2leak::size(8), _::binary>>, %{meta: %{frame_port: 6 }}) do
    %{
      version: version,                        # Protocol Version
      devtype: 0x47,                           # Device Type
      devtype_name: device_type_name(0x47),    # Device Type Text
      reptype: 1,                              # Report Type (1: for Measurement Report)
      lowbat: lowbat,                          # Battery Low Indicator (0: Battery OK, 1: low Battery)
      bat: bat/10,                             # Battery voltage in V
      water1leak: water1leak,                  # Water 1 Leak state (0: No Leak, 1: Leak)
      water1leak_text:                         # Water 1 Leak state text
        case water1leak do
          0 -> "No Leak"
          1 -> "Leak"
        end,
      water2leak: water2leak,                  # Water 2 Leak state (0: No Leak, 1: Leak)
      water2leak_text:                         # Water 2 Leak state text
        case water2leak do
          0 -> "No Leak"
          1 -> "Leak"
        end
    }
  end

  def parse(payload, meta) do
    Logger.info("Unhandled meta.frame_port: #{inspect get_in(meta, [:meta, :frame_port])} with payload #{inspect payload}")
    []
  end

  # define the names for Device types
  def device_type_name(0x01), do: "R711 Indoor Temperature Humidity Sensor"
  def device_type_name(0x02), do: "R311A Door/Window Sensor"
  def device_type_name(0x03), do: "RB11E Occupancy/Light/Temperature Sensor"
  def device_type_name(0x04), do: "R311G Light Sensor"
  def device_type_name(0x05), do: "RA07"
  def device_type_name(0x06), do: "R311W Water leak Sensor"
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
        field: "devtype",
        display: "Device Type",
      },
      %{
        field: "devtype_name",
        display: "Device Type Name",
      },
      %{
        field: "reptype",
        display: "Report Type",
      },
      %{
        field: "lowbat",
        display: "Low Battery",
      },
      %{
        field: "bat",
        display: "Battery Voltage",
        unit: "V",
      },
      %{
        field: "sversion",
        display: "Software Version",
      },
      %{
        field: "hwversion",
        display: "Hardware Version",
      },
      %{
        field: "datecode",
        display: "Manufacture Date",
      },

      # Light Sensors: R311G, R311B
      %{
        field: "lux",
        display: "Illuminance",
        unit: "lux",
      },

      # Water Leak Sensors: R311W, R718WB, R718WA, R718WA2, R718WB2
      %{
        field: "water1leak",
        display: "Water 1 Leak",
      },
      %{
        field: "water2leak",
        display: "Water 2 Leak",
      }
    ]
  end


  #--------- Tests

  def tests() do
    [
      # Rep Type 0
      {
        :parse_hex,
        "0104000A0B201811190000",
        %{meta: %{frame_port: 6}},
        %{
          datecode: "20181119",
          devtype: 4,
          devtype_name: "R311G Light Sensor",
          hwversion: "V1.1",
          reptype: 0,
          sversion: "V1.0",
          version: 1
        },
      },

      # Rep Type 1 (R311G)
      {
        :parse_hex,
        "0104012000360000000000",
        %{meta: %{frame_port: 6}},
        %{
          bat: 3.2,
          devtype: 4,
          devtype_name: "R311G Light Sensor",
          lowbat: 0,
          lux: 54,
          reptype: 1,
          version: 1
        },
      },

      # Rep Type 1 (R311W)
      {
        :parse_hex,
        "0106012000010000000000",
        %{meta: %{frame_port: 6}},
        %{
          bat: 3.2,
          devtype: 6,
          devtype_name: "R311W Water leak Sensor",
          lowbat: 0,
          reptype: 1,
          version: 1,
          water1leak: 0,
          water1leak_text: "No Leak",
          water2leak: 1,
          water2leak_text: "Leak"
        },
      },
    ]
  end

end