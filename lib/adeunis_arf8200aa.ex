defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for Adeunis ARF8200AA
  # According to documentation provided by Adeunis
  # Link:
  # Documentation: https://www.adeunis.com/wp-content/uploads/2017/08/ANALOG_PWR_LoRaWAN_UG_V2.0.1_FR_EN.pdf

  # massive information provided. if some information is not needed, just comment specific frames



  def parse(<<code::8, status::8, payload::binary>>, _meta) do
    << fcnt::4, err::4 >> = << status::8 >>

    error = case err do
      0 -> "no error"
      1 -> "config done"
      2 -> "low battery"
      4 -> "config switch error"
      8 -> "HW error"
      _ -> "multiple errors"
    end

    case code do
      0x10 ->
        << s300::8, s301::8, s320::8, s321::8, s322::8, s323::8, s306::8 >> = payload
        << a_duration::4, a_trigger::2, a_threshold::2 >> = << s321>>
        << b_duration::4, b_trigger::2, b_threshold::2 >> = << s323>>

        transmission = case s301 do
          0x00 -> "event mode"
          _ -> s301*6
        end

        sense_a = case s320 do
          0 -> "none"
          1 -> "0-10 V"
          2 -> "4-20 mA"
          _ -> "error"
        end

        duration_a = case a_duration do
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
          14 -> 300000
          _ -> "error"
        end

        trigger_a = case a_trigger do
          0 -> "disabled"
          1 -> "rising edge"
          2 -> "falling edge"
          3 -> "rising and falling edges"
          _ -> "error"
        end

        threshold_a = case a_threshold do
          0 -> "none"
          1 -> "Low only"
          2 -> "High only"
          3 -> "Low and high"
          _ -> "error"
        end

        sense_b = case s322 do
          0 -> "none"
          1 -> "0-10 V"
          2 -> "4-20 mA"
          _ -> "error"
        end

        duration_b = case b_duration do
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
          14 -> 300000
          _ -> "error"
        end

        trigger_b = case b_trigger do
          0 -> "disabled"
          1 -> "rising edge"
          2 -> "falling edge"
          3 -> "rising and falling edges"
          _ -> "error"
        end

        threshold_b = case b_threshold do
          0 -> "none"
          1 -> "Low only"
          2 -> "High only"
          3 -> "Low and high"
          _ -> "error"
        end

        operation_mode = case s306 do
          0 -> "Park"
          1 -> "Production"
          2 -> "Test"
          3 -> "Repli"
          _ -> "Error"
        end

        %{
          frame_type: "configuration frame",
          transmission_period_keepalive: s300*6,
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
        << s220::8, s221::8 >> = payload
        adr = case s220 do
          0 -> "Off"
          1 -> "On"
        end

        mode = case s221 do
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
        << _rfua::4, type_a::4, a_value::24, _rfub::4, type_b::4, b_value::24 >> = payload

        unit_a = case type_a do
          1 -> "V"
          2 -> "µA"
          _ -> "error"
        end
        unit_b = case type_b do
          1 -> "V"
          2 -> "mA"
          _ -> "error"
        end

        value_a = case type_a do
          1 -> a_value/1000000
          2 -> a_value/100000
          _ -> "error"
        end

        value_b = case type_b do
          1 -> b_value/1000000
          2 -> b_value/100000
          _ -> "error"
        end

        %{
          unit_a: unit_a,
          value_a: value_a,
          unit_b: unit_b,
          value_b: value_b
        }

      0x42 ->
        << _rfua::4, type_a::4, a_value::24, _rfub::4, type_b::4, b_value::24 >> = payload

        unit_a = case type_a do
          1 -> "V"
          2 -> "µA"
          _ -> "error"
        end
        unit_b = case type_b do
          1 -> "V"
          2 -> "mA"
          _ -> "error"
        end

        value_a = case type_a do
          1 -> a_value/1000000
          2 -> a_value/100000
          _ -> "error"
        end

        value_b = case type_b do
          1 -> b_value/1000000
          2 -> b_value/100000
          _ -> "error"
        end

        %{
          unit_a: unit_a,
          value_a: value_a,
          unit_b: unit_b,
          value_b: value_b
        }
    end
  end
end
