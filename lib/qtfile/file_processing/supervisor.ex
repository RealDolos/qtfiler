defmodule Qtfile.FileProcessing.Supervisor do
  use Supervisor
  alias Qtfile.FileProcessing.{UploadState, UploadEvent, RoomUploadInformer}

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      {UploadState, []},
      {UploadEvent, []},
      {RoomUploadInformer, [10]},
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
