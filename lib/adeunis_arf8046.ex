defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #

  def parse(<<_code::8, status::8, _type::8, meter_value1::little-32, _type2::8, meter_value2::little-32>>, _meta) do
    << _fcnt::4, err::4 >> = << status::8 >>

    error = case err do
      0 -> "no error"
      1 -> "config done"
      2 -> "low battery"
      4 -> "config switch error"
      8 -> "HW error"
    end

    %{
      value1: meter_value1,
      value2: meter_value2,
      error: error
    }

  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end


# edit unit so it matches your usecase, mind pulse valence
  def fields do
  [
    %{
      "field" => "Wert",
      "unit" => "kWh",
      "display" => "Wert"
    }
  ]
  end
end
