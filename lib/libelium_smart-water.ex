defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for Libelium Smart Environment Device
  # According to documentation provided by Libelium
  # Link: http://www.libelium.com/development/plug-sense
  # Documentation: http://www.libelium.com/downloads/documentation/waspmote_plug_and_sense_technical_guide.pdf
  
  def parse(<<temp::big-16, opr::big-16, ph::big-16, disox::big-16, conduct::big-16, power::big-16>>, _meta) do

    # return value map
    %{
      temp: temp/10,    # Temperature in °C
      opr: opr/100,     # Oxidation-reduction potential in V
      ph: ph/100,       # pH
      disox: disox/10,  # Dissolved Oxygen in %
      conduct: conduct, # Conductivity in µS/cm
      power: power      # Battery level in %
    }
  end
end
