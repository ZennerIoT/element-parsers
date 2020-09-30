defmodule Parser do
  use Platform.Parsing.Behaviour
  @doc """
     => this is an "@moduledoc"
     # Agriculture Sensor Parser
  
     Build after: T0005978_TRM
     for: Agriculture Sensor
     by: TEKTELIC Communications
     
     Changelog:
       2020-09-29 [fb]: Initial. (without Response to Config/Control Commands)
     
  """
  
  # Does only start if the frame_port matches (thx to elixirs pattern matching)
  def parse(<< data::binary >>, %{meta: %{frame_port: 10}}) do 
    # The recursion thing..
    parse_dyn( Map.new(), data ) # Returns the final List/Map
  end
  
   # Configuration/ Control Commands
  def parse(<< data::binary >>, %{meta: %{frame_port: 100}}) do
    Logger.warn "Configuration/ Control Command received!"
    %{
      configuration_control_commands: data
    }
  end
  
  
  # Catchall o.O
  def parse(_event, _meta) do
    Logger.info "Catchall!"
    []
  end
  
  
# ---
  
  # The dynamic uplink parser
  defp parse_dyn( parsed_payload, << data::binary >> ) do
    # ! REKURSIV !
    # This Function will always return an value or empty map.
    # If an unknown behaviour occurs it will add an notice to the returned data and Log it with the "Logger" Module.
    # Failsafe: If no pattern matches or an unknown pattern is received (due to updates, etc.) it will check wheter the "data" variable is empty 
    # or not and generates the notice as mentioned before.
    # > _meta should be handled seperately in a higher function eq. parse()
    
    case data do
      # If the pattern matches: 0x00, 0xFF (00FF) it knows that it must be followed by any value (in here 1 Byte) and "automatically" cuts this values out,
      # due to elixirs essential design. The overhead left doesn't need to be sliced or anything else.
      # TEMPLATE | x Byte/-s | Fakt: Wrote down some facts to keep in mind.. 
