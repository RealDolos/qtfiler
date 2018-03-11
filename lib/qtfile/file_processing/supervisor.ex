defmodule Qtfile.FileProcessing.Supervisor do
  use Supervisor
  alias Qtfile.FileProcessing.{
    UploadState,
    UploadEvent,
    RoomUploadInformer,
    MetadataGenerator,
    RoomMetadataInformer,
    MediaTagger,
    Thumbnailer,
    RoomPreviewInformer,
  }

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      UploadState,
      UploadEvent,
      RoomUploadInformer,
      MediaTagger,
      MetadataGenerator,
      RoomMetadataInformer,
      Thumbnailer,
      RoomPreviewInformer,
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
