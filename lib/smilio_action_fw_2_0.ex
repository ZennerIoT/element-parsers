defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger
  def parse(<<frame, b1::16, b2::16, b3::16, b4::16, b5::16>>, _meta) when frame in [0x02, 0x03, 0x40] do
    %{
      data_frame_type: data_frame_type(frame),
      button1: b1,
      button2: b2,
      button3: b3,
      button4: b4,
      button5: b5,
    }
  end

  # Each 24 hours, Smilio Action sends automatically a monitoring data frame.
  def parse(<<0x01, battery_idle::16, battery_emission::16, 0x64>>, _meta) do
    %{
      message_type: "keep_alive",
      battery_idle: battery_idle,
      battery_emission: battery_emission
    }
  end

  def parse(payload, _meta) do
    Logger.info("Unhandled Payload: #{inspect payload}")
    []
  end


  def data_frame_type(0x02), do: "normal"
  # Whenever the SKIPLY magnetic badge is detected, Smilio Action sends an `acknowledge` frame.
  def data_frame_type(0x03), do: "acknowledge"
  # The PULSE data frame is the same as the `normal` with the
  # significant difference that counters are reset to zero after the data frame is sent.
  def data_frame_type(0x40), do: "pulse"
  def data_frame_type(_), do: "unknown"

  def fields do
    [
      %{
        "field" => "battery_idle",
        "display" => "Battery (Idle Mode)",
        "unit" => "mV"
      },
      %{
        "field" => "battery_emission",
        "display" => "Battery (Emission)",
        "unit" => "mV"
      },
      %{
        "field" => "data_frame_type",
        "display" => "Data Frame Type",
      },
      %{
        "field" => "button1",
        "display" => "Button 1",
      },
      %{
        "field" => "button2",
        "display" => "Button 2",
      },
      %{
        "field" => "button3",
        "display" => "Button 3",
      },
      %{
        "field" => "button4",
        "display" => "Button 4",
      },
      %{
        "field" => "button5",
        "display" => "Button 5",
      }
    ]
  end

  def tests() do
    [
      {
        :parse_hex, "020001001000A000230010", %{}, %{
          button1: 1,
          button2: 16,
          button3: 160,
          button4: 35,
          button5: 16,
          data_frame_type: "normal"}
        },
      {
        :parse_hex, "030001001000A000230010", %{}, %{
          button1: 1,
          button2: 16,
          button3: 160,
          button4: 35,
          button5: 16,
          data_frame_type: "acknowledge"}
        },
      {
        :parse_hex, "4000010000000100000001", %{}, %{
          button1: 1,
          button2: 0,
          button3: 1,
          button4: 0,
          button5: 1,
          data_frame_type: "pulse"}
      },
      {
        :parse_hex, "010C800C8064", %{}, %{
          battery_emission: 3200,
          battery_idle: 3200,
          message_type: "keep_alive"
        }
      },
    ]
  end
end