#      << 0x00, 0xFF, dummy::8 , overhead::binary >> ->  
#        parse_dyn(
#          Map.put_new(
#            parsed_payload,  # -> The already parsed fields (passed to function as parameter to persist through the recursion)
#            :dummy,          # -> The "name" of the new field (as atom)
#            dummy            # -> The Value of the new field
#          ),
#          overhead # pass the overhead to have it during the next iteration..
#        )  # Handle the overhead


      # battery_remaining_lifetime | 1 Byte | Fakt: 1%/LSB
      << 0x00, 0xFF, battery_remaining_lifetime::8 , overhead::binary >> ->  
        parse_dyn(
          Map.put_new(
            parsed_payload,               
            :battery_remaining_lifetime,
            battery_remaining_lifetime
          ),
          overhead # pass the overhead..
        )

      # input_1 (Soil Moisture) | 2 Bytes | Fakt: 1kHz/LSB
      << 0x01, 0x04, input_1::16 , overhead::binary >> ->  
        parse_dyn(
          Map.put_new(
            parsed_payload,
            :input_1,
            input_1
          ),
          overhead # pass the overhead..
        )
      
      
      # input_2 (Soil Temperature) | 2 Bytes | Fakt: 1mV/LSB
      << 0x02, 0x02, input_2::16 , overhead::binary >> ->  
        parse_dyn(
          Map.put_new(
            parsed_payload,
            :input_2,
            input_2
          ),
          overhead # pass the overhead..
        )
      
        
      # watermark_01 (Soil Water Tension) | 2 Bytes | Fakt: 1Hz/LSB
      << 0x05, 0x04, watermark_01::16 , overhead::binary >> ->  
        parse_dyn(
          Map.put_new(
            parsed_payload,
            :watermark_01,
            watermark_01
          ),
          overhead # pass the overhead..
        )
        
      
      # watermark_02 (Soil Water Tension) | 2 Bytes | Fakt: 1Hz/LSB
      << 0x06, 0x04, watermark_02::16 , overhead::binary >> ->  
        parse_dyn(
          Map.put_new(
            parsed_payload,
            :watermark_02,
            watermark_02
          ),
          overhead # pass the overhead..
        )
        
        
      # ambient_light_intensity | 2 Bytes | Fakt: 1lx/LSB
      << 0x09, 0x65, ambient_light_intensity::16 , overhead::binary >> ->  
        parse_dyn(
          Map.put_new(
            parsed_payload,
            :ambient_light_intensity,
            ambient_light_intensity
          ),
          overhead # pass the overhead..
        )
        
        
      # 1. ambient_light_alarm [FALSE] | 1 Byte | Fakt: Boolean (0x00 -> No alarm; 0xFF -> ALARM!)
      << 0x09, 0x00, 0x00, overhead::binary >> ->  
        parse_dyn(
          Map.put_new(
            parsed_payload,               
            :ambient_light_alarm,
            false
          ),
          overhead # pass the overhead..
        )
      # 2. ambient_light_alarm [TRUE]
      << 0x09, 0x00, 0xFF, overhead::binary >> ->  
        parse_dyn(
          Map.put_new(
            parsed_payload,               
            :ambient_light_alarm,
            true
          ),
          overhead # pass the overhead..
        )
        
        
      # accelerometer_data | 6 Byte | Fakt: 1 milli-g: [1.Byte = X-Data; 2.Byte = Y-Data; 3.Byte = Z-Data]/ Signed (individuall per Achsis) => Integer is signed ^^
      << 0x0A, 0x71, x_achis::integer-size(16), y_achis::integer-size(16), z_achis::integer-size(16), overhead::binary >> ->  
        parse_dyn(
          Map.put_new(
            parsed_payload,               
            :accelerometer_data,
            %{ # Passes this data as map..
              x: x_achis,
              y: y_achis,
              z: z_achis
            }
          ),
          overhead # pass the overhead..
        )
        
        
      # impact_magnitude | 2 Byte | Fakt: 1 milli-g
      << 0x0A, 0x02, impact_magnitude::16 , overhead::binary >> ->  
        parse_dyn(
          Map.put_new(
            parsed_payload,               
            :impact_magnitude,
            impact_magnitude
          ),
          overhead # pass the overhead..
        )
        
        
      # 1. impact_alarm [FALSE] | 1 Byte | Fakt: Boolean (0x00 -> No impact alarm; 0xFF -> ALARM!)
      << 0x0A, 0x00, 0x00, overhead::binary >> ->  
        parse_dyn(
          Map.put_new(
            parsed_payload,               
            :impact_alarm,
            false
          ),
          overhead # pass the overhead..
        )
      # 2. impact_alarm [TRUE]
      << 0x0A, 0x00, 0xFF, overhead::binary >> ->  
        parse_dyn(
          Map.put_new(
            parsed_payload,               
            :impact_alarm,
            true
          ),
          overhead # pass the overhead..
        )
        
        
      # ambient_temperature | 2 Byte | Fakt: 0.1 °C/LSB signed
      << 0x0B, 0x67, ambient_temperature::integer-size(16), overhead::binary >> ->  
        parse_dyn(
          Map.put_new(
            parsed_payload,               
            :ambient_temperature,
            ambient_temperature * 0.1  # scaled
          ),
          overhead # pass the overhead..
        )
        
        
      # ambient_relative_humidity | 1 Byte | Fakt: 0.5%/LSB
      << 0x0B, 0x68, ambient_relative_humidity::8 , overhead::binary >> ->  
        parse_dyn(
          Map.put_new(
            parsed_payload,               
            :ambient_relative_humidity,
            ambient_relative_humidity * 0.5  # scaled
          ),
          overhead # pass the overhead..
        )
        
        
      # mcu_temperature | 1 Byte | Fakt: 0.1 °C/LSB signed
      << 0x0C, 0x67, mcu_temperature::integer-size(8), overhead::binary >> ->  
        parse_dyn(
          Map.put_new(
            parsed_payload,               
            :mcu_temperature,
            mcu_temperature * 0.1  # scaled
          ),
          overhead # pass the overhead..
        )
        
        
      # Failsafe / Stop point (if no condition fits or data is just empty..)
      << x::binary >> when byte_size(x) > 0 ->
        Logger.error "There is unparsed data left! (#{byte_size(x)} Bytes) - It could be invalid or an parsing error.."
        parsed_payload = Map.put_new(parsed_payload, :configuration_control_commands, "There is unparsed data left! (#{byte_size(x)} Bytes) => (#{Base.encode16(x)})")  # To see in Control/Field
        
        [parsed_payload]
        
      # Default behaviour -> no bytes left
      _ -> 
        [parsed_payload] # Returns the payload.. could be empty
    end
  end
  
  
