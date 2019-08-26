defmodule Parser do
  use Platform.Parsing.Behaviour

  require Logger

  # ELEMENT IoT Parser for NAS BK-G Pulse Reader CM3060 LoRaWAN
  #
  # Product:
  #   https://www.nasys.no/product/lorawan-pulse-bk-g-reader/
  #
  # Documentation:
  #   https://www.nasys.no/wp-content/uploads/BK_G_Pulse_Reader_cm3060-1.pdf
  #
  # Changelog
  #   2019-08-26 [jb]: Initial version
  #
  # LoRaWAN Frame-Ports:
  #   24: Status - Implemented
  #   25: Usage - Implemented
  #   49: Config Request
  #   50: Config
  #   51: Update mode
  #   99: Boot/Debug - Implemented

  # Status message
  def parse(<<0x03, _battery_mapped, temperature::signed, _rssi, _dontknow, usage::binary-5, alert::binary-5, _rest::binary>>, %{meta: %{frame_port:  24}}) do
    %{
      type: :status,
      temperature: temperature,
    }
    |> Map.merge(parse_usage(usage))
    |> Map.merge(parse_alert(alert))
  end

  # Usage message
  def parse(<<0x03, usage::binary-5, alert::binary-5, _rest::binary>>, %{meta: %{frame_port:  25}}) do
    %{
      type: :usage,
    }
    |> Map.merge(parse_usage(usage))
    |> Map.merge(parse_alert(alert))
  end

  # Boot Message
  def parse(<<0x00, serial::4-binary, firmware::3-binary, reset_reason, _battery_info, _rest::binary>>, %{meta: %{frame_port:  99}}) do
    <<major::8, minor::8, patch::8>> = firmware
    %{
      type: :boot,
      serial: Base.encode16(serial),
      firmware: "#{major}.#{minor}.#{patch}",
      reset_reason: reset_reason(reset_reason),
      #battery_voltage: Map.get(%{0x01 => "3.0V", 0x02 => "3.6V"}, battery_info, :unknown), # Does not seem to be correct
    }
  end
  # Shutdown Message
  def parse(<<0x01, reset_reason, _regular_status_message::binary>>, %{meta: %{frame_port:  99}}) do
    # TODO: Handle _regular_status_message
    %{
      type: :shutdown,
      reset_reason: reset_reason(reset_reason),
    }
  end

  # Catchall for any other message.
  def parse(payload, meta) do
    Logger.info("Unknown payload #{inspect payload} and frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  defp parse_usage(<<0x04::4, _::2, 0::1, value_during_reporting_usage::1, usage_counter::32-little>>) do
    %{
      medium_type: :gas_liter,
      usage_mode: :counter,
      usage_counter: usage_counter,
      usage_during_reporting: value_during_reporting_usage,
    }
  end

  defp parse_alert(<<0x01::4, _::1, is_alert::1, 1::1, value_during_reporting_alert::1, alert_counter::32-little>>) do
    %{
      alert_during_reporting: value_during_reporting_alert,
      alert: is_alert,
      alert_counter: alert_counter,
    }
  end

  defp reset_reason(0x02), do: :watchdog_reset
  defp reset_reason(0x24), do: :soft_reset
  defp reset_reason(0x10), do: :normal_magnet
  defp reset_reason(0x20), do: :hardware_error
  defp reset_reason(0x31), do: :user_magnet
  defp reset_reason(0x32), do: :user_dfu
  defp reset_reason(_), do: :unknown

  def fields() do
    [
      %{
        "field" => "type",
        "display" => "Messagetype",
      },
      %{
        "field" => "medium_type",
        "display" => "Mediumtype",
      },
      %{
        "field" => "temperature",
        "display" => "Temperatur",
        "unit" => "°C"
      },
      %{
        "field" => "usage_mode",
        "display" => "Verbrauchsart",
      },
      %{
        "field" => "usage_counter",
        "display" => "Verbrauch",
      },
      %{
        "field" => "alert",
        "display" => "Alarm",
      },
      %{
        "field" => "alert_counter",
        "display" => "Alarmcounter",
      },
    ]
  end

  def tests() do
    [
      {
        # Status message
        :parse_hex,
        "03 71 18 01 63 40 5E970000 12 00000000",
        %{meta: %{frame_port: 24}},
        %{
          alert: 0,
          alert_counter: 0,
          alert_during_reporting: 0,
          medium_type: :gas_liter,
          temperature: 24,
          type: :status,
          usage_counter: 38750,
          usage_during_reporting: 0,
          usage_mode: :counter
        },
      },

      {
        # Usage message
        :parse_hex,
        "03 40 5E970000 12 00000000",
        %{meta: %{frame_port: 25}},
        %{
          alert: 0,
          alert_counter: 0,
          alert_during_reporting: 0,
          medium_type: :gas_liter,
          type: :usage,
          usage_counter: 38750,
          usage_during_reporting: 0,
          usage_mode: :counter
        },
      },

      {
        # Boot message
        :parse_hex,
        "0045001B4E000802100005",
        %{meta: %{frame_port: 99}},
        %{
          firmware: "0.8.2",
          reset_reason: :normal_magnet,
          serial: "45001B4E",
          type: :boot
        },
      },
    ]
  end

end
