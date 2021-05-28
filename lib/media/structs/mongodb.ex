defmodule Media.MongoDB do
  @moduledoc false
  defstruct args: []

  defimpl DB, for: Media.MongoDB do
    @media_collection "media"
    @platform_collection "platform"
    @schema_collection %{"platform" => Media.Platforms.Platform, "media" => Media.MongoDB.Schema}
    alias BSON.ObjectId
    alias Media.{Cartesian, FiltersMongoDB, Helpers, MongoDB}
    alias Media.MongoDB.Schema, as: MediaSchema
    alias Media.Platforms.Platform
    ## TO DO to be altered in next issues
    def list_platforms(_args) do
      Mongo.find(Media.Helpers.repo(), "platform", %{})
      |> Media.Helpers.format_result(schema_to_module("platform"))
    end

    @doc """
    Media.Context.list_medias(%{
        args: %{
          page: 0,
          per_page: 10,
          filters: [
            %{key: "title", value: "value"},
            %{key: "number_field", value: 10, operation: "<"}
          ],
          sort: %{title: "desc"}
        }
      })

    """
    def list_medias(%MongoDB{args: args}) do
      pagination_pipe =
        Helpers.build_pagination(
          Helpers.extract_param(args, :page),
          Helpers.extract_param(args, :per_page)
        )
        |> case do
          {0, 0} ->
            []

          {offset, limit} ->
            [
              %{"$skip" => offset},
              %{"$limit" => limit}
            ]
        end

      ## We build the filters and valdiate them
      {sort_pipe, filters_pipe} =
        with {:ok, %{filter: filters, sort: sort, operation: operations}} <-
               args |> Helpers.build_params(),
             sort <- handle_sort(sort),
             {sort, []} <-
               {sort,
                FiltersMongoDB.init(
                  filters
                  |> Cartesian.possible_combinations(),
                  operations
                )} do
          {[], sort}
        else
          {:error, error} ->
            error

          {sort, {computed_filters, normal_filters}} ->
            ## this can be used later for further computations
            ## so we can optimize our query (running the normal filters first for ex.)
            # initial_computations ++
            {sort,
             format_fitlers(normal_filters) ++
               format_fitlers(computed_filters)}
        end

      query_media(filters_pipe, sort_pipe, pagination_pipe)
    end

    # filters to pipeline
    defp format_fitlers(filters) do
      if filters == [], do: [], else: [%{"$match" => %{"$and" => filters}}]
    end

    defp handle_sort(sort) when is_map(sort) do
      sort
      |> Map.values()
      |> List.first()
      |> String.downcase()
      |> case do
        "desc" -> 0
        "asc" -> 1
      end
    end

    defp handle_sort(nil), do: []

    # def get_media(%MongoDB{args: id}) do
    #   case get_full_media(id) do
    #     [] ->
    #       {:error, :not_found, "media"}

    #     item ->
    #       item |> Map.get(:result) |> Enum.at(0)
    #   end
    # end

    def insert_media(args), do: insert(args, @media_collection)

    ## Bwhen submitting the form this will be called inside the controller after the file management is done
    def update_media(%MongoDB{args: %{id: id} = args}) do
      with %MediaSchema{} = media <- get(%MongoDB{args: id}, @media_collection),
           data <- MediaSchema.changeset(media, args),
           {_data, true} <- {data, data.valid?} do
        update(data, id, @media_collection)
      else
        {:error, :not_found, _collection} ->
          {:error, %{error: "#{@media_collection} does not exist"}}

        {data, false} ->
          ## TO DO we should cover this to return a proper error in case the changeset
          ## is not valid
          {:error, data}
      end
    end

    def delete_media(args), do: delete(args, @media_collection)
    def get_platform(args), do: get(args, @platform_collection)
    def insert_platform(args), do: insert(args, @platform_collection)

    def update_platform(%MongoDB{args: %{id: id} = args} = platform) do
      with %Platform{} = platform <- get(platform, @platform_collection),
           data <- Platform.changeset(platform, args),
           {_data, true} <- {data, data.valid?} do
        update(args, id, @platform_collection)
      else
        {:error, :not_found, _collection} ->
          {:error, %{error: "#{@platform_collection} does not exist"}}

        {data, false} ->
          ## TO DO we should cover this to return a proper error in case the changeset
          ## is not valid
          {:error, data}
      end
    end

    def delete_platform(args), do: delete(args, @platform_collection)

    def get_media(%MongoDB{args: id}) do
      with true <- Helpers.valid_object_id?(id), %{total: 0} <- get_full_media(id) do
        {:error, :not_found, @media_collection |> String.capitalize()}
      else
        %{result: result} ->
          {:ok, result |> List.first()}

        false ->
          {:error, Helpers.id_error_message(id)}
      end
    end

    def get(%MongoDB{args: id}, collection) do
      case Mongo.find_one(:mongo, collection, %{_id: ObjectId.decode!(id)}) do
        nil ->
          {:error, :not_found, collection |> String.capitalize()}

        item ->
          Helpers.format_item(item, schema_to_module(collection), id)
      end
    end

    def get_full_media(id) do
      id = ObjectId.decode!(id)

      initial_pipeline = [
        %{"$match" => %{"_id" => id}}
      ]

      query_media(initial_pipeline)
    end

    def query_media(filters_pipe, sort_pipe \\ [], pagintaion_pipe \\ []) do
      add_number_contents = [
        %{"$addFields" => %{"number_of_contents" => %{"$size" => "$contents_used"}}}
      ]

      pipeline = [
        %{
          "$facet" => %{
            "result" =>
              add_number_contents ++
                filters_pipe ++
                pagintaion_pipe ++
                sort_pipe ++
                [
                  %{
                    "$lookup" => %{
                      "from" => "platform",
                      "localField" => "files.platform_id",
                      "foreignField" => "_id",
                      "as" => "platforms"
                    }
                  },
                  %{
                    "$addFields" => %{
                      "files" => %{
                        "$map" => %{
                          "input" => "$files",
                          "in" => %{
                            "$mergeObjects" => [
                              "$$this",
                              %{
                                "platform" => %{
                                  "$arrayElemAt" => [
                                    "$platforms",
                                    %{
                                      "$indexOfArray" => [
                                        "$platforms._id",
                                        "$$this.platform_id"
                                      ]
                                    }
                                  ]
                                }
                              }
                            ]
                          }
                        }
                      }
                    }
                  }
                ],
            "total" => add_number_contents ++ filters_pipe ++ [%{"$count" => "count"}]
          }
        }
      ]

      %{"result" => result, "total" => total} =
        Mongo.aggregate(Helpers.repo(), "media", pipeline)
        |> Enum.to_list()
        |> Enum.at(0)

      # total =

      %{
        result: Helpers.format_result(result, schema_to_module("media")),
        total: total |> Enum.at(0, %{}) |> Map.get("count", 0)
      }
    end

    # defp handle_count(collection, filter) do
    #   case Mongo.count_documents(Helpers.repo(), collection, filter) do
    #     {:ok, count} when is_integer(count) ->
    #       count

    #     {:error, _} ->
    #       0

    #     _ ->
    #       0
    #   end
    # end

    # defp media_by_id(id) do
    #   Mongo.find_one(Helpers.repo(), @media_collection, %{_id: ObjectId.decode!(id)})
    #   |> case do
    #     nil -> {:error, :not_found, @media_collection}
    #     item -> item
    #   end
    # end

    def insert(%MongoDB{args: args}, collection) do
      module = schema_to_module(collection)
      # data = Media.changeset(%Media{}, args) equivalent to the line below
      data = apply(module, :changeset, [module |> struct(%{}), args])

      with true <- data.valid?,
           {:ok, result} <-
             Mongo.insert_one(Helpers.repo(), collection, Helpers.get_changes(data)) do
        {:ok, get(%MongoDB{args: ObjectId.encode!(result.inserted_id)}, collection)}
      else
        {:error, %{write_errors: [%{"code" => 11_000}]}} ->
          {:error, "#{collection |> String.capitalize()} already exists"}

        false ->
          {:error, data}

        _err ->
          {:error, %{error: "Unknown DB Error"}}
      end
    end

    ## TO DO work this out to be generic
    def update(data, id, collection) do
      case Mongo.update_one(
             Helpers.repo(),
             collection,
             %{_id: ObjectId.decode!(id)},
             %{
               "$set" =>
                 data
                 |> Helpers.get_changes()
                 |> Helpers.format_changes()
                 |> Helpers.update_timestamp()
             }
           ) do
        {:ok, _result} ->
          ## why accessing the databse again let's try return the result variable
          {:ok, get(%MongoDB{args: id}, collection)}

        _err ->
          {:error, %{error: "Unknown DB Error"}}
      end
    end

    def delete(%MongoDB{args: id}, collection) do
      Mongo.delete_one(Helpers.repo(), collection, %{_id: ObjectId.decode!(id)})
      |> case do
        {:ok, %{deleted_count: 1}} ->
          {:ok, "#{collection |> String.capitalize()} with id #{id} deleted successfully"}

        {:ok, %{deleted_count: 0}} ->
          {:error, "#{collection |> String.capitalize()} does not exists"}
      end
    end

    defp schema_to_module(collection) do
      @schema_collection[collection]
    end
  end
end
