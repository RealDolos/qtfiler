defmodule Qtfile.Util do
  def hash(hash_type, file_path) do
    File.stream!(file_path, [], 2048)
    |> Enum.reduce(:crypto.hash_init(hash_type), fn(line, acc) ->
      :crypto.hash_update(acc,line)
    end)
    |> :crypto.hash_final
    |> Base.encode16(case: :lower)
  end
end
