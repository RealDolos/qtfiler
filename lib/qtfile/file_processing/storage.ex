defmodule Qtfile.FileProcessing.Storage do
  def new_file(id, size) do
    written = :uninitialised
    info = {id, size}
    {:ok, {info, written}}
  end

  def get_id({{id, _}, _}) do
    id
  end

  def get_size({{_, size}, _}) do
    size
  end

  def get_offset({_, :uninitialised}) do
    0
  end

  def get_offset({_, {:initialised, o}}) do
    o
  end

  def write_chunk(
    {{id, size} = info, written} = upload, offset, chunkSize, writeCB, doneCB
  ) do
    path = "uploads/" <> id

    {mode, initialise} =
      case written do
        :uninitialised ->
          {[:write, :binary], fn(file) ->
            {:ok, _} = :file.position(file, size)
            :ok = :file.truncate(file)
            {:initialised, 0}
          end}
        {:initialised, _} ->
          {[:read, :write, :binary], fn(_) ->
            written
          end}
      end

    delete_on_error(path, mode,
      fn(file) ->
        written = initialise.(file)
        {:initialised, currentOffset} = written

        if offset == currentOffset do
          {:ok, _} = :file.position(file, offset)
          chunkState = {0}

          {status, {chunkWritten}, result} =
            writeCB.(chunkState, fn({chunkWritten}, data) ->
              size = :erlang.byte_size(data)
              chunkWritten = chunkWritten + size

              if chunkWritten > chunkSize do
                :error
              else
                :file.write(file, data)

                status = if chunkWritten == chunkSize do
                  :ok
                else
                  :more
                end

                {status, {chunkWritten}}
              end
            end)

          case status do
            :ok ->
              true = chunkWritten == chunkSize
            :suspended ->
              true = chunkWritten < chunkSize
          end

          written = {:initialised, offset + chunkWritten}
          {:ok, {{info, written}, result}}
        else
          {:ok, {{info, written}, :offset_incorrect}}
        end
      end, fn({upload, result}) ->
        {{_, size}, written} = upload
        done =
          case written do
            {:initialised, ^size} -> true
            {:initialised, _} -> false
            :uninitialised -> false
          end
        doneCB.(done, upload, result)
      end
    )
  end

  defp delete_on_error(
    path, args, writeCallback, closedCallback
  ) do
    {:ok, file} = :file.open(path, args)
    try do
      {:ok, result} = writeCallback.(file)
      :ok = :file.sync(file)
      :ok = :file.close(file)
      {:ok, result}
    rescue
      e ->
        :ok = :file.close(file)
        :ok = :file.delete(path)
        raise e
    else
      {:ok, result} ->
        try do
          closedCallback.(result)
        rescue
          e ->
            :ok = :file.delete(path)
            raise e
        end
    end
  end
end

