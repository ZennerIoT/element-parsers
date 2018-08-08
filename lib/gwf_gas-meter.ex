defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for GWF Gas meter with Elster module
  # According to documentation provided by GWF

  #
  # Changelog
  #   2018-04-18 [as]: Initial version.
  #   2018-08-08 [jb]: Parsing battery and additional function.
  #


  def parse(<<ptype::8, manu::integer-little-16, mid::integer-32, medium::8, state::8, accd::integer-little-16, vif::8, volume::integer-little-32, additional_functions::binary-1, battery::binary-1, _::binary>>, _meta) do
    med = case medium do
      3 -> "gas"
      6 -> "warm water"
      7 -> "water"
      _ -> "unknown"
    end

    decimalplaces = case vif do
      0x16 -> 1
      0x15 -> 10
      0x14 -> 100
      0x13 -> 1000
    end

    s = case state do
      0x00 -> "no error"
      0x04 -> "battery error"
      0x30 -> "no comm module <-> meter"
      0x50 -> "jammed comm module <-> meter"
      0x34 -> "no comms module <-> meter AND battery error"
      0x55 -> "jammed comm module <-> meter AND batter error"
      _ -> "unknown error"
    end

    <<n1::integer-4,n0::integer-4,n3::integer-4,n2::integer-4,n5::integer-4,n4::integer-4,n7::4,n6::integer-4>> = <<mid::32>>

    <<battery_lifetime_semester::5, battery_link_error::1, _::2>> = battery

    <<no_usage::1, backflow::1, battery_low::1, _::1, broken_pipe::1, _::1, continous_flow::1, _::1>> = additional_functions

    %{
      protocol_type: ptype,
      manufacturer_id: Base.encode16(<<manu::16>>),
      actuality_minutes: accd,
      meter_id: Integer.to_string(n7)<>Integer.to_string(n6)<>Integer.to_string(n5)<>Integer.to_string(n4)<>Integer.to_string(n3)<>Integer.to_string(n2)<>Integer.to_string(n1)<>Integer.to_string(n0),
      medium: med,
      state: s,
      volume: volume/decimalplaces,

      continous_flow: continous_flow,
      broken_pipe: broken_pipe,
      battery_low: battery_low,
      backflow: backflow,
      no_usage: no_usage,

      battery_link_error: battery_link_error,
      battery_lifetime_semester: battery_lifetime_semester,
      battery_percent: (battery_lifetime_semester / 31) * 100,
    }
  end

  def fields do
    [
      %{
        "field" => "volume",
        "display" => "Volume",
        "unit" => "m³"
      }
    ]
  end

  def tests() do
    [
      {
        :parse_hex, "01E61E1831062103000000141900000000D0982D", %{}, %{
          protocol_type: 1,
          manufacturer_id: "1EE6",
          actuality_minutes: 0,
          meter_id: "21063118",
          medium: "gas",
          state: "no error",
          volume: 0.25,

          battery_lifetime_semester: 26,  # 31 = max, 0 = min
          battery_percent: 83.87096774193549, # 100 = max, 0 = min
          battery_link_error: 0,          # 0 = false, 1 = true

          backflow: 0,
          battery_low: 0,
          broken_pipe: 0,
          continous_flow: 0,
          no_usage: 0,
        }
      }
    ]
  end
end
