defmodule Parser do
  use Platform.Parsing.Behaviour

  def parse(<<0::1, 0::1, _register::5, _status::1, meter_value::24>>, _meta) do
    %{
      Wert: meter_value,
    }
  end
end
