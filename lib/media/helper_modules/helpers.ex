defmodule Media.Helpers do
  @moduledoc false
  alias BSON.ObjectId
  alias Ecto.Changeset

  alias Media.{MongoDB, PostgreSQL}
  @media_collection "media"
  @platform_collection "platform"
  # Returns the router helper module from the configs. Raises if the router isn't specified.
  @spec router() :: atom()
  def router do
    case env(:router) do
      nil -> raise "The :router config must be specified: config :media, router: MyAppWeb.Router"
      r -> r
    end
    |> Module.concat(Helpers)
  end

  def env(key, default \\ nil) do
    Application.get_env(:media, key)
    |> case do
      nil -> default
      value -> value
    end
  end

  def active_database do
    Application.get_env(:media, :active_database)
    |> case do
      "mongoDB" ->
        %MongoDB{}

      "postgreSQL" ->
        %PostgreSQL{}

      _ ->
        raise "Please configure your active database for :media application, accepted values for :active_database are ``mongoDB`` or ``postgreSQL``"
    end
  end

  def repo do
    Application.get_env(:media, :repo)
    |> case do
      nil ->
        raise "Please make sure to configure your repo under for the :media app, i.e: repo: MyApp.Repo or if it is a mongoDB repo: :mongo where mongo is the name of the MongoDB application."

      repo ->
        repo
    end
  end

  def db_struct(args) do
    struct(active_database(), %{args: args})
  end

  def get_changes(data) do
    changes =
      data.changes
      |> Enum.reduce(%{}, fn change, acc ->
        change |> format_data_changes() |> Map.merge(acc)
      end)

    data.data
    |> format_data()
    |> Map.merge(changes)
    |> add_timestamps()
  end

  defp add_timestamps(data) when is_map(data) do
    creation_time = System.system_time(:second)
    Map.merge(data, %{inserted_at: creation_time, updated_at: creation_time})
  end

  def update_timestamp(data) when is_map(data) do
    Map.put(data, :updated_at, System.system_time(:second))
  end

  defp format_data(data) do
    data
    |> Map.from_struct()
    |> Map.drop([:__meta__])
  end

  defp format_data_changes(%{limit: limits} = changes) do
    limits =
      Enum.map(limits, fn limit ->
        limit |> Map.from_struct() |> Map.get(:changes)
      end)

    Map.put(changes, :limit, limits)
  end

  defp format_data_changes({key, value}) when is_list(value) do
    Map.put(
      %{},
      key,
      Enum.map(
        value,
        fn v ->
          if is_struct(v) do
            v.changes
          else
            v
          end
        end
      )
    )
  end

  defp format_data_changes({key, value}) when is_struct(value) do
    Map.put(%{}, key, value.changes)
  end

  defp format_data_changes({key, value}), do: Map.put(%{}, key, value)

  def format_changes(changes) do
    Enum.map(changes, &format_change/1) |> Enum.into(%{})
  end

  def format_change({field, %Ecto.Changeset{changes: _changes} = changeset}) do
    changeset
    |> format_change()
    |> (&Tuple.append({field}, &1)).()
  end

  def format_change(%Ecto.Changeset{changes: _changes} = changeset) do
    changeset
    |> Changeset.apply_changes()
    |> Map.from_struct()
    |> Map.drop([:id])
  end

  def format_change({field, data}) when is_list(data) do
    data
    |> Enum.map(&format_change/1)
    |> (&Tuple.append({field}, &1)).()
  end

  def format_change(field) do
    field
  end

  def format_item(item, schema, id) do
    {:ok, date_time} =
      (Map.get(item, "inserted_at") || Map.get(item, :inserted_at)) |> DateTime.from_unix()

    date = date_time |> DateTime.to_string() |> String.split(" ") |> hd

    struct(
      schema,
      item
      |> Morphix.atomorphiform!()
      |> Map.put(:id, id)
      |> Map.put(:inserted_at, date)
    )
  end

  def create_collections do
    Mongo.command(repo(), %{
      createIndexes: @media_collection,
      indexes: [
        %{key: %{author: 1}, name: "name_idx", unique: false},
        %{key: %{type: 1}, name: "type_idx", unique: false},
        %{key: %{contents_used: 1}, name: "contents_idx", unique: false}
      ]
    })

    Mongo.command(repo(), %{
      createIndexes: @platform_collection,
      indexes: [
        %{key: %{name: 1}, name: "name_idx", unique: true}
      ]
    })
  end

  def format_result(result, schema) do
    result
    |> Enum.to_list()
    |> Enum.map(fn x ->
      converted_map = x |> Morphix.atomorphiform!()

      struct(
        schema,
        converted_map
        |> Map.put(:id, ObjectId.encode!(converted_map._id))
      )
    end)
  end

  @doc """
  Convert map string keys to :atom keys
  """
  def atomize_keys(nil), do: nil

  # Structs don't do enumerable and anyway the keys are already
  # atoms
  def atomize_keys(%{__struct__: _} = struct) do
    struct
  end

  def atomize_keys(%{} = map) do
    map
    |> Enum.map(fn {k, v} -> {atomize(k), atomize_keys(v)} end)
    |> Enum.into(%{})
  end

  # Walk the list and atomize the keys of
  # of any map members
  def atomize_keys([head | rest]) do
    [atomize_keys(head) | atomize_keys(rest)]
  end

  def atomize_keys(not_a_map) do
    not_a_map
  end

  defp atomize(k) when is_binary(k) do
    String.to_atom(k)
  end

  defp atomize(k) when is_atom(k) do
    k
  end

  def build_pagination(_offset, nil), do: {0, 0}

  def build_pagination(offset, limit) when is_integer(offset) and is_integer(limit) do
    offset = limit * (if(offset == 0, do: 1, else: offset) - 1)
    {offset, limit}
  end

  def build_pagination(offset, limit) when is_binary(offset) and is_binary(limit) do
    with {offset, _} <- Integer.parse(offset), {limit, _} <- Integer.parse(limit) do
      offset = limit * (if(offset == 0, do: 1, else: offset) - 1)
      {offset, limit}
    else
      _ -> {0, 0}
    end
  end

  def build_pagination(_offset, _limit), do: {0, 0}
  def extract_param(args, key, default \\ nil)

  def extract_param(args, key, default) when key |> is_binary,
    do: Map.get(args, key |> String.to_atom()) || Map.get(args, key) || default

  def extract_param(args, key, default) when key |> is_atom,
    do: Map.get(args, key) || Map.get(args, key |> Atom.to_string()) || default

  ### FILTERS HELPERS ###

  def build_params(params) do
    case build_args(params) do
      {:ok, new_args} ->
        {:ok, new_args}

      {:error, %{errors: errors}} ->
        {:error, message: "Invalid data provided", errors: errors}

      {:error, error} ->
        {:error, message: "Invalid data provided", errors: error}
    end
  end

  def build_args(args) do
    filters = extract_param(args, :filters, [])

    {new_filter, operation} = filters |> format_filter_post

    res = %{
      filter: new_filter,
      operation: operation,
      sort: args |> extract_param(:sort) |> build_sorts()
    }

    case res |> check_error_operation do
      :ok ->
        {:ok, res}

      :error ->
        {:error, "Between operation should contain value and value2"}
    end
  end

  def check_error_operation(%{operation: op}) do
    {_suc, error} = Enum.split_with(op, fn {_k, v} -> v != "error" end)

    if error != [] do
      :error
    else
      :ok
    end
  end

  def format_filter_post(nil) do
    {[], []}
  end

  def format_filter_post(filters) when is_list(filters) do
    case filters do
      [] ->
        {[], %{}}

      _ ->
        Enum.reduce(filters, {[], %{}}, fn filter, {fil, operation} ->
          {op, val} = get_op(filter)

          {
            if val != [] do
              fil
              |> List.insert_at(
                -1,
                cartesian([filter |> extract_param("key")], [val])
              )
            else
              fil
            end,
            if op != nil do
              operation
              |> Map.put(extract_param(filter, "key"), op)
            else
              operation
            end
          }
        end)
    end
  end

  defp get_op(filter) do
    op = extract_param(filter, :operation)
    val = extract_param(filter, :value)
    val2 = extract_param(filter, :value2)

    if op == "between" and (val == nil or val2 == nil) do
      {"error", val}
    else
      if op != "between",
        do: {%{"operation" => op}, val},
        else: {%{"operation" => op, "from" => val, "to" => val2}, val}
    end
  end

  def build_sorts(nil), do: nil
  def build_sorts(sorts) when sorts == %{}, do: nil

  def build_sorts(sorts) do
    res = sorts |> Enum.unzip()

    Enum.zip(res |> elem(0), res |> elem(1))
    |> Enum.into(%{}, &convert_sorts/1)
  end

  defp convert_sorts({_key, ""}) do
    nil
  end

  defp convert_sorts({"created", value}) do
    {"inserted_at", build_sort_value(value)}
  end

  defp convert_sorts({"updated", value}) do
    {"updated_at", build_sort_value(value)}
  end

  defp convert_sorts({key, value}) do
    {key, build_sort_value(value)}
  end

  defp build_sort_value(value) when value in ["desc", "DESC", "dsc", "DSC"] do
    "desc"
  end

  defp build_sort_value(value) when value in ["asc", "ASC"] do
    "asc"
  end

  defp build_sort_value(_value) do
    nil
  end

  def cartesian(key, value) do
    for i <- key,
        j <- value,
        do: %{i => j}
  end

  ### FILTERS HELPERS ###

  def binary_is_integer?(:error), do: false
  def binary_is_integer?({_duration, _}), do: true

  def valid_object_id?(id) when is_binary(id) do
    String.match?(id, ~r/^[0-9a-f]{24}$/)
  end

  def valid_object_id?(_id), do: false

  def valid_postgres_id?(id) when is_integer(id), do: true
  def valid_postgres_id?(id) when is_binary(id), do: binary_is_integer?(Integer.parse(id))
  def valid_postgres_id?(_id), do: false

  def id_error_message(id),
    do: "The id provided: #{inspect(id)} is not valid. Please provide a valid object ID."
end
