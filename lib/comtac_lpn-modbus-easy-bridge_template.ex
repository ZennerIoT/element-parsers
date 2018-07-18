defmodule Parser do

  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for comtac LPN Modbus easy SW / Specification V0.08
  #
  # Link: https://www.comtac.ch/en/products/lora/bridges/lpn-modbus-bridge.html
  #
  # ----------- ATTENTION! -----------
  #
  # This code is a TEMPLATE and NEEDS to be configured BEFORE usage!
  #
  # This Modbus device is a bridge with multiple registers.
  # Each register needs to be configured in the bridge itself for a device on the modbus.
  # The bridge will send the values of each register via LoRaWAN.
  # This parser needs to be modified to match the register configuration.
  # Set the enabled register in @register_enabled table to either true or false.
  #
  # ----------- ATTENTION! -----------
  #
  # Changelog
  #
  #   2018-07-18: [jb] First implementation.
  #

  @register_enabled [
    r0: true,
    r1: true,
    r2: false,
    r3: false,
    r4: false,
    r5: false,
    r6: false,
    r7: false,

    r8: false,
    r9: false,
    r10: false,
    r11: false,
    r12: false,
    r13: false,
    r14: false,
    r15: false,
  ]
  
  # Parsing LoRa uplink payload structure on Port3
  def parse(<<
      r0::1, r1::1, r2::1, r3::1, r4::1, r5::1, r6::1, r7::1, # Status Modbus REG00..07
      r8::1, r9::1, r10::1, r11::1, r12::1,r13::1,r14::1, r15::1, # Status Modbus REG08..15
      registers_binary::binary
    >>, %{meta: %{frame_port: 3}}) do

    registers = [
      r0: r0,
      r1: r1,
      r2: r2,
      r3: r3,
      r4: r4,
      r5: r5,
      r6: r6,
      r7: r7,
      r8: r8,
      r9: r9,
      r10: r10,
      r11: r11,
      r12: r12,
      r13: r13,
      r14: r14,
      r15: r15,
    ]

    registers |> Enum.reduce({registers_binary, %{}}, &handle_register/2) |> elem(1)
  end

  def handle_register({register, ok}, {registers_binary, result}) do

    case {@register_enabled[register], ok} do

      {true, 0} -> # Enabled but error
        <<value::16, rest::binary>> = registers_binary
        result = result
          |> Map.put(:"#{register}_value", value)
          |> Map.put(:"#{register}_status", "error")
        {rest, result}

      {true, 1} -> # Enabled and ok
        <<value::16, rest::binary>> = registers_binary
        result = result
          |> Map.put(:"#{register}_value", value)
          |> Map.put(:"#{register}_status", "ok")
        {rest, result}

      {false, _} -> # Dont care
        {registers_binary, result}

    end
  end

  #def fields() do
  # # Omitted field definitions here so all fields will be shown.
  # # Because of missing information about the values itself.
  #end

  def tests() do
    [
      {
        # Both register provide values
        :parse_hex, "C00000DE00DE",
        %{meta: %{frame_port: 3}},
        %{r0_status: "ok", r0_value: 222, r1_status: "ok", r1_value: 222},
      },
      {
        # Register 2 is faulty
        :parse_hex, "800000420000",
        %{meta: %{frame_port: 3}},
        %{r0_status: "ok", r0_value: 66, r1_status: "error", r1_value: 0},
      },
    ]
  end

end
