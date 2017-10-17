defmodule Parser do
  use Platform.Parsing.Behaviour

  def parse(<<0::1, 0::1, register::5, status::1, meter_value::24>>, _meta) do
    %{
    Wert: meter_value,
    }
  end
end
