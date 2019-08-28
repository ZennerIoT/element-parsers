defmodule Parser do
  use Platform.Parsing.Behaviour

  require Logger

  # ELEMENT IoT Parser for NAS Cyble Module CM3030 LoRaWAN
  #
  # Product:
  #   https://www.nasys.no/product/lorawan-itron-module/
  #
  # Documentation:
  #   https://www.nasys.no/wp-content/uploads/Cyble_Module_CM3030_2.pdf
  #
  # Changelog
  #   2019-08-26 [jb]: Initial version
  #
  # LoRaWAN Frame-Ports:
  #   14: Water Usage - Implemented
  #   24: Status - Implemented
  #   50: Config
  #   99: Boot/Debug - Implemented

  # Status Message
  def parse(<<usage_counter::32-little, _rest::binary>>, %{meta: %{frame_port: 14}}) do
    %{
      type: :usage,
      usage_counter: usage_counter, # Liter Count
    }
  end

  # Status Message
  def parse(<<usage_counter::32-little, battery, temp::signed, _rfu, status::binary-1, _rest::binary>>, %{meta: %{frame_port: 24}}) do
    <<is_alert::1, user_triggered::1, _::3, temp_detection::1, _::2>> = status
    %{
      type: :status,
      alert: is_alert,
      user_triggered: user_triggered,
      temperature_detection: temp_detection,
      usage_counter: usage_counter, # Liter Count
      battery: (battery * 16) / 1000, # mV => V
      temperature: temp,
    }
  end

  # Boot Message
  def parse(<<0x00, serial::4-binary, firmware::3-binary, reset_reason, _rest::binary>>, %{meta: %{frame_port:  99}}) do
    <<major::8, minor::8, patch::8>> = firmware
    %{
      type: :boot,
      serial: Base.encode16(serial),
      firmware: "#{major}.#{minor}.#{patch}",
      reset_reason: reset_reason(reset_reason),
    }
  end


  # Catchall for any other message.
  def parse(payload, meta) do
    Logger.info("Unknown payload #{inspect payload} and frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  defp reset_reason(0x10), do: :calibration_timeout
  defp reset_reason(0x31), do: :user_magnet
  defp reset_reason(reason), do: "unknown_#{reason}"

  def fields() do
    [
      %{
        "field" => "type",
        "display" => "Messagetype",
      },
      %{
        "field" => "temperature",
        "display" => "Temperatur",
        "unit" => "°C"
      },
      %{
        "field" => "usage_counter",
        "display" => "Verbrauch",
        "unit" => "l"
      },
      %{
        "field" => "battery",
        "display" => "Battery",
        "unit" => "mV"
      },
      %{
        "field" => "alert",
        "display" => "Alarm",
      },
    ]
  end

  def tests() do
    [
      {
        # Water usage
        :parse_hex,
        "800A0000",
        %{meta: %{frame_port: 14}},
        %{type: :usage, usage_counter: 2688},
      },

      {
        # Status
        :parse_hex,
        "53000000 59 13 83 1000 4D070707860770072B07AA07570711078F0779073507B00700000003060601000000E7DE",
        %{meta: %{frame_port: 24}},
        %{
          alert: 0,
          battery: 1.424,
          temperature_detection: 0,
          temperature: 19,
          type: :status,
          usage_counter: 83,
          user_triggered: 0
        },
      },

      {
        # Status
        :parse_hex,
        "11000000 4e 24 00 0440",
        %{meta: %{frame_port: 24}},
        %{
          alert: 0,
          battery: 1.248,
          temperature_detection: 1,
          temperature: 36,
          type: :status,
          usage_counter: 17,
          user_triggered: 0
        },
      },

      {
        # Boot/Debug
        :parse_hex,
        "004500124C00021F00",
        %{meta: %{frame_port: 99}},
        %{
          firmware: "0.2.31",
          reset_reason: "unknown_0",
          serial: "4500124C",
          type: :boot
        },
      },
    ]
  end

end
