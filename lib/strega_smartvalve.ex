defmodule Parser do
  use Platform.Parsing.Behaviour

  def parse(<<bat_mv::binary-4, vt::binary-1, rest::binary>>, _meta) do
    %{
      bat_v: String.to_integer(bat_mv)/1000,
      valvestatus: if(vt == "1" or vt == "3" , do: "open", else: "closed"),
      lidstatus: if(vt == "2" or vt == "3" , do: "open", else: "closed")
    }
  end

  def fields do
    [
      %{
        field: "bat_v",
        display: "Battery voltage",
        unit: "V"
      }
    ]
  end

  def tests() do
    [
      {
        :parse_hex, "3330343830", %{}, %{
          valvestatus: "closed",
          lidstatus: "closed",
          bat_v: 3.048
        }
      },
      {
        :parse_hex, "3330313131", %{}, %{
          valvestatus: "open",
          lidstatus: "closed",
          bat_v: 3.011
        }
      },
      {
        :parse_hex, "3330333832", %{}, %{
          valvestatus: "closed",
          lidstatus: "open",
          bat_v: 3.038
        }
      },
      {
        :parse_hex, "3239323733", %{}, %{
          valvestatus: "open",
          lidstatus: "open",
          bat_v: 2.927
        }
      }
    ]
  end

end
