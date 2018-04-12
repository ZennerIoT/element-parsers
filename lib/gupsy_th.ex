defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for Gupsy temperature and humidity sensor
  # According to documentation provided by Gupsy

  def parse(<<humid::big-16, temp::big-16, vbat::big-16>>, _meta) do
    %{
      humid: (125*humid)/(65536)-6,
      temp: (175.72*temp)/(65536)-46.85,
      vbat: 10027.008/vbat,
    }
  end
end
