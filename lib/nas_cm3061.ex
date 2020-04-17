defmodule Parser do
  use Platform.Parsing.Behaviour

  require Logger

  # ELEMENT IoT Parser for NAS LoRaWAN PULSER BK-G CM3061
  #
  # Product:
  #   https://www.nasys.no/product/lorawan-bk-g-pulse-reader/
  #
  # Documentation:
  #   https://www.nasys.no/wp-content/uploads/LoRaWAN-PULSER-BK-G_CM3061.pdf
  #
  # Changelog
  #   2020-04-17 [jb]: Initial version
  #
  # LoRaWAN Frame-Ports:
  #   24: Status
  #   25: Usage
  #   49: Configuration Request
  #   50: Configuration
  #   99: System packets
  #
  # DOWN Messages:
  #   Configuration
  #     reporting_config_packet
  #       "00 02 3C000000" and Port 50 => Usage jede 60 Minuten
  #       "00 02 A0050000" and Port 50 => Usage jede 24 Stunden
  #

  # Status message
  def parse(<<0x01,_rest::binary>> = payload, %{meta: %{frame_port:  24}}) do
    parse_status_payload(payload)
  end

  # Usage message
  def parse(<<0x01, general::binary-1, counter::32-little>>, %{meta: %{frame_port:  25}}) do
    <<_::5, usage_detected::1, _::bits>> = general
    %{
      type: :usage,
      usage_detected: usage_detected,
    }
    |> add_counter(counter)
  end

  # Configuration message - reporting_config_packet
  def parse(<<0x00, configured_params::binary-1, rest::binary>>, %{meta: %{frame_port: 50}}) do
    <<_::5, behaviour::1, status::1, usage::1>> = configured_params

    row = %{
      type: :reporting_config_packet,
    }

    {row, rest} = case usage do
      1 ->
        <<usage_interval::16-little, rest::binary>> = rest
        row = Map.merge(row, %{usage_interval: usage_interval})
        {row, rest}
      0 ->
        {row, rest}
    end

    {row, rest} = case status do
      1 ->
        <<status_interval::16-little, rest::binary>> = rest
        row = Map.merge(row, %{status_interval: status_interval})
        {row, rest}
      0 ->
        {row, rest}
    end

    {row, _rest} = case behaviour do
      1 ->
        <<send_usage::1, _::bits>> = rest
        row = Map.merge(row, %{send_usage: %{0 => :only_when_new_data, 1 => :always}[send_usage]})
        {row, rest}
      0 ->
        {row, rest}
    end

    row
  end

  # Configuration message - metering_config_packet
  def parse(<<0x05, configured_params::binary-1, rest::binary>>, %{meta: %{frame_port: 50}}) do
    <<_::3, meter_serial::1, _::1, reading_offset::1, reading_absolute::1, general_config::1>> = configured_params

    row = %{
      type: :metering_config_packet,
    }

    {row, rest} = case general_config do
      1 ->
        <<_::5, exponent::3, rest::binary>> = rest
        case exponent do
          1 -> {Map.merge(row, %{units_per_pulse: 1}), rest}
          2 -> {Map.merge(row, %{units_per_pulse: 10}), rest}
          3 -> {Map.merge(row, %{units_per_pulse: 100}), rest}
          4 -> {Map.merge(row, %{units_per_pulse: 1000}), rest}
          _ -> {row, rest}
        end
      0 ->
        {row, rest}
    end

    {row, rest} = case reading_absolute do
      1 ->
        <<absolute_reading::32-little, rest::binary>> = rest
        row = Map.merge(row, %{absolute_reading: absolute_reading})
        {row, rest}
      0 ->
        {row, rest}
    end

    {row, rest} = case reading_offset do
      1 ->
        <<offset::16-signed-little, rest::binary>> = rest
        row = Map.merge(row, %{offset: offset})
        {row, rest}
      0 ->
        {row, rest}
    end

    {row, _rest} = case meter_serial do
      1 ->
        case rest do
          <<0xFFFFFFFF::32, rest::binary>> ->
            {row, rest}
          <<meter_id::32-little, rest::binary>> ->
            row = Map.merge(row, %{meter_id: meter_id})
            {row, rest}
        end
      0 ->
        {row, rest}
    end

    row
  end

  def parse(<<0x10, _rest::binary>>, %{meta: %{frame_port: 50}}) do
    %{
      type: :meta_pos_config_request,
    }
  end

  def parse(<<0x11, _rest::binary>>, %{meta: %{frame_port: 50}}) do
    %{
      type: :meta_eic_config_request,
    }
  end

  # Boot Message
  def parse(<<0x00, serial::4-binary, firmware::3-binary,
    reset_reason, general_info::binary-1,
    _hardware_config, sensor_fw_version::16-little,
    device_uptime::24>>, %{meta: %{frame_port:  99}}) do
    <<major::8, minor::8, patch::8>> = firmware
    <<config_restored::1, _::1, wakeup_from_dfu::1, _::bits>> = general_info
    %{
      type: :boot,
      serial: Base.encode16(serial),
      firmware: "#{major}.#{minor}.#{patch}",
      reset_reason: reset_reason(reset_reason),
      sensor_fw_version: sensor_fw_version,
      device_uptime: device_uptime,
      config_restored: config_restored,
      wakeup_from_dfu: wakeup_from_dfu,
    }
  end

  # Shutdown Message
  def parse(<<0x01, shutdown_reason, last_status_packet::binary>>, %{meta: %{frame_port:  99}}) do
    last_status_packet
    |> parse_status_payload()
    |> Map.merge(%{
      type: :shutdown,
      shutdown_reason: shutdown_reason(shutdown_reason),
    })
  end

  # Config failed
  def parse(<<0x13, packet_from_fport, parse_error_code>>, %{meta: %{frame_port:  99}}) do
    %{
      type: :config_failed_packet,
      packet_from_fport: packet_from_fport,
      parse_error_code: parse_error_code,
      parse_error: case parse_error_code do
        2 -> :unknown_fport
        3 -> :packet_size_short
        4 -> :packet_size_long
        5 -> :value_error
        6 -> :protocol_parse_error
        7 -> :reserved_flag_set
        8 -> :invalid_flag_combination
        9 -> :unavailable_feature_request
        10 -> :unsupported_header
        11 -> :unreachable_hw_request
        13 -> :internal_error
        _ -> :unknown
      end,
    }
  end

  # Catchall for any other message.
  def parse(payload, meta) do
    Logger.info("Unknown payload #{inspect payload} and frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  def parse_status_payload(<<
    0x01,
    general::binary-1,
    active_alerts::binary-1,
    battery_percent, battery_offset,
    temperature::signed, _temp_offset::binary-1,
    downlink::binary-2,
    counter::32-little,
    _rest::binary>>) do
    <<_::4, tamper::1, _::bits>> = active_alerts
    <<rssi, snr::signed>> = downlink
    %{
      type: :status,
      packet_reason: packet_reason(general),
      tamper: tamper,
      battery_offset: battery_offset,
      temperature: temperature,
      counter: counter,
      downlink_rssi: rssi * -1,
      downlink_snr: snr,
    }
    |> add_battery_percent(battery_percent)
    |> add_counter(counter)
  end

  defp shutdown_reason(0x10), do: :calibration_timeout
  defp shutdown_reason(0x20), do: :hardware_error
  defp shutdown_reason(0x31), do: :magnet_shutdown
  defp shutdown_reason(0x32), do: :enter_dfu
  defp shutdown_reason(0x33), do: :app_shutdown
  defp shutdown_reason(0x34), do: :switch_to_wmbus
  defp shutdown_reason(_), do: :unknown

  defp packet_reason(<<_::2, 1::1, _::bits>>), do: :app
  defp packet_reason(<<_::1, 1::1, _::bits>>), do: :magnet
  defp packet_reason(<<_::0, 1::1, _::bits>>), do: :alert
  defp packet_reason(_), do: :unknown

  defp add_battery_percent(row, 255), do: row
  defp add_battery_percent(row, value), do: Map.merge(row, %{battery_percent: trunc(value/254)})

  defp add_counter(row, 0xFFFFFFFF), do: row
  defp add_counter(row, value), do: Map.merge(row, %{counter: value, volume: value/1000})

  defp reset_reason(0b00000010), do: :watchdog_reset
  defp reset_reason(0b00000100), do: :soft_reset
  defp reset_reason(0b00010000), do: :magnet_wakeup
  defp reset_reason(0b10000000), do: :nfc_wakeup
  defp reset_reason(_), do: :unknown

  def fields() do
    [
      %{
        "field" => "counter",
        "display" => "Usage in l",
        "unit" => "l",
      },
      %{
        "field" => "volume",
        "display" => "Volume in m³",
        "unit" => "m3",
      },

      %{
        "field" => "type",
        "display" => "Messagetype",
      },
      %{
        "field" => "tamper",
        "display" => "Tamper",
      },

      %{
        "field" => "temperature",
        "display" => "Temperatur",
        "unit" => "°C"
      },

      %{
        "field" => "downlink_rssi",
        "display" => "Downlink RSSI",
        "unit" => "dBm",
      },
      %{
        "field" => "downlink_snr",
        "display" => "Downlink SNR",
        "unit" => "Bm",
      },

      %{
        "field" => "usage_interval",
        "display" => "Usage Interval",
        "unit" => "min",
      },
      %{
        "field" => "status_interval",
        "display" => "Status Interval",
        "unit" => "min",
      },

      %{
        "field" => "absolute_reading",
        "display" => "Absolute Reading",
        "unit" => "l",
      },
      %{
        "field" => "offset",
        "display" => "Offset Reading",
        "unit" => "l",
      },
      %{
        "field" => "units_per_pulse",
        "display" => "Units per Pulse",
        "unit" => "l",
      },

      %{
        "field" => "device_uptime",
        "display" => "Uptime",
        "unit" => "h",
      },
    ]
  end

  def tests() do
    [
      {
        # Status message
        :parse_hex,
        "018008FF9212005207A0000000", # 010000FF110E0082F606447400
        %{meta: %{frame_port: 24}},
        %{
          battery_offset: 146,
          counter: 160,
          downlink_rssi: -82,
          downlink_snr: 7,
          packet_reason: :alert,
          tamper: 1,
          temperature: 18,
          type: :status,
          volume: 0.16

        },
      },

      {
        # Usage message
        :parse_hex,
        "010468010000",
        %{meta: %{frame_port: 25}},
        %{counter: 360, type: :usage, usage_detected: 1, volume: 0.36},
      },

      {
        # Configuration message
        :parse_hex,
        "0005780000",
        %{meta: %{frame_port: 50}},
        %{
          send_usage: :only_when_new_data,
          type: :reporting_config_packet,
          usage_interval: 120
        },
      },
      {
        # Configuration message
        :parse_hex,
        "00076801A00501",
        %{meta: %{frame_port: 50}},
        %{
          send_usage: :only_when_new_data,
          status_interval: 1440,
          type: :reporting_config_packet,
          usage_interval: 360
        },
      },
      {
        # Configuration message
        :parse_hex,
        "05 13 02 625C0000 BB6D0E02",
        %{meta: %{frame_port: 50}},
        %{
          absolute_reading: 23650,
          meter_id: 34500027,
          type: :metering_config_packet,
          units_per_pulse: 10
        },
      },

      {
        # Boot message
        :parse_hex,
        "00FA0110500102068000200000000000",
        %{meta: %{frame_port: 99}},
        %{
          config_restored: 0,
          device_uptime: 0,
          firmware: "1.2.6",
          reset_reason: :nfc_wakeup,
          sensor_fw_version: 0,
          serial: "FA011050",
          type: :boot,
          wakeup_from_dfu: 0
        },
      },

      {
        # Shutdown message
        :parse_hex,
        "0132010000FF1110004F0701000000000000",
        %{meta: %{frame_port: 99}},
        %{
          battery_offset: 17,
          counter: 1,
          downlink_rssi: -79,
          downlink_snr: 7,
          packet_reason: :unknown,
          shutdown_reason: :enter_dfu,
          tamper: 0,
          temperature: 16,
          type: :shutdown,
          volume: 0.001
        },
      },

      {
        # Shutdown message
        :parse_hex,
        "13330A",
        %{meta: %{frame_port: 99}},
        %{
          packet_from_fport: 51,
          parse_error: :unsupported_header,
          parse_error_code: 10,
          type: :config_failed_packet
        },
      },

    ]
  end

end
