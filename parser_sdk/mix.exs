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
      {:timex, "~> 3.1"},
      {:lib_wmbus, git: zisops_git_url("code/lib_wmbus"), ref: "cc993ae48f35f38d68a0a03503121b36131bf405"}, # Internal ZIS library available on ELEMENT.
    ]
  end

  def zisops_git_url(repo) do
    if nil == System.get_env("DEPLOYMENT_USER") || nil == System.get_env("DEPLOYMENT_PASSWORD") do
      "git@git.zisops.com:#{repo}.git"
    else
      "https://#{System.get_env("DEPLOYMENT_USER")}:#{System.get_env("DEPLOYMENT_PASSWORD")}@git.zisops.com/#{repo}.git"
    end
  end
end
