defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for GlobalsSat GPS Tracker
  # According to documentation provided by GlobalSat
  # Link: http://www.globalsat.com.tw/en/product-199335/LoRaWAN%E2%84%A2-Compliant-GPS-Tracker-LT-100-Series.html#a

  def parse(event, _meta) do
    <<_foo::size(8), _fix::size(8), bat::size(8), lat::size(32), lon::size(32)>> = event
    {
      %{
        battery: bat
      },
      [
        location: {  lon*0.000001, lat*0.000001 }
      ]
    }
  end
end
