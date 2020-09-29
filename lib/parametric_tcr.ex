defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # ELEMENT IoT Parser for device Parametric TCR Radar Traffic Counter (Solar)
  #
  # Changelog:
  #   2020-07-07 [jb]: Initial implementation according to https://parametric.ch/docs/tcr/tcr_payload_v1
  #   2020-09-29 [jb]: Initial implementation according to https://parametric.ch/docs/tcr/tcr_payload_v2
  #

  # Firmware v3
  # Extended Application Payload Format (PTYPE = 2)
  def parse(<<
    0xbe, # Vendor ID, always 0xbe for Parametric Devices
    0x02, # Device Family, always 0x01 for TCR Devices
    0x01, # Payload Version, always 0x01 for V3 Payloads
    sbx_batt::8, # battery gauge when equiped with an SBX solar charger 0…100%
    sbx_pv::16, # Solar panel power when equiped with SBX 0…65535 mW

    temp::16-signed, # Device Temperature -3276.8°C –>3276.7°C

    speeds::binary, # speed classes
  >>, %{meta: %{frame_port: 15}}) do
    %{
      solar_battery: sbx_batt,
      solar_panel_power: sbx_pv,
      temperature: temp/10,
    }
    |> parse_speed_class(0, speeds)
    |> calc_totals("left")
    |> calc_totals("right")
  end
  # TCR Payload V2
  def parse(<<
    0xbe, # Vendor ID, always 0xbe for Parametric Devices
    0x02, # Device Family, always 0x01 for TCR Devices
    0x02, # Payload Version
    sbx_batt::16, # battery voltage when equiped with an SBX solar charger 0…65535mV
    sbx_pv::16, # Solar panel power when equiped with SBX 0…65535 mW

    temp::16-signed, # Device Temperature -3276.8°C –>3276.7°C

    speeds::binary, # speed classes
  >>, %{meta: %{frame_port: 15}}) do
    %{
      solar_battery_volt: sbx_batt/1000,
      solar_panel_power: sbx_pv,
      temperature: temp/10,
    }
    |> parse_speed_class(0, speeds)
    |> calc_totals("left")
    |> calc_totals("right")
  end

  # TCR Configuration Payload
  # This payload is sent once after a successful join.
  def parse(<<
    0xbe, # Vendor ID, always 0xbe for Parametric Devices
    0x02, # Device Family, always 0x01 for TCR Devices
    payload_version,
    device_type,
    fw_version::binary-3,
    operating_mode,
    device_class,
    uplink_type,
    uplink_intervall::16,
    link_check_intervall::16,
    hold_off_time::16,
    radar_sensitivity,
    ltr_lane_distance,
    rtl_lane_distance,
    sc0_start, sc0_end,
    sc1_start, sc1_end,
    sc2_start, sc2_end,
    sc3_start, sc3_end,
  >>, %{meta: %{frame_port: 190}}) when payload_version in [0x01, 0x02] do
    <<f1, f2, f3>> = fw_version

    device_type = case payload_version do
      0x01 -> Map.get(%{0 => :tcr, 1 => :tcr_s}, device_type, device_type)
      0x02 -> Map.get(%{0 => :tcr_ls, 1 => :tcr_lss, 2 => :tcr_hs, 3 => :tcr_hss}, device_type, device_type)
      _ -> :unknown
    end

    %{
      vendor_id: 0xbe,
      device_family: 0x02,
      payload_version: payload_version,

      device_type: device_type,
      firmware_version: "V#{f1}.#{f2}.#{f3}",

      operating_mode: Map.get(%{0 => :timespan, 1 => :trigger}, operating_mode, operating_mode),
      device_class: Map.get(%{0 => :a, 1 => :b, 2 => :c}, device_class, device_class),

      uplink_type: Map.get(%{0 => :unconfirmed, 1 => :confirmed}, uplink_type, uplink_type),
      uplink_intervall: uplink_intervall,

      link_check_intervall: link_check_intervall,

      hold_off_time: hold_off_time,
      radar_sensitivity: radar_sensitivity,

      ltr_lane_distance: ltr_lane_distance,
      rtl_lane_distance: rtl_lane_distance,

      speed_class0_start: sc0_start,
      speed_class0_end: sc0_end,

      speed_class1_start: sc1_start,
      speed_class1_end: sc1_end,

      speed_class2_start: sc2_start,
      speed_class2_end: sc2_end,

      speed_class3_start: sc3_start,
      speed_class3_end: sc3_end,
    }
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  defp parse_speed_class(row, index, <<l_cnt::16, l_avg::8, r_cnt::16, r_avg::8, rest::binary>>) do
    row
    |> Map.merge(%{
      "left_count_class#{index}" => l_cnt,
      "left_avg_class#{index}" => l_avg,
      "right_count_class#{index}" => r_cnt,
      "right_avg_class#{index}" => r_avg,
    })
    |> parse_speed_class(index+1, rest)
  end
  defp parse_speed_class(row, _index, <<>>), do: row
  defp parse_speed_class(row, _index, rest) do
    row
    |> Map.merge(%{
      "speeds_invalid_binary" => inspect(rest),
    })
  end

  defp calc_totals(row, direction) do
    total_count = Map.get(row, "#{direction}_count_class0", 0) + Map.get(row, "#{direction}_count_class1", 0) + Map.get(row, "#{direction}_count_class2", 0) + Map.get(row, "#{direction}_count_class3", 0)

    total_avg = (Map.get(row, "#{direction}_count_class0", 0) * Map.get(row, "#{direction}_avg_class0", 0) + Map.get(row, "#{direction}_count_class1", 0) * Map.get(row, "#{direction}_avg_class1", 0) + Map.get(row, "#{direction}_count_class2", 0) * Map.get(row, "#{direction}_avg_class2", 0) + Map.get(row, "#{direction}_count_class3", 0) * Map.get(row, "#{direction}_avg_class3", 0))

    total_avg = case total_count do
      0 -> 0 # Avoid divide by zero
      _ -> total_avg / total_count
    end

    Map.merge(row, %{
      "#{direction}_count" => total_count,
      "#{direction}_avg" => total_avg,
    })
  end

  # Define fields with human readable name and a SI unit if available.
  def fields() do
    [
      # The first field should be a numeric value, so it can be used for graphs.
      %{
        field: "left_count",
        display: "Left Count",
      },
      %{
        field: "right_count",
        display: "Right Count",
      },

      %{
        field: "left_avg",
        display: "Left Speed Avg",
        unit: "km/h",
      },
      %{
        field: "right_avg",
        display: "Right Speed Avg",
        unit: "km/h",
      },


      %{
        field: "temperature",
        display: "Temperature",
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
        field: "solar_battery_volt",
        display: "Solar Battery",
        unit: "V",
      },
      %{
        field: "solar_panel_power",
        display: "Solar Panel Power",
        unit: "mW",
      },
    ] ++ Enum.flat_map(0..3, fn(i) ->
      [
        %{
          field: "left_count_class#{i}",
          display: "Left Count Class#{i}",
        },
        %{
          field: "right_count_class#{i}",
          display: "Right Count Class#{i}",
        },
        %{
          field: "left_avg_class#{i}",
          display: "Left Speed Avg Class#{i}",
          unit: "km/h",
        },
        %{
          field: "right_avg_class#{i}",
          display: "Right Speed Avg Class#{i}",
          unit: "km/h",
        },
      ]
    end)
  end

  def tests() do
    [
      {
        :parse_hex,
        "be02016412c218b800000000010600000000020b00000000011e000000000000",
        %{
          meta: %{frame_port: 15},
          _comment: "payload v1",
        },
        %{
          :solar_battery => 100,
          :solar_panel_power => 4802,
          :temperature => 632.8,
          "left_avg" => 0,
          "left_avg_class0" => 0,
          "left_avg_class1" => 0,
          "left_avg_class2" => 0,
          "left_avg_class3" => 0,
          "left_count" => 0,
          "left_count_class0" => 0,
          "left_count_class1" => 0,
          "left_count_class2" => 0,
          "left_count_class3" => 0,
          "right_avg" => 14.5,
          "right_avg_class0" => 6,
          "right_avg_class1" => 11,
          "right_avg_class2" => 30,
          "right_avg_class3" => 0,
          "right_count" => 4,
          "right_count_class0" => 1,
          "right_count_class1" => 2,
          "right_count_class2" => 1,
          "right_count_class3" => 0
        }
      },

      {
        :parse_hex,
        "be020100010000000000000305a00000640000010708191a313278",
        %{
          meta: %{frame_port: 190},
          _comment: "config v1",
        },
        %{
          device_class: :a,
          device_family: 2,
          device_type: :tcr,
          firmware_version: "V1.0.0",
          hold_off_time: 0,
          link_check_intervall: 1440,
          ltr_lane_distance: 0,
          operating_mode: :timespan,
          payload_version: 1,
          radar_sensitivity: 100,
          rtl_lane_distance: 0,
          speed_class0_end: 7,
          speed_class0_start: 1,
          speed_class1_end: 25,
          speed_class1_start: 8,
          speed_class2_end: 49,
          speed_class2_start: 26,
          speed_class3_end: 120,
          speed_class3_start: 50,
          uplink_intervall: 3,
          uplink_type: :unconfirmed,
          vendor_id: 190
        }
      },

      {
        :parse_hex,
        "be0202646412c218b800000000010600000000020b00000000011e000000000000",
        %{
          meta: %{frame_port: 15},
          _comment: "payload v2",
        },
        %{
          :solar_battery_volt => 25.7,
          :solar_panel_power => 4802,
          :temperature => 632.8,
          "left_avg" => 0,
          "left_avg_class0" => 0,
          "left_avg_class1" => 0,
          "left_avg_class2" => 0,
          "left_avg_class3" => 0,
          "left_count" => 0,
          "left_count_class0" => 0,
          "left_count_class1" => 0,
          "left_count_class2" => 0,
          "left_count_class3" => 0,
          "right_avg" => 14.5,
          "right_avg_class0" => 6,
          "right_avg_class1" => 11,
          "right_avg_class2" => 30,
          "right_avg_class3" => 0,
          "right_count" => 4,
          "right_count_class0" => 1,
          "right_count_class1" => 2,
          "right_count_class2" => 1,
          "right_count_class3" => 0
        }
      },

      {
        :parse_hex,
        "be020200010000000000000305a00000640000010708191a313278 ",
        %{
          meta: %{frame_port: 190},
          _comment: "config v2",
        },
        %{
          device_class: :a,
          device_family: 2,
          device_type: :tcr_ls,
          firmware_version: "V1.0.0",
          hold_off_time: 0,
          link_check_intervall: 1440,
          ltr_lane_distance: 0,
          operating_mode: :timespan,
          payload_version: 2,
          radar_sensitivity: 100,
          rtl_lane_distance: 0,
          speed_class0_end: 7,
          speed_class0_start: 1,
          speed_class1_end: 25,
          speed_class1_start: 8,
          speed_class2_end: 49,
          speed_class2_start: 26,
          speed_class3_end: 120,
          speed_class3_start: 50,
          uplink_intervall: 3,
          uplink_type: :unconfirmed,
          vendor_id: 190
        }
      },
    ]
  end
end
