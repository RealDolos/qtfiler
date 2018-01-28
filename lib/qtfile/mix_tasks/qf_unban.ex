defmodule Mix.Tasks.Qf.Unban do
  @shortdoc "Unbans a user"
  use Mix.Task

  def run([user]) do
    Mix.Task.run("qf.set.status", [user, "active"])
  end

  def run(_) do
    Mix.shell.error(Qtfile.Tasks.Util.arguments_error())
  end
end
