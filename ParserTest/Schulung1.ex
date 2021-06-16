defmodule Parser do
  require Logger
  use Platform.Parsing.Behaviour

  def parse(<<battery::8,value::16-big,status::binary-1,error::binary-1,alarm::binary-1,brightness::16-little>>, %{meta: %{frame_port: 25}}) do
    <<startup::1,normal::1,interrupt::1,_::4,alerttype::1>>=status
    <<_::6,internal::1,external::1>>=error
    <<_::1,door_open::1,button_pressed::1,movement::1,movement_counter::4>>=alarm

    %{
      battery: battery,
      value: value,
      alerttype: parse_alerttype(alerttype),
      brightness: brightness,
      button_pressed: button_pressed==1,
      door_open: door_open==1,
      interrupt: interrupt==1,
      internal: internal==1,
      external: external==1,
      startup: startup==1,
      movement: movement==1,
      movement_counter: movement_counter,
      normal: normal==1
    }

  end

  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  defp parse_alerttype(internal_alerttype) do
    case internal_alerttype do
      0 -> "Fehler"
      1 -> "Alarm"
      _ -> :unknown
    end
  end

  def fields() do
    [
      %{
        "field" => "battery",
        "display" => "Batteriestatus",
        "unit" => "%"
      },
      %{
        "field" => "brightness",
        "display" => "Helligkeit",
        "unit" => "Lux"
      }
    ]
  end

  def tests() do
    [
      {
        :parse_hex, "642710E1007F1027", %{meta: %{frame_port: 25}}, %{
          alerttype: "Alarm",
          battery: 100,
          brightness: 10000,
          button_pressed: true,
          door_open: true,
          external: false,
          internal: false,
          interrupt: true,
          movement: true,
          movement_counter: 15,
          normal: true,
          startup: true,
          value: 10000
        }
      }
    ]
  end
end
