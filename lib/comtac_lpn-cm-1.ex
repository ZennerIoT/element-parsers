defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for comtac LPN CM1
  # According to documentation provided ThingPark Market
  # Link: http://www.comtac.ch/de/produkte/lora/condition-monitoring/lpn-cm-1.html
  # Documentation: https://drive.google.com/file/d/0B6TBYAxODZHHa29GVWFfN0tIYjQ/view

  def parse(<<
              status::binary-1,
              _mintemp::signed-8,
              _maxtemp::signed-8,
              _minhum::signed-8,
              _maxhum::signed-8,
              sendinterval::16,
              battery::16,
              temperature::signed-16,
              humidity::signed-16
            >>, _meta) do
        <<
          _max_temp_on::1,
          _min_temp_on::1,
          0::1,
          _tx_on_event::1,
          _max_hum_on::1,
          _min_hum_on::1,
          0::1,
          _booster_on::1 >> = status
        %{
          send_interval: sendinterval,
          temperature_c: temperature/100,
          humidity_percent: humidity/100,
          battery_volt: battery / 1000,
        }
  end

  def parse(_, _), do: []

end
