defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for Adeunis ARF8230AA
  # According to documentation provided by Adeunis
  # Link: https://www.adeunis.com/en/produit/pulse-2/
  # Documentation: https://www.adeunis.com/wp-content/uploads/2017/08/PULSE_LoRaWAN_UG_V2_FR_GB.pdf

  # basic parser only, default configs used, no thresholds etc
  # not all alarms/errors visualized, please see documentation for further information

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
        << s306::8, s301::16, s3201::4, s3202::4, s321::8, s322::8, s325::16, s326::16, s327::16, s328::16, s329::16, s330::16, s331::16 >> = payload
        %{
          frame_type: "configuration frame",
          transmission_period: s301/60,
          ch1_config: s3201,
          ch2_config: s3202,
          measure_period: s325,
          error: error
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
        << alarms::8, maxf_a::16, maxf_b::16, minf_a::16, minf_b::16 >> = payload
        %{
          frame_type: "keepalive frame",
          alarms: alarms,
          max_flow_a: maxf_a,
          max_flow_b: maxf_b,
          min_flow_a: minf_a,
          min_flow_b: minf_b,
          error: error
        }

      0x46 ->
        << counter_a:: 32, counter_b::32 >> = payload
        %{
          frame_type: "data frame",
          counter_a: counter_a,
          counter_b: counter_b,
          error: error
        }

      _ ->
        []
    end

  end



end
