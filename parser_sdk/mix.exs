defmodule ParserSdk.MixProject do
  use Mix.Project

  def project do
    [
      app: :parser_sdk,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps() ++ deps_testing(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},

      {:timex, "~> 3.1"},
    ]
  end

  defp deps_testing(:test) do
    [
      {:lib_wmbus, git: zisops_git_url("code/lib_wmbus"), ref: "cc993ae48f35f38d68a0a03503121b36131bf405"}
    ]
  end
  defp deps_testing(_) do
    []
  end

  # Helper for a ssh-less dependency using https which needs user:pass from env.
  def zisops_git_url(repo) do
    if nil == System.get_env("DEPLOYMENT_USER") || nil == System.get_env("DEPLOYMENT_PASSWORD") do
      "git@git.zisops.com:#{repo}.git"
    else
      "https://#{System.get_env("DEPLOYMENT_USER")}:#{System.get_env("DEPLOYMENT_PASSWORD")}@git.zisops.com/#{repo}.git"
    end
  end
end
