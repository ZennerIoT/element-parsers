defmodule ParserSdk.MixProject do
  use Mix.Project

  def project do
    [
      app: :parser_sdk,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Default dependencies
  defp deps do
    [
      {:timex, "~> 3.3"},
      {:lib_wmbus, git: zisops_git_url("code/lib_wmbus"), ref: "84b93ff1cc61a06bae4bedc42b865e7a97f35be4"}, # Internal ZIS library available on ELEMENT.
      {:timeseries, git: zisops_git_url("code/timeseries")}, # Internal ZIS library available on ELEMENT.
    ]
  end

  def zisops_git_url(repo) do
    "git@git.zisops.com:#{repo}.git"
  end
end
