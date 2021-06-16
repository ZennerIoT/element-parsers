defmodule Parser do
  require Logger
  use Platform.Parsing.Behaviour



  def parse(<<battery::8,rest::binary>>, %{meta: %{frame_port: 30}}) do

  Map.merge(
    %{
      battery: battery
    },
    parse_rest(rest)
    )
  end

  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  defp parse_rest(<<0x00,error::binary-1,rest::binary>>) do
    <<_::6,internal::1,external::1>>=error

    Map.merge(
      %{
        internal: internal==1,
        external: external==1
      },
      parse_rest(rest)
    )
  end

  defp parse_rest(<<0x01,alert::binary-1,rest::binary>>) do
    <<_::1,door_open::1,button_pressed::1,movement::1,movement_counter::4>>=alert

    Map.merge(
      %{
      door_open: door_open==1,
      button_pressed: button_pressed==1,
      movement: movement==1,
      movement_counter: movement_counter
    },
    parse_rest(rest)
    )

  end

  defp parse_rest(<<0x02,temperature::8,rest::binary>>) do
    Map.merge(
      %{
        temperature: temperature
      },
      parse_rest(rest)
    )
  end

  defp parse_rest(<<>>) do
    %{

    }
  end

  defp parse_rest(<<_::binary-1,_::binary-1,rest::binary>>) do
    Map.merge(
      %{

      },
    parse_rest(rest)
    )
  end




  def fields() do
    [
      %{
        "field" => "battery",
        "display" => "Batteriestatus",
        "unit" => "%"
      }
    ]
  end



  def tests() do
    [
      {
        :parse_hex, "640003017F0264", %{meta: %{frame_port: 30}}, %{
          battery: 100,
          button_pressed: true,
          door_open: true,
          external: true,
          internal: true,
          movement: true,
          movement_counter: 15,
          temperature: 100
        }
      }
    ]
  end
end
