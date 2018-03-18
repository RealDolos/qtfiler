defmodule Qtfile.FileProcessing.VideoPreviewGenerator do
  use GenStage
  alias Qtfile.FileProcessing.MediaTagger
  require Logger

  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    {:producer_consumer, {},
     dispatcher: GenStage.BroadcastDispatcher,
     subscribe_to: [{MediaTagger, selector: &tag_selector/1}],
    }
  end

  defp tag_selector({:media, :video, _}) do
    true
  end

  defp tag_selector(_) do
    false
  end

  defp video_types() do
    [
      [
        ext: "webm",
        type: "webm",
        codec: "libvpx",
        extra_options: []
      ],
      [
        ext: "mp4",
        type: "mp4",
        codec: "libx264",
        extra_options: []
      ],
    ]
  end

  def handle_events(tagged_files, _from, {}) do
    video_previews = Enum.flat_map(video_types(), fn(params) ->
      Enum.flat_map(tagged_files, fn({:media, :video, file}) ->
        try do
          [generate_video_preview(file, params)]
        rescue
          e ->
            Logger.info "thumbgen error"
            Logger.info(inspect(e))
            []
        end
      end)
    end)

    {:noreply, video_previews, {}}
  end

  defp generate_video_preview(
    file, ext: ext, type: type, codec: codec, extra_options: extra_options
  ) do

    path = "uploads/" <> file.uuid
    output_path = "uploads/previews/" <> file.uuid <> "." <> ext

    result = Porcelain.exec("ffmpeg", extra_options ++
      [
        "-i", path, "-map_metadata", "-1", "-an", "-sn", "-map", "0:v", "-c:v", codec,
        "-crf", "23", "-b:v", "64k", "-f", ext,
        "-vf", "scale=w=256:h=256:force_original_aspect_ratio=decrease", "-t", "15",
        output_path
      ]
    )

    0 = result.status

    {:ok, video_preview} = Qtfile.Files.add_preview(
      %{
        file: file,
        mime_type: "video/" <> type,
      }
    )

    video_preview
  end
end
