defmodule Qtfile.Tasks.Util do
  import Mix.Ecto

  def start_ecto() do
    Application.put_env(:logger, :level, :info)
    [repo] = parse_repo([])

    ensure_repo(repo, [])
    ensure_started(repo, [])
  end

  def print_errors([]) do
  end

  def print_errors([{field, {reason, _}}|t]) do
    Mix.shell.info("=== An ecto validation error occurred! ===")
    IO.puts "#{field} #{reason}"
    print_errors(t)
  end

  def arguments_error(), do: "=== Wrong amount of arguments supplied ==="
end
