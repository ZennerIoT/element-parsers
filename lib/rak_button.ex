defmodule Parser do
  # Parser v1 for RAK Button according to: http://docs.rakwireless.com/en/LoRa/RAK612-LoRaButton/Software%20Development/RAK_LB801%C2%A0LoRaButton%C2%A0AT%20Firmware%20User%C2%A0Manual%C2%A0V1.0.pdf
  # Creator NK

  use Platform.Parsing.Behaviour

  def parse(<<0x53,0x01, b1, b2, b3, b4, charging, battery >>, _meta) do
    button_pressed = cond do
      b1 == 1 -> "button1"
      b2 == 1 -> "button2"
      b3 == 1 -> "button3"
      b4 == 1 -> "button4"
      true -> "none"
    end
    %{
      charging: charging == 1,
      battery: min(battery, 100),
      button1: b1,
      button2: b2,
      button3: b3,
      button4: b4,
      button_pressed: button_pressed
    }
  end
end
