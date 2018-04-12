defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for GWF Gas meter with Elster module
  # According to documentation provided by GWF
  # Test hex payload: "01E61E1831062103000000141800000000D830E9"
  def parse(<<ptype::8, manu::integer-little-16, mid::integer-32, medium::8, state::8, accd::integer-little-16, vif::8, volume::integer-little-32, _::binary>>, _meta) do
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


    %{
    protocol_type: ptype,
    manufacturer_id: Base.encode16(<<manu::16>>),
    actuality_minutes: accd,
    meter_id: Integer.to_string(n7)<>Integer.to_string(n6)<>Integer.to_string(n5)<>Integer.to_string(n4)<>Integer.to_string(n3)<>Integer.to_string(n2)<>Integer.to_string(n1)<>Integer.to_string(n0),
    medium: med,
    state: s,
    volume: volume/decimalplaces,
    }
  end
end
