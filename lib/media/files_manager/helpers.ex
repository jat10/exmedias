defmodule Media.Helpers do
  @moduledoc """
    Media.Helpers contains all the helper functions
  """

  @doc """
  Returns the router helper module from the configs. Raises if the router isn't specified.
  """
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

  def active_databse do
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
    struct(active_databse(), %{args: args})
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
    {:ok, date_time} = item["inserted_at"] |> DateTime.from_unix()
    date = date_time |> DateTime.to_string() |> String.split(" ") |> hd

    struct(
      schema,
      item
      |> Morphix.atomorphiform!()
      |> Map.put(:id, id)
      |> Map.put(:inserted_at, date)
    )
  end
end
