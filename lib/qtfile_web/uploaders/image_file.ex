defmodule Qtfile.ImageFile do
  use Arc.Definition
  use Arc.Ecto.Definition
  import Ecto
  def __storage, do: Arc.Storage.Local

  # Include ecto support (requires package arc_ecto installed):

  # @versions [:original]

  # To add a thumbnail version:
  @versions [:original, :thumb]

  # Whitelist file extensions:
  # def validate({file, _}) do
  #   ~w(.jpg .jpeg .gif .png) |> Enum.member?(Path.extname(file.file_name))
  # end

  # Define a thumbnail transformation:
  def transform(:thumb, _) do
    # windows is garbage jesus christ just purge it please
    {os, _} = :os.type()

    if os === :unix do
      {:convert, "-strip -limit area 10MB -limit disk 100MB -limit width 3840 -limit height 2160 -thumbnail 250x250^ -gravity center -extent 250x250 -format png", :png}
    else
      :noaction
    end
  end

  # Override the persisted filenames:
  def filename(version, {file, scope}) do
    # version
    "#{scope.uuid}-#{version}"
  end

  # Override the storage directory:
  def storage_dir(version, {file, scope}) do
    "uploads/rooms/#{scope.room_id}"
  end

  # Provide a default URL if there hasn't been a file uploaded
  # def default_url(version, scope) do
  #   "/images/avatars/default_#{version}.png"
  # end

  # Specify custom headers for s3 objects
  # Available options are [:cache_control, :content_disposition,
  #    :content_encoding, :content_length, :content_type,
  #    :expect, :expires, :storage_class, :website_redirect_location]
  #
  # def s3_object_headers(version, {file, scope}) do
  #   [content_type: Plug.MIME.path(file.file_name)]
  # end
end
