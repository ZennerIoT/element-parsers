defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # ELEMENT IoT Parser for device Parametric PCR2 People Counter Radar Peopleflow Sensor
  #
  # This Parser supports PCR2-IN indoor and PCR2-OD outdoor in Firmware version 2 and 3 in Extended (PTYPE=2) and ELSYS (PTYPE=0) payload format.
  # For Cayenne LPP (PTYPE=1) payload format use the dedicated parser for that universal payload format.
  #
  # Changelog:
  #   2020-06-09 [jb]: Initial implementation according to https://parametric.ch/docs/pcr2/pcr2_app_payloads_v2
  #   2020-07-07 [jb]: Implemented v3 according to https://parametric.ch/docs/pcr2/pcr2_app_payloads_v3, renamed field temperature to cpu_temp
  #

  # Firmware v3
  # Extended Application Payload Format (PTYPE = 2)
  def parse(<<
    0xbe, # Vendor ID, always 0xbe for Parametric Devices
    0x01, # Device Family, always 0x01 for PCR2 Devices
    0x03, # Payload Version, always 0x03 for V3 Payloads
    ltr::16, # left-to-right counter
    rtl::16, # right-to-left counter
    ltr_sum::16, # sum of left-to-right counts since device power up
    rtl_sum::16, # sum of right-to-left counts since device power up
    sbx_batt::8, # battery gauge when equiped with an SBX solar charger 0…100%
    sbx_pv::16, # Solar panel power when equiped with SBX 0…65.535 mW
    cpu_temp::16-signed # CPU Temperature -3276.8°C –>3276.7°C
  >>, %{meta: %{frame_port: 14}}) do
    %{
      left_to_right: ltr,
      right_to_left: rtl,
      left_to_right_sum: ltr_sum,
      right_to_left_sum: rtl_sum,
      solar_battery: sbx_batt,
      solar_panel_power: sbx_pv,
      cpu_temp: cpu_temp/10,
    }
  end
  # Firmware v3
  # ELSYS Application Payload Format (PTYPE = 0)
  def parse(<<0x0a, ltr::16, 0x0a, rtl::16, 0x01, temp::signed-16>>, %{meta: %{frame_port: 14}}) do
    %{
      left_to_right: ltr,
      right_to_left: rtl,
      cpu_temp: temp/10
    }
  end

  # Firmware v2
  # PCR2 is sending 9 bytes of hex encoded data on port 14
  # after interval time expired or after a trigger event (trigger mode only).
  def parse(<<0x0a, ltr::16, 0x16, rtl::16, 0x01, temp::signed-16>>, %{meta: %{frame_port: 14}}) do
    %{
      left_to_right: ltr,
      right_to_left: rtl,
      cpu_temp: temp/10
    }
  end

  # Firmware v2
  # Directly after a join, the device is sending a configuration payload once using port 190.
  def parse(<<type, fw1, fw2, fw3, mode, payload_type, confirmed, interval::16, lci::16, hot::16, radar_sens::8>>, %{meta: %{frame_port: 190}}) do
    payload_type = case payload_type do
      0 -> :parametric
      1 -> :cayennelp
      _ -> :unknown
    end

    confirmed = case confirmed do
      0 -> :disabled
      1 -> :enabled
      _ -> :unknown
    end

    %{
      device_type: type,
      firmware_version: "V#{fw1}.#{fw2}.#{fw3}",
      operation_mode: mode,
      payload_type: payload_type,
      confirmed_uplinks: confirmed,
      measurement_interval: interval,
      linkcheck_interval: lci,
      hold_off_time: hot,
      radar_sensitivity: radar_sens,
    }
  end

  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  # Define fields with human readable name and a SI unit if available.
  def fields() do
    [
      # The first field should be a numeric value, so it can be used for graphs.
      %{
        field: "left_to_right",
        display: "Left to Right",
      },
      %{
        field: "right_to_left",
        display: "Right to Left",
      },

      %{
        field: "left_to_right_sum",
        display: "Left to Right Summe",
      },
      %{
        field: "right_to_left_sum",
        display: "Right to Left Summe",
      },

      %{
        field: "cpu_temp",
        display: "CPU Temperature",
        unit: "°C",
      },
      %{
        field: "measurement_interval",
        display: "Measurement Interval",
        unit: "min",
      },
      %{
        field: "linkcheck_interval",
        display: "LinkCheck Interval",
        unit: "min",
      },
      %{
        field: "hold_off_time",
        display: "Hold Off Time",
        unit: "s",
      },
      %{
        field: "radar_sensitivity",
        display: "Radar Sensitivity",
        unit: "%",
      },

      %{
        field: "solar_battery",
        display: "Solar Battery",
        unit: "%",
      },
      %{
        field: "solar_panel_power",
        display: "Solar Panel Power",
        unit: "mW",
      },
    ]
  end

  def tests() do
    [
      # v2 firmware
      {
        :parse_hex,
        "0A000016000001013C",
        %{meta: %{frame_port: 14}},
        %{left_to_right: 0, right_to_left: 0, cpu_temp: 31.6}
      },
      {
        :parse_hex,
        "0A0002160001010139",
        %{meta: %{frame_port: 14}},
        %{left_to_right: 2, right_to_left: 1, cpu_temp: 31.3}
      },
      {
        :parse_hex,
        "0A001016001301FF9A",
        %{meta: %{frame_port: 14}},
        %{left_to_right: 16, right_to_left: 19, cpu_temp: -10.2}
      },

      {
        :parse_hex,
        "00030000000001000A05A0000064",
        %{meta: %{frame_port: 190}},
        %{
          confirmed_uplinks: :enabled,
          device_type: 0,
          firmware_version: "V3.0.0",
          hold_off_time: 0,
          linkcheck_interval: 1440,
          measurement_interval: 10,
          operation_mode: 0,
          payload_type: :parametric,
          radar_sensitivity: 100
        }
      },

      # v3 firmware, extended
      {
        :parse_hex,
        "be 01 03 00 00 00 00 00 01 00 00 64 0c e4 01 39",
        %{meta: %{frame_port: 14}},
        %{
          cpu_temp: 31.3,
          left_to_right: 0,
          left_to_right_sum: 1,
          right_to_left: 0,
          right_to_left_sum: 0,
          solar_battery: 100,
          solar_panel_power: 3300
        }
      },
      # v3 firmware, short
      {
        :parse_hex,
        "0A00020A0001010139",
        %{meta: %{frame_port: 14}},
        %{left_to_right: 2, right_to_left: 1, cpu_temp: 31.3}
      },
    ]
  end
end
