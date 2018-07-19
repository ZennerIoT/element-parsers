defmodule Parser do
  use Platform.Parsing.Behaviour

  # Parser for E1310 DALI Bridge

  # Example Payload: 020500000000

  #  Byte[0]: Bit1 für DALI Kommunikationsfehler; Bit3: DALI Leuchte hat einen Leuchtwert > 0
  #  Byte[1]: Letzter empfanger LoRaWAN Leuchtwert in Prozent
  #  Byte[2]: Letzter DALI Leuchtwert (0..253) (QueryActLevel-Cmd)
  #  Byte[3]: DALI-Status (QueryStatus-Cmd)
  #  Bit 0: Status of Ballast (0 = ok)
  #  Bit 1: Lamp failure (0 = ok)
  #  Bit 2: Lamp arc power on (0 = off)
  #  Bit 3: Query: Limit Error (0 = Last requested arc power level is between MIN...MAX or OFF)
  #  Bit 4: Fade ready (0 = fade is ready, 1 = fade is running)
  #  Bit 5: Query: Reset state (0 = No)
  #  Bit 6: Query: Missing Short Address (0 = No)
  #  Bit 7: Query: Power failure (0 = No)
  #  Byte[4]: DALI-Device Versionnr (QueryVersionnr-Cmd)
  #  Byte[5]: DALI-Device Devicetype (QueryDevicetype-Cmd)

  def parse(<<
      _::4, #unused
      glowing::1,
      _::1, #unused
      communication_error::1,
      _::1, # unused
      last_received_level::8,
      last_level::8,
      power_failure::1,
      missing_short_address::1,
      reset_state::1,
      fade_ready::1,
      limit_error::1,
      lamp_arc_power_on::1,
      lamp_failure::1,
      ballast_error::1,
      dali_version::8,
      dali_device_type::8
    >>, _meta) do
    %{
      communication_error: communication_error,
      glowing: glowing,
      last_received_level: last_received_level,
      last_level: last_level,
      ballast_error: ballast_error,
      lamp_failure: lamp_failure,
      lamp_arc_power_on: lamp_arc_power_on,
      limit_error: limit_error,
      fade_ready: fade_ready,
      reset_state: reset_state,
      missing_short_address: missing_short_address,
      power_failure: power_failure,
      dali_version: dali_version,
      dali_device_type: dali_device_type,
    }
  end
  def parse(_, _), do: []

end