# ---

  
  # Definition of Fields
  def fields() do
    [
      %{
        "field"   =>"battery_remaining_lifetime",
        "unit"    =>"%",
        "display" =>"Batterie (restliche Lebenszeit)"
      },
      %{
        "field"   =>"input_1",
        "unit"    =>"kHz", # no Conversion factor provided
        "display" =>"Bodenfeuchtigkeit"
      },
      %{
        "field"   =>"input_2",
        "unit"    =>"mV", # no Conversion factor provided
        "display" =>"Bodentemperatur"
      },
      %{
        "field"   =>"watermark_01",
        "unit"    =>"Hz", # no Conversion factor provided
        "display" =>"Bodenwasserspannung 1"
      },
      %{
        "field"   =>"watermark_02",
        "unit"    =>"Hz", # no Conversion factor provided
        "display" =>"Bodenwasserspannung 2"
      },
      %{
        "field"   =>"ambient_light_intensity",
        "unit"    =>"lx",
        "display" =>"Umgebungslichtintensität"
      },
      %{
        "field"   =>"ambient_light_alarm",
        "display" =>"Umgebungslichtalarm"
      },
      %{
        "field"   =>"accelerometer_data",
        "unit"    =>"milli-𝑔",
        "display" =>"Beschleunigungsmesserdaten"
      },
      %{
        "field"   =>"impact_magnitude",
        "unit"    =>"milli-𝑔",
        "display" =>"Aufprallgröße"
      },
      %{
        "field"   =>"impact_alarm",
        "display" =>"Aufprallalarm"
      },
      %{
        "field"   =>"ambient_temperature",
        "unit"    =>"°C",
        "display" =>"Umgebungstemperatur"
      },
      %{
        "field"   =>"ambient_relative_humidity",
        "unit"    =>"%",
        "display" =>"relative Luftfeuchtigkeit"
      },
      %{
        "field"   =>"mcu_temperature",
        "unit"    =>"°C",
        "display" =>"MCU Temperatur"
      }
    ]
  end
  
  
  # TEST's
  def tests() do
    # Note: please reorder/cut/add the payload to test dynamic parsing behaviour (in a new element down here 👇)
    [
      { # All in one (ordered by documentation listing)
        :parse_hex, "00FF0001040000020200000504000006040000096500000900000A710000000000000A0200000A00000B6700000B68000C6700", %{meta: %{frame_port: 10}}, %{
          battery_remaining_lifetime: 0,
          input_1: 0,
          input_2: 0,
          watermark_01: 0,
          watermark_02: 0,
          ambient_light_intensity: 0,
          ambient_light_alarm: false,
          accelerometer_data: %{x: 0, y: 0, z: 0},
          impact_magnitude: 0,
          impact_alarm: false,
          ambient_temperature: 0,
          ambient_relative_humidity: 0,
          mcu_temperature: 0
        }
      },
    ]
  end
  
end
