defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Strega Smart Valve
  # According to documentation v3.0 and V4.0 provided by Strega
  # Link: http://www.stregatechnologies.com/products/wireless-smart-valve/
  #
  # Changelog
  #   2018-09-13 [as]: Initial version.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #   2020-06-12 [jb]: Supporting v4 Payloads, RENAMED READING FIELDS!
  #   2021-04-23 [jb]: Added hint for custom payloads from FULL devices.
  #   2021-07-01 [jb]: Processing payloads for LITE and FULL device models.
  #   2021-07-12 [jb]: Fixed parsing of FULL payloads. Formatted code.
  #

  # v3 payload
  def parse(<<bat_mv::binary-4, flags::binary-1>>, _meta) do
    %{payload_version: :v3}
    |> parse_flags(flags, :v3)
    |> parse_bat_mv(bat_mv, :v3)
  end

  # v4 payload
  def parse(<<bat_mv::binary-4, flags::binary-1, suffix::binary>>, %{meta: %{frame_port: 4}}) do
    %{
      payload_version: :v4
      # Not documented what is at the end of some payloads ...
      # payload_suffix: Base.encode16(suffix)
    }
    |> parse_flags(flags, :v4)
    |> parse_bat_mv(bat_mv, :v4)
    |> parse_v4_suffix(suffix)
  end

  def parse(payload, meta) do
    Logger.warn(
      "Could not parse payload #{inspect(payload)} with frame_port #{
        inspect(get_in(meta, [:meta, :frame_port]))
      }"
    )

    []
  end

  defp parse_v4_suffix(row, <<0x23, temp::16, hygro::16, rest::binary>>) do
    row
    |> Map.merge(%{
      temperature: temp / 65536 * 165 - 40,
      humidity: hygro / 65536 * 100
    })
    |> parse_v4_suffix(rest)
  end

  defp parse_v4_suffix(row, <<0x43, counter::48, rest::binary>>) do
    row
    |> Map.merge(%{
      counter: counter
    })
    |> parse_v4_suffix(rest)
  end

  defp parse_v4_suffix(row, <<0x56, analog::32, rest::binary>>) do
    row
    |> Map.merge(%{
      analog: analog
    })
    |> parse_v4_suffix(rest)
  end

  defp parse_v4_suffix(row, <<ignored, rest::binary>>) when ignored in [0x23, 0x43, 0x56] do
    parse_v4_suffix(row, rest)
  end

  defp parse_v4_suffix(row, <<>>) do
    row
  end

  defp parse_v4_suffix(row, suffix) do
    Map.merge(row, %{
      payload_suffix: Base.encode16(suffix)
    })
  end

  defp parse_flags(reading, <<_::6, tamper::1, valve::1>>, :v3) do
    Map.merge(reading, %{
      valve: map_bit(valve, :close, :open),
      tamper: map_bit(tamper, :close, :open)
    })
  end

  defp parse_flags(reading, <<flags>>, :v4) do
    <<_::1, fraud::1, leak::1, di1::1, di0::1, cable::1, _::2>> = flags = <<flags - 0x30::8>>

    reading
    |> parse_flags(flags, :v3)
    |> Map.merge(%{
      cable: map_bit(cable, :disconnected, :connected),
      di_0: map_bit(di0, :off, :on),
      di_1: map_bit(di1, :off, :on),
      leakage: map_bit(leak, :no, :yes),
      fraud: map_bit(fraud, :no, :yes)
    })
  end

  defp parse_bat_mv(reading, <<_::2, pre::6, bat_mv::binary-3>>, :v3) do
    # Need to ignore the first 2 bits, because in v4 they are used too.
    Map.merge(reading, %{
      battery: String.to_integer(<<pre, bat_mv::binary-3>>) / 1000
    })
  end

  defp parse_bat_mv(reading, <<class::1, power::1, bat_mv_short::30-bits>>, :v4) do
    Map.merge(reading, %{
      battery: String.to_integer(<<0::1, 0::1, bat_mv_short::30-bits>>) / 1000,
      lorawan_class: map_bit(class, :class_a, :class_c),
      power_supply: map_bit(power, :battery, :external)
    })
  end

  defp map_bit(0, a, _b), do: a
  defp map_bit(1, _a, b), do: b

  def fields do
    [
      %{
        field: "temperature",
        display: "Temperature",
        unit: "°C"
      },
      %{
        field: "humidity",
        display: "Humidity",
        unit: "%"
      },
      %{
        field: "battery",
        display: "Battery",
        unit: "V"
      },
      %{
        field: "payload_version",
        display: "Payload Version"
      },
      %{
        field: "lorawan_class",
        display: "LoRaWAN Class"
      },
      %{
        field: "power_supply",
        display: "Power Supply"
      },
      %{
        field: "tamper",
        display: "Tamper"
      },
      %{
        field: "valve",
        display: "Valve"
      },
      %{
        field: "cable",
        display: "Cable"
      },
      %{
        field: "fraud",
        display: "Fraud"
      },
      %{
        field: "leakage",
        display: "Leakage"
      },
      %{
        field: "di_0",
        display: "DigitalInput0"
      },
      %{
        field: "di_1",
        display: "DigitalInput1"
      }
    ]
  end

  def tests() do
    [
      {
        :parse_hex,
        "3330343830",
        %{},
        %{battery: 3.048, payload_version: :v3, tamper: :close, valve: :close}
      },
      {
        :parse_hex,
        "3330313131",
        %{},
        %{battery: 3.011, payload_version: :v3, tamper: :close, valve: :open}
      },
      {
        :parse_hex,
        "3330333832",
        %{},
        %{battery: 3.038, payload_version: :v3, tamper: :open, valve: :close}
      },
      {
        :parse_hex,
        "3239323733",
        %{},
        %{battery: 2.927, payload_version: :v3, tamper: :open, valve: :open}
      },

      # v4 payload
      {
        :parse_hex,
        "33 3138 38 32 23 63 3D 77 DB",
        %{meta: %{frame_port: 4}},
        %{
          battery: 3.188,
          cable: :disconnected,
          di_0: :off,
          di_1: :off,
          fraud: :no,
          humidity: 46.81854248046875,
          leakage: :no,
          lorawan_class: :class_a,
          payload_version: :v4,
          power_supply: :battery,
          tamper: :open,
          temperature: 23.962173461914063,
          valve: :close
        }
      },
      {
        :parse_hex,
        "33 35 39 34 35 23 61 D2 81 C6",
        %{meta: %{frame_port: 4}},
        %{
          battery: 3.594,
          cable: :connected,
          di_0: :off,
          di_1: :off,
          fraud: :no,
          humidity: 50.6927490234375,
          leakage: :no,
          lorawan_class: :class_a,
          payload_version: :v4,
          power_supply: :battery,
          tamper: :close,
          temperature: 23.048248291015625,
          valve: :open
        }
      },
      {
        :parse_hex,
        "723736318E235E69893F",
        %{meta: %{frame_port: 4}},
        %{
          battery: 2.761,
          cable: :connected,
          di_0: :on,
          di_1: :on,
          fraud: :yes,
          humidity: 53.61175537109375,
          leakage: :no,
          lorawan_class: :class_a,
          payload_version: :v4,
          power_supply: :external,
          tamper: :open,
          temperature: 20.850296020507813,
          valve: :close
        }
      },
      {
        :parse_hex,
        "33 31 38 38 32 23 63 3D 77 DB",
        %{
          meta: %{frame_port: 4},
          _comment: "Lite version from docs."
        },
        %{
          battery: 3.188,
          cable: :disconnected,
          di_0: :off,
          di_1: :off,
          fraud: :no,
          humidity: 46.81854248046875,
          leakage: :no,
          lorawan_class: :class_a,
          payload_version: :v4,
          power_supply: :battery,
          tamper: :open,
          temperature: 23.962173461914063,
          valve: :close
        }
      },
      {
        :parse_hex,
        "333537377223623EBB9A23",
        %{
          meta: %{frame_port: 4},
          _comment: "Full version from real device."
        },
        %{
          battery: 3.577,
          cable: :disconnected,
          di_0: :off,
          di_1: :off,
          fraud: :yes,
          humidity: 73.2818603515625,
          leakage: :no,
          lorawan_class: :class_a,
          payload_version: :v4,
          power_supply: :battery,
          tamper: :open,
          temperature: 23.320159912109375,
          valve: :close
        }
      },
      {
        :parse_hex,
        "F0 30 32 31 76 23 64 B7 6C 11 43 30 37 34 32 32 31 56 30 37 31 43 23 43 56",
        %{
          meta: %{frame_port: 4},
          _comment: "Full version from docs"
        },
        %{
          analog: 808_923_459,
          battery: 0.021,
          cable: :connected,
          counter: 53_013_657_039_409,
          di_0: :off,
          di_1: :off,
          fraud: :yes,
          humidity: 42.21343994140625,
          leakage: :no,
          lorawan_class: :class_c,
          payload_version: :v4,
          power_supply: :external,
          tamper: :open,
          temperature: 24.913864135742188,
          valve: :close
        }
      },
      {
        :parse_hex,
        "f0 30 31 37 7e 23 60 fb 82 b3 23",
        %{
          meta: %{frame_port: 4},
          _comment: "Temp and Humidity from docs"
        },
        %{
          battery: 0.017,
          cable: :connected,
          di_0: :on,
          di_1: :off,
          fraud: :yes,
          humidity: 51.05438232421875,
          leakage: :no,
          lorawan_class: :class_c,
          payload_version: :v4,
          power_supply: :external,
          tamper: :open,
          temperature: 22.506942749023438,
          valve: :close
        }
      },
      {
        :parse_hex,
        "F0 30 32 31 76 56 30 37 31 43 56",
        %{
          meta: %{frame_port: 4},
          _comment: "Analog from docs"
        },
        %{
          analog: 808_923_459,
          battery: 0.021,
          cable: :connected,
          di_0: :off,
          di_1: :off,
          fraud: :yes,
          leakage: :no,
          lorawan_class: :class_c,
          payload_version: :v4,
          power_supply: :external,
          tamper: :open,
          valve: :close
        }
      },
      {
        :parse_hex,
        "F0 30 32 31 76 43 30 37 34 32 32 31 43",
        %{
          meta: %{frame_port: 4},
          _comment: "Counter from docs"
        },
        %{
          battery: 0.021,
          cable: :connected,
          counter: 53_013_657_039_409,
          di_0: :off,
          di_1: :off,
          fraud: :yes,
          leakage: :no,
          lorawan_class: :class_c,
          payload_version: :v4,
          power_supply: :external,
          tamper: :open,
          valve: :close
        }
      },
      {
        :parse_hex,
        "F0 30 32 31 76",
        %{
          meta: %{frame_port: 4},
          _comment: "No options from docs"
        },
        %{battery: 0.021, payload_version: :v3, tamper: :open, valve: :close}
      }
    ]
  end
end
