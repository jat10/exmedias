defmodule MongoDB do
  @moduledoc false
  defstruct args: []

  defimpl DB, for: MongoDB do
    @media_collection "media"
    alias BSON.ObjectId
    alias Media.Helpers
    alias Media.Schema, as: Media

    def get(%MongoDB{args: %{id: id}}) do
      case Mongo.find_one(Helpers.repo(), @media_collection, %{_id: ObjectId.decode!(id)}) do
        nil ->
          {:error, :not_found, @media_collection}

        item ->
          Helpers.format_item(item, Media, id)
      end
    end

    defp get_media(id) do
      Mongo.find_one(Helpers.repo(), @media_collection, %{_id: ObjectId.decode!(id)})
      |> case do
        nil -> {:error, :not_found, @media_collection}
        item -> item
      end
    end

    def insert(%MongoDB{args: args}) do
      data = Media.changeset(%Media{}, args)

      with true <- data.valid?,
           {:ok, result} <-
             Mongo.insert_one(Helpers.repo(), @media_collection, Helpers.get_changes(data)) do
        get_media(ObjectId.encode!(result.inserted_id))
        |> Helpers.format_item(Media, ObjectId.encode!(result.inserted_id))
      else
        {:error, %{write_errors: [%{"code" => 11_000}]}} ->
          {:error, "#{@media_collection |> String.capitalize()} already exists"}

        false ->
          {:error, data}

        _err ->
          {:error, %{error: "Unknown DB Error"}}
      end
    end

    def update(%MongoDB{args: %{id: id} = args} = media) do
      with %Media{} = media <- get(media),
           data <- Media.changeset(media, args),
           {data, true} <- {data, data.valid?},
           {:ok, _result} <-
             Mongo.update_one(
               :mongo,
               @media_collection,
               %{_id: ObjectId.decode!(id)},
               %{
                 "$set" =>
                   data
                   |> Helpers.get_changes()
                   |> Helpers.format_changes()
                   |> Helpers.update_timestamp()
               }
             ) do
        ## why accessing the databse again let's try return the result variable
        {:ok, get(%MongoDB{args: %{id: id}})}
      else
        {:error, :not_found, _} ->
          {:error, %{error: "#{@media_collection} does not exist"}}

        {data, false} ->
          ## TODO we should cover this to return a proper error in case the changeset
          ## is not valid
          {:error, %{error: data}}

        _err ->
          {:error, %{error: "Unknown DB Error"}}
      end
    end

    def delete(%MongoDB{args: %{id: id}}) do
      Mongo.delete_one(:mongo, @media_collection, %{_id: ObjectId.decode!(id)})
    end
  end
end
