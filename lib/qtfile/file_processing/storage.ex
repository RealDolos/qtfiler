defmodule Qtfile.FileProcessing.Storage do
  require Logger

  def store_file(file_data, callback) do
    hash = :crypto.hash_init(:sha)
    path = "uploads/" <> file_data.uuid
    size = file_data.size

    delete_on_error(path, [:write, :binary],
      fn(file) ->
        {:ok, _} = :file.position(file, size)
        :ok = :file.truncate(file)
        {:ok, _} = :file.position(file, 0)
        {:ok, {_, 0, hash}, result} =
          callback.({file, size, hash}, fn({file, size, hash}, data) ->
            size = size - :erlang.byte_size(data)
            :ok = :file.write(file, data)
            status =
              cond do
                size > 0 -> :more
                size == 0 -> :ok
              end
            {status, {
              file,
              size,
              :crypto.hash_update(hash, data)
            }}
          end)
        {:ok, {result, hash}}
      end,
      fn({result, hash}) ->
        hash = Base.encode16(:crypto.hash_final(hash), case: :lower)
        file_data = Map.put(file_data, :hash, hash)
        case Qtfile.Files.create_file(file_data) do
          {:ok, _} ->
            QtfileWeb.RoomChannel.broadcast_new_files(
              [file_data], file_data.location.room_id
            )
            {:ok, result}
          {:error, changeset} ->
            Logger.error("failed to add file to db")
            Logger.error(inspect(changeset))
            raise "file creation db error"
        end
      end
    )
  end

  defp delete_on_error(path, args, writeCallback, closedCallback) do
    {:ok, file} = :file.open(path, args)
    try do
      {:ok, result} = writeCallback.(file)
      :ok = :file.sync(file)
      {:ok, result}
    rescue
      e ->
        :file.close(file)
        :file.delete(path)
        raise e
    else
      {:ok, result} ->
        try do
          :ok = :file.close(file)
          {:ok, result} = closedCallback.(result)
          {:ok, result}
        rescue
          e ->
            :file.delete(path)
          raise e
        end
    end
  end
end

