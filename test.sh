
set -x
set -e

elixir test_parser.exs lib/adeunis_temp.ex
elixir test_parser.exs lib/ascoel_cm868lmrth.ex
elixir test_parser.exs lib/ascoel_cm868lr.ex
elixir test_parser.exs lib/dzg_loramod.ex
elixir test_parser.exs lib/gwf_gas-meter.ex
elixir test_parser.exs lib/holley_e-meter.ex
elixir test_parser.exs lib/libelium_smart-parking_v3.exs
elixir test_parser.exs lib/libelium_smart-water.ex
elixir test_parser.exs lib/nke_ino.ex
elixir test_parser.exs lib/zis_zisdis8.ex
elixir test_parser.exs lib/zenner_water-meter.ex
elixir test_parser.exs lib/libelium_smart-agriculture.ex
