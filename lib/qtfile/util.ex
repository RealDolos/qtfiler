defmodule Qtfile.Util do
  def hash(hash_type, file_path) do
    File.stream!(file_path, [], 2048)
    |> Enum.reduce(:crypto.hash_init(hash_type), fn(line, acc) ->
      :crypto.hash_update(acc,line)
    end)
    |> :crypto.hash_final
    |> Base.encode16(case: :lower)
  end

  def get_ip_address(%{remote_ip: {one, two, three, four}}) do
    "#{one}.#{two}.#{three}.#{four}"
  end
end
