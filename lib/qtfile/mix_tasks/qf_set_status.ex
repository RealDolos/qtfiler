defmodule Mix.Tasks.Qf.Set.Status do
  @shortdoc "Sets the status of a user."
  use Mix.Task
  import Mix.Ecto

  def run([user, status]) do
    Qtfile.Tasks.Util.start_ecto()

    result =
      Qtfile.Accounts.get_user_by_username(user)
      |> Qtfile.Accounts.update_user(%{status: status})

    case result do
      {:ok, _} ->
        Mix.shell.info("Changed #{user}'s status to \"#{status}\"")
      {:error, changeset} ->
        Qtfile.Tasks.Util.print_errors(changeset.errors)
    end
  end

  def run(_) do
    Mix.shell.error(Qtfile.Tasks.Util.arguments_error())
  end
end
