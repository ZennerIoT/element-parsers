defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for ZIS DigitalInputSurveillance 8
  # According to self developed devices
  # not commercially available
  #
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #

  def parse(<< _stat_foo::6, stat_heartbeat::1, stat_change::1, in1::integer-8, in2::integer-8,in3::integer-8,in4::integer-8,in5::integer-8,in6::integer-8,in7::integer-8,in8::integer-8>>, _meta) do

    trigger_txt=[]

    trigger_txt = cond do
      stat_heartbeat==1 -> ["heartbeat"|trigger_txt]
      true -> trigger_txt
    end

    trigger_txt = cond do
      stat_change==1 -> ["change"|trigger_txt]
      true -> trigger_txt
    end

    %{
        trigger: Enum.join(trigger_txt, " , "),
        input1: in1,
        input2: in2,
        input3: in3,
        input4: in4,
        input5: in5,
        input6: in6,
        input7: in7,
        input8: in8
    }
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  def tests() do
    [
      # Heartbeat frame
      {
        :parse_hex, "020101010101010101", %{}, %{
          trigger: "heartbeat",
          input1: 1,
          input2: 1,
          input3: 1,
          input4: 1,
          input5: 1,
          input6: 1,
          input7: 1,
          input8: 1
        }
      },

      #Trigger frame
      {
        :parse_hex, "010000010101010101", %{}, %{
          trigger: "change",
          input1: 0,
          input2: 0,
          input3: 1,
          input4: 1,
          input5: 1,
          input6: 1,
          input7: 1,
          input8: 1
        }
      }
    ]
  end
end
