defmodule Qtfile.FileProcessing.MetadataGenerator do
  use GenStage
  alias Qtfile.FileProcessing.UploadEvent

  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    {:producer_consumer, {},
     dispatcher: GenStage.BroadcastDispatcher,
     subscribe_to: [UploadEvent],
    }
  end

  def handle_events(files, _from, {}) do
    metadata_objects = Enum.map(files, fn(file) ->
      process_file(file)
    end)

    {:noreply, metadata_objects, {}}
  end

  defp process_file(file) do
    path = "uploads/" <> file.uuid

    result = Porcelain.exec("ffprobe",
      ["-print_format", "json", "-show_format", "-show_streams", path]
    )

    0 = result.status
    result = Poison.decode!(result.out)
    {:ok, metadata_object} = Qtfile.Files.add_metadata(file, result)
    metadata_object
  end
end
