defmodule Mix.Tasks.Qf.Token do
  @shortdoc "Creates a registration token"
  use Mix.Task
  import Mix.Ecto

  def run([]) do
    Qtfile.Tasks.Util.start_ecto()

    token = Qtfile.SingleToken.create_token()

    response = "=== Generated Token ===
Token: " <> token

    Mix.shell.info(response)
  end

  def run(_) do
    Mix.shell.info("=== This command does not take any arguments ===")
  end
end
