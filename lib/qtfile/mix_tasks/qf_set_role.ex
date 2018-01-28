defmodule Mix.Tasks.Qf.Set.Role do
  @shortdoc "Sets the role of a user"
  @moduledoc """
  USAGE: mix qf.set.role USERNAME ROLE
  Check the documentation or the code to see the available roles.
  """
  use Mix.Task
  import Mix.Ecto

  def run([user, role]) do
    Qtfile.Tasks.Util.start_ecto()
    role = String.downcase(role)

    result =
      Qtfile.Accounts.get_user_by_username(user)
      |> Qtfile.Accounts.update_user(%{role: role})

    case result do
      {:ok, _} ->
        Mix.shell.info("Changed #{user}'s role to \"#{role}\"")
      {:error, changeset} ->
        Qtfile.Tasks.Util.print_errors(changeset.errors)
    end
  end

  def run(_) do
    Mix.shell.error(Qtfile.Tasks.Util.arguments_error())
  end
end
