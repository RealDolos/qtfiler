defmodule Qtfile.FileProcessing.MediaTagger do
  use GenStage
  alias Qtfile.FileProcessing.UploadEvent
  alias Qtfile.Admin.ThumbRegen

  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    {:producer_consumer, {},
     dispatcher: GenStage.BroadcastDispatcher,
     subscribe_to: [UploadEvent, ThumbRegen],
    }
  end

  defp mime_tag(file) do
    mime_type =
      case file.mime_type do
        nil -> ""
        x -> x
      end

    case String.split(mime_type, "/") do
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
