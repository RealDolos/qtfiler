defmodule Qtfile.FileProcessing.MediaTagger do
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

  defp mime_tag(file) do
    case String.split(file.mime_type, "/") do
      ["video" | _] -> {:media, :video, file}
      ["audio" | _] -> {:media, :audio, file}
      ["image" | _] -> {:media, :image, file}
      _ -> {:nomedia, file}
    end
  end

  def handle_events(files, _from, {}) do
    tagged_files = Enum.map(files, &mime_tag/1)
    {:noreply, tagged_files, {}}
  end
end
