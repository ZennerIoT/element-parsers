defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for Adeunis ARF8170BA
  # According to documentation provided by Adeunis
  # Link: https://www.adeunis.com/en/produit/dry-contacts-2/
  # Documentation: https://www.adeunis.com/wp-content/uploads/2017/08/DRY_CONTACTS_LoRaWAN_UG_V2.0.0_FR_GB.pdf

  # parser for 4 counter inputs, outputs are not interpreted

  def parse(<<code::8, status::8, payload::binary>>, _meta) do
    << fcnt::3, res::1, err::4 >> = << status::8 >>

    error = case err do
      0 -> "no error"
      1 -> "config done"
      2 -> "low battery"
      4 -> "config switch error"
      8 -> "HW error"
      _ -> "unknown"
    end

    case code do
      0x10 ->
        << s300::8, s301::8, s320::8, s321::8, s322::8, s323::8, s306::8 >> = payload
        %{
          frame_type: "configuration",
          keepalive_time: s300/6,
          transmission_period: s301/6
        }

      0x20 ->
        << adr1::8, mode1::8 >> = payload
        adr = case adr1 do
          0 -> "Off"
          1 -> "On"
        end
       mode = case mode1 do
          0 -> "ABP"
          1 -> "OTAA"
        end
        %{
          frame_type: "ADR config",
          ADR: adr,
          Mode: mode
        }

      0x30 ->
        %{
          frame_type: "Status frame",
          status: "Online"
        }

      0x40 ->
        << tor1::16, tor2::16, tor3::16, tor4::16, details::8 >> = payload
        %{
          frame_type: "data frame",
          Port1_count: tor1,
          Port2_count: tor2,
          Port3_count: tor3,
          Port4_count: tor4
        }
      _ ->
        []
    end

  end
end
