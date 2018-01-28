defmodule Mix.Tasks.Qf.Ban do
  @shortdoc "Bans a user"
  use Mix.Task

  def run([user]) do
    Mix.Task.run("qf.set.status", [user, "banned"])
  end

  def run(_) do
    Mix.shell.error(Qtfile.Tasks.Util.arguments_error())
  end
end
