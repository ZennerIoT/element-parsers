defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for Bosch Parking Sensor
  # According to documentation provided by Bosch.
  #
  # Changelog
  # 2018-10-09: [jb] Interface v1 implemented
  # 2018-11-12: [jb] Interface v2 implemented
  # 2019-02-19: [jb] Added fields


  # 3.1.1 Parking status
  def parse(<<_reserved::7, state::1>>, %{meta: %{frame_port: 1}}) do
    %{
      message_type: "parking_status",
      p_state: park_state_name(state),
      map_state: state,
    }
  end

  # 3.1.2 Heartbeat
  def parse(<<_reserved::7, state::1>>, %{meta: %{frame_port: 2}}) do
    %{
      message_type: "heartbeat",
      p_state: park_state_name(state),
      map_state: state,
    }
  end

  # 3.1.3 Startup
  def parse(<<_reserved::7, state::1, reset_cause::8, firmware::24, debug::binary-12>>, %{meta: %{frame_port: 3}}) do
    << major::8, minor::8, patch::8 >> = << firmware::24 >>
    %{
      message_type: "startup",
      p_state: park_state_name(state),
      map_state: state,
      reset_cause: reset_cause(reset_cause),
      firmware: "#{major}.#{minor}.#{patch}",
      debug: Base.encode16(debug),
    }
  end

  # Catchall for reparsing
  def parse(_, _), do: []


  def park_state_name(0), do: "free"
  def park_state_name(1), do: "occupied"
  def park_state_name(_), do: "unknown"

  def reset_cause(0), do: "watchdog_reset"
  def reset_cause(1), do: "power_on_reset"
  def reset_cause(2), do: "system_request_reset"
  def reset_cause(_), do: "other_resets"

  def fields() do
    [
      %{
        "field" => "message_type",
        "display" => "Message Type",
      },
      %{
        "field" => "p_state",
        "display" => "Parking State Name",
      },
      %{
        "field" => "map_state",
        "display" => "Parking State",
      },
      %{
        "field" => "debug",
        "display" => "Debug Info",
      },
      %{
        "field" => "firmware",
        "display" => "Firmware",
      },
      %{
        "field" => "reset_cause",
        "display" => "Reset Cause",
      },

      %{
        "field" => "message_type",
        "display" => "DI2-ChangeAfter",
        "unit" => "s"
      },
    ]
  end


  def tests() do
    [
      # 3.1.1 Parking status
      {
        :parse_hex, "00", %{meta: %{frame_port: 1}}, %{message_type: "parking_status", map_state: 0, p_state: "free"},
      },
      {
        :parse_hex, "01", %{meta: %{frame_port: 1}}, %{message_type: "parking_status", map_state: 1, p_state: "occupied"},
      },

      # 3.1.2 Heartbeat
      {
        :parse_hex, "00", %{meta: %{frame_port: 2}}, %{message_type: "heartbeat", map_state: 0, p_state: "free"},
      },
      {
        :parse_hex, "01", %{meta: %{frame_port: 2}}, %{message_type: "heartbeat", map_state: 1, p_state: "occupied"},
      },

      # 3.1.3 Startup
      {
        :parse_hex, "0000000000000000000000000017030300", %{meta: %{frame_port: 3}}, %{
          debug: "000000000000000017030300",
          firmware: "0.0.0",
          map_state: 0,
          message_type: "startup",
          p_state: "free",
          reset_cause: "watchdog_reset"
        },
      },
      {
        :parse_hex, "0100000000000000000000000017030300", %{meta: %{frame_port: 3}}, %{
          debug: "000000000000000017030300",
          firmware: "0.0.0",
          map_state: 1,
          message_type: "startup",
          p_state: "occupied",
          reset_cause: "watchdog_reset"
        },
      },

    ]
  end

end
