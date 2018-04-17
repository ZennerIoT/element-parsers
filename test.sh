
set -x
set -e

elixir test_parser.exs lib/holley_e-meter.ex
elixir test_parser.exs lib/ascoel_cm868lmrth.ex
