defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Adeunis ARF8200AA
  # According to documentation provided by Adeunis
  # Link:
  # Documentation: https://www.adeunis.com/wp-content/uploads/2017/08/ANALOG_PWR_LoRaWAN_UG_V2.0.1_FR_EN.pdf
  #
  # massive information provided. if some information is not needed, just comment specific frames
  #
  #
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #   2021-06-07 [jb]: Added do_extend_reading/2 callback. Added tests and formatted code.
  #

  def do_extend_reading(fields, _meta) do
    fields
  end

  def parse(<<code::8, status::8, payload::binary>>, meta) do
    <<_fcnt::4, err::4>> = <<status::8>>

    error =
      case err do
        0 -> "no error"
        1 -> "config done"
        2 -> "low battery"
        4 -> "config switch error"
        8 -> "HW error"
        _ -> "multiple errors"
      end

    case code do
      0x10 ->
        <<s300::8, s301::8, s320::8, s321::8, s322::8, s323::8, s306::8>> = payload
        <<a_duration::4, a_trigger::2, a_threshold::2>> = <<s321>>
        <<b_duration::4, b_trigger::2, b_threshold::2>> = <<s323>>

        transmission =
          case s301 do
            0x00 -> "event mode"
            _ -> s301 * 6
          end

        sense_a =
          case s320 do
            0 -> "none"
            1 -> "0-10 V"
            2 -> "4-20 mA"
            _ -> "error"
          end

        duration_a =
          case a_duration do
            0 -> "no"
            1 -> 10
            2 -> 20
            3 -> 50
            4 -> 100
            5 -> 200
            6 -> 500
            7 -> 1000
            8 -> 2000
            9 -> 5000
            10 -> 10000
            11 -> 20000
            12 -> 40000
            13 -> 60000
            14 -> 300_000
            _ -> "error"
          end

        trigger_a =
          case a_trigger do
            0 -> "disabled"
            1 -> "rising edge"
            2 -> "falling edge"
            3 -> "rising and falling edges"
            _ -> "error"
          end

        threshold_a =
          case a_threshold do
            0 -> "none"
            1 -> "Low only"
            2 -> "High only"
            3 -> "Low and high"
            _ -> "error"
          end

        sense_b =
          case s322 do
            0 -> "none"
            1 -> "0-10 V"
            2 -> "4-20 mA"
            _ -> "error"
          end

        duration_b =
          case b_duration do
            0 -> "no"
            1 -> 10
            2 -> 20
            3 -> 50
            4 -> 100
            5 -> 200
            6 -> 500
            7 -> 1000
            8 -> 2000
            9 -> 5000
            10 -> 10000
            11 -> 20000
            12 -> 40000
            13 -> 60000
            14 -> 300_000
            _ -> "error"
          end

        trigger_b =
          case b_trigger do
            0 -> "disabled"
            1 -> "rising edge"
            2 -> "falling edge"
            3 -> "rising and falling edges"
            _ -> "error"
          end

        threshold_b =
          case b_threshold do
            0 -> "none"
            1 -> "Low only"
            2 -> "High only"
            3 -> "Low and high"
            _ -> "error"
          end

        operation_mode =
          case s306 do
            0 -> "Park"
            1 -> "Production"
            2 -> "Test"
            3 -> "Repli"
            _ -> "Error"
          end

        %{
          frame_type: "configuration frame",
          transmission_period_keepalive: s300 * 6,
          transmission_period_transmission: transmission,
          cha_config: sense_a,
          chb_config: sense_b,
          cha_duration: duration_a,
          cha_trigger: trigger_a,
          cha_threshold: threshold_a,
          chb_duration: duration_b,
          chb_trigger: trigger_b,
          chb_threshold: threshold_b,
          mode: operation_mode
        }

      0x20 ->
        <<s220::8, s221::8>> = payload

        adr =
          case s220 do
            0 -> "Off"
            1 -> "On"
          end

        mode =
          case s221 do
            0 -> "ABP"
            1 -> "OTAA"
          end

        %{
          frame_type: "Nwk config frame",
          ADR: adr,
          Mode: mode,
          error: error
        }

      0x30 ->
        <<_rfua::4, type_a::4, a_value::24, _rfub::4, type_b::4, b_value::24>> = payload

        unit_a =
          case type_a do
            1 -> "V"
            2 -> "µA"
            _ -> "error"
          end

        unit_b =
          case type_b do
            1 -> "V"
            2 -> "mA"
            _ -> "error"
          end

        value_a =
          case type_a do
            1 -> a_value / 1_000_000
            2 -> a_value / 100_000
            _ -> "error"
          end

        value_b =
          case type_b do
            1 -> b_value / 1_000_000
            2 -> b_value / 100_000
            _ -> "error"
          end

        %{
          unit_a: unit_a,
          value_a: value_a,
          unit_b: unit_b,
          value_b: value_b
        }

      0x42 ->
        <<_rfua::4, type_a::4, a_value::24, _rfub::4, type_b::4, b_value::24>> = payload

        unit_a =
          case type_a do
            1 -> "V"
            2 -> "µA"
            _ -> "error"
          end

        unit_b =
          case type_b do
            1 -> "V"
            2 -> "mA"
            _ -> "error"
          end

        value_a =
          case type_a do
            1 -> a_value / 1_000_000
            2 -> a_value / 100_000
            _ -> "error"
          end

        value_b =
          case type_b do
            1 -> b_value / 1_000_000
            2 -> b_value / 100_000
            _ -> "error"
          end

        %{
          unit_a: unit_a,
          value_a: value_a,
          unit_b: unit_b,
          value_b: value_b
        }

      unknown_code ->
        %{error: "unknown_code:#{inspect(unknown_code)}"}
    end
    |> extend_reading(meta)
  end

  def parse(payload, meta) do
    Logger.warn(
      "Could not parse payload #{inspect(payload)} with frame_port #{
        inspect(get_in(meta, [:meta, :frame_port]))
      }"
    )

    []
  end

  # This function will take whatever parse() returns and provides the possibility
  # to add some more fields to readings using do_extend_reading()
  def extend_reading(readings, meta) when is_list(readings),
    do: Enum.map(readings, &extend_reading(&1, meta))

  def extend_reading({fields, opts}, meta), do: {extend_reading(fields, meta), opts}
  def extend_reading(%{} = fields, meta), do: do_extend_reading(fields, meta)
  def extend_reading(other, _meta), do: other

  def tests() do
    [
      {
        :parse_hex,
        "428002061DA102000000",
        %{meta: %{frame_port: 1}},
        %{
          unit_a: "µA",
          unit_b: "mA",
          value_a: 4.00801,
          value_b: 0.0
        }
      }
    ]
  end
end
