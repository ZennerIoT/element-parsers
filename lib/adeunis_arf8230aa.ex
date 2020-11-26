defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Adeunis ARF8230AA
  # According to documentation provided by Adeunis
  # Link: https://www.adeunis.com/en/produit/pulse-2/
  # Documentation: https://www.adeunis.com/wp-content/uploads/2017/08/PULSE_LoRaWAN_UG_V2_FR_GB.pdf
  #
  # basic parser only, default configs used, no thresholds etc
  # not all alarms/errors visualized, please see documentation for further information
  #
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #   2020-11-24 [jb]: Added extend_reading with start and impulse extension from profile.
  #

  def preloads do
    [device: [profile_data: [:profile]]]
  end

  # Forms from views:
  # k_wh = float(float(device.fields.gaszahler.startwert)+float(data.counter_a)*float(device.fields.gaszahler.impulswertigkeit))*11.3
  # zahlerstand_m_3 = float(float(device.fields.gaszahler.startwert)+float(data.counter_a)*float(device.fields.gaszahler.impulswertigkeit))
#  defp do_extend_reading(%{counter_a: a} = reading, %{device: %{fields: %{"gaszahler" => %{"startwert" => startwert, "impulswertigkeit" => impulswertigkeit}}}}) do
#    zaehlerstand = Float.round((startwert + a) * impulswertigkeit / 1, 4)
#    Map.merge(reading, %{
#      :"7-0:3.0.0" => zaehlerstand,
#      k_wh: zaehlerstand * 11.3,
#      zahlerstand_m_3: zaehlerstand,
#    })
#  end
  # Use this function to add more fields to readings for integration purposes. By default doing nothing.
  defp do_extend_reading(fields, _meta), do: fields

  def parse(<<code::8, status::8, payload::binary>>, meta) do
    << _fcnt::4, err::4 >> = << status::8 >>

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
        << _s306::8, s301::16, s3201::4, s3202::4, _s321::8, _s322::8, s325::16, _s326::16, _s327::16, _s328::16, _s329::16, _s330::16, _s331::16 >> = payload
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
    |> extend_reading(meta)
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  # This function will take whatever parse() returns and provides the possibility
  # to add some more fields to readings using do_extend_reading()
  defp extend_reading(readings, meta) when is_list(readings), do: Enum.map(readings, &extend_reading(&1, meta))
  defp extend_reading({fields, opts}, meta), do: {extend_reading(fields, meta), opts}
  defp extend_reading(%{} = fields, meta), do: do_extend_reading(fields, meta)
  defp extend_reading(other, _meta), do: other

  def tests() do
    [
      {
        :parse_hex,
        "46E00000241200000000",
        %{
          meta: %{
            frame_port: 1
          }
        },
        %{counter_a: 9234, counter_b: 0, error: "no error", frame_type: "data frame"}
      },

#      {
#        :parse_hex,
#        "46E00000241200000000",
#        %{
#          meta: %{
#            frame_port: 1
#          },
#          device: %{
#            fields: %{"gaszahler" => %{"startwert" => 100, "impulswertigkeit" => 0.1}}
#          }
#        },
#        %{
#          "7-0:3.0.0": 933.4,
#          counter_a: 9234,
#          counter_b: 0,
#          error: "no error",
#          frame_type: "data frame",
#          k_wh: 10547.42,
#          zahlerstand_m_3: 933.4
#        }
#      },
    ]
  end

end
