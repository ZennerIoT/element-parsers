defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #

  def parse(<<0::1, 0::1, _register::5, _status::1, meter_value::24>>, _meta) do
    %{
      Wert: meter_value,
    }
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

end
