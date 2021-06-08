defmodule MediaWeb.MediaView do
  @moduledoc false
  use MediaWeb, :view
  alias MediaWeb.MediaView

  def render(
        "media.json",
        %{
          media:
            %{
              title: title,
              author: author,
              tags: tags,
              type: type,
              locked_status: locked_status,
              private_status: private_status,
              seo_tag: seo_tag,
              id: id
            } = media
        }
      ) do
    %{
      title: title,
      author: author,
      tags: tags,
      type: type,
      locked_status: locked_status,
      private_status: private_status,
      seo_tag: seo_tag,
      id: id |> format_id(),
      number_of_contents: Map.get(media, :number_of_contents, 0),
      files: media.files |> Enum.map(&(&1 |> format_file()))
    }

    # |> IO.inspecT(label)
  end

  defp format_file(%{platform_id: %BSON.ObjectId{} = id, platform: platform} = file),
    do:
      file
      |> Map.put(:platform_id, id |> format_id())
      |> Map.put(
        :platform,
        platform
        |> Map.put(:id, platform |> Map.get(:_id) |> format_id)
        |> Map.delete(:_id)
      )

  defp format_file(%{platform_id: %BSON.ObjectId{} = id} = file),
    do:
      file
      |> Map.put(:platform_id, id |> format_id())

  defp format_file(file), do: file

  defp format_id(%BSON.ObjectId{} = id) do
    id |> BSON.ObjectId.encode!()
  end

  defp format_id(id) do
    id
  end

  # defp format_id(nil), do: nil

  def render("media.json", %{media: media}) do
    media
  end

  def render("message.json", %{message: message}) do
    %{message: message}
  end

  def render("error.json", %{error: error}) do
    %{error: error}
  end

  def render("medias.json", %{medias: medias, total: total}) do
    %{result: render_many(medias, MediaView, "media.json"), total: total}
  end
end

# %{
#   "file_id" => "60b46b843c414e3a86c7505938c8f28f",
#   "filename" => "phoenix.png54e8e3911ace4aeda5120065be047f9e",
#   "platform" => %{
#     "description" => "some description",
#     "height" => 42,
#     "id" => "60be49640a998655d52a8c0f",
#     "inserted_at" => 1_623_083_364,
#     "name" => "e6ca9798a0d148678e62b4482f72d443",
#     "number_of_medias" => 0,
#     "updated_at" => 1_623_083_364,
#     "width" => 42
#   },
#   "platform_id" => "60be49640a998655d52a8c0f",
#   "size" => 13900,
#   "thumbnail_filename" => "phoenix.png-Thumbnail15e3ded486024c7a9d0bcea062ccc2e0",
#   "thumbnail_url" => "some url",
#   "type" => "image/png",
#   "url" => "some url"
# }

# %{
#   "duration" => nil,
#   "file_id" => _fileid,
#   "filename" => _filename_fileid,
#   "platform" => %{
#     "description" => "some description",
#     "height" => 42,
#     "id" => _1609,
#     "inserted_at" => _date1,
#     "name" => _name,
#     "updated_at" => _date2,
#     "width" => 42
#   },
#   "platform_id" => _1610,
#   "size" => _13900,
#   "type" => "image/png",
#   "thumbnail_filename" => thumbnail_filename,
#   "thumbnail_url" => thumbnail_url,
#   "url" => url
# } = file
