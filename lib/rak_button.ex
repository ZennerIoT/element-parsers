defmodule Parser do

  use Platform.Parsing.Behaviour

  require Logger

  #
  # Parser v1 for device RAK Button.
  #
  # Changelog:
  #   2019-05-09 [nk]: Initial implementation according to "RAK_LB801LoRaButtonATFirmwareUserManualV1.0.pdf"
  #   2019-05-09 [jb]: Added tests, fields and documentation.
  #

  def parse(<<0x53, 0x01, b1, b2, b3, b4, charging, battery>>, _meta) do
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
      button1: b1, # Can be 0=off or 1=on, this is NOT a counter.
      button2: b2,
      button3: b3,
      button4: b4,
      button_pressed: button_pressed,
    }
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  # Define fields with human readable name and a SI unit if available.
  def fields() do
    [
      %{
        field: "charging",
        display: "Stromversorgung",
      },
      %{
        field: "battery",
        display: "Batteriestand",
        unit: "%",
      },
      %{
        field: "button1",
        display: "Knopf 1",
      },
      %{
        field: "button2",
        display: "Knopf 2",
      },
      %{
        field: "button3",
        display: "Knopf 3",
      },
      %{
        field: "button4",
        display: "Knopf 4",
      },
      %{
        field: "button_pressed",
        display: "Knopf gedrückt",
      },
    ]
  end

  def tests() do
    [
      {:parse_hex, "5301000000000142", %{meta: %{frame_port: 8}},
        %{
          battery: 66,
          button1: 0,
          button2: 0,
          button3: 0,
          button4: 0,
          button_pressed: "none",
          charging: true
        }
      },
      {:parse_hex, "53010101010100FF", %{meta: %{frame_port: 8}},
        %{
          battery: 100,
          button1: 1,
          button2: 1,
          button3: 1,
          button4: 1,
          button_pressed: "button1",
          charging: false
        }
      },
      {:parse_hex, "5301000000010164", %{meta: %{frame_port: 8}},
        %{
          battery: 100,
          button1: 0,
          button2: 0,
          button3: 0,
          button4: 1,
          button_pressed: "button4",
          charging: true
        }
      },
      {:parse_hex, "5301000100000064", %{meta: %{frame_port: 8}},
        %{
          battery: 100,
          button1: 0,
          button2: 1,
          button3: 0,
          button4: 0,
          button_pressed: "button2",
          charging: false
        }
      },
      {:parse_hex, "", %{meta: %{frame_port: 8}}, []},
    ]
  end

end
