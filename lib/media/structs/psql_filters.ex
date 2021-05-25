defmodule Media.FiltersPostgreSQL do
  @moduledoc """
  Filters
  """
  # alias Media.Helpers
  # alias Media.PostgreSQL
  @computed_filters ["number_of_contents"]
  import Ecto.Query

  # def add_offset(query, offset) do
  #   if offset != 0 do
  #     query
  #     |> offset(^offset)
  #   else
  #     query
  #   end
  # end

  def add_sort(query, nil), do: query
  def add_sort(query, sort) when sort == %{}, do: query

  def add_sort(query, sort) do
    [field | _tail] = sort |> Map.keys()
    direction = sort[field]

    field =
      cond do
        is_binary(field) -> String.to_atom(field)
        is_atom(field) -> field
        true -> raise "Sorted field can only be an atom or a string"
      end

    with false <- is_nil(direction),
         direction <- direction |> String.downcase() |> String.to_atom(),
         true <- direction in [:desc, :asc] do
      query
      |> order_by([p], [{^direction, field(p, ^field)}])
    else
      _ -> query
    end
  end

  def add_limit(query, limit) do
    if limit != 0 do
      query
      |> limit(^limit)
    else
      query
    end
  end

  def init(query, filters, op \\ %{})

  def init(query, filters, _op) when filters == [],
    do: query

  def init(query, filters, op) when is_list(filters) do
    ## remove the computed filter from here
    {computed_op, op} = Map.split(op, @computed_filters)

    {computed_filters, filters} =
      Enum.split_with(filters |> Enum.at(0), fn filter ->
        (Map.keys(filter) |> Enum.at(0)) in @computed_filters
      end)

    filters = [filters]

    conditions =
      Enum.reduce(filters, false, fn filter, condition ->
        dynamic(^build_where_and(filter, op) or ^condition)
      end)

    if computed_filters == [] do
      query
      |> where(^conditions)
    else
      computed_filters = computed_filters(query, computed_filters, computed_op)

      query
      |> having(^computed_filters)
      |> where(^conditions)
    end
  end

  def init(query, _filters, _op), do: query

  def computed_filters(_query, filters, _op) when filters == [] do
    dynamic([], ^true or ^false)
  end

  def computed_filters(query, filters, op) do
    ## I should accumulate into dynamic and not query
    Enum.reduce(filters, true, fn filter, dynamic ->
      dynamic((^add_computed_condition(query, filter, op) and ^dynamic) or false)
    end)
  end

  # =, <, >, <=, >=, <>
  def add_computed_condition(_query, %{"number_of_contents" => value}, op) do
    operation = op["number_of_contents"]["operation"]
    value = if is_binary(value), do: value |> String.to_integer(), else: value

    case operation do
      "=" ->
        dynamic([p], fragment("COUNT(?) = ?", p.id, ^value))

      "<" ->
        dynamic([p], fragment("COUNT(?) < ?", p.id, ^value))

      ">" ->
        dynamic([p], fragment("COUNT(?) > ?", p.id, ^value))

      "<=" ->
        dynamic([p], fragment("COUNT(?) <= ?", p.id, ^value))

      ">=" ->
        dynamic([p], fragment("COUNT(?) >= ?", p.id, ^value))

      "<>" ->
        dynamic_between(op)

      "between" ->
        dynamic_between(op)
    end
  end

  defp dynamic_between(op) do
    from = Map.get(op["number_of_contents"], "from", "0") |> Integer.parse() |> elem(0)
    to = Map.get(op["number_of_contents"], "to", "0") |> Integer.parse() |> elem(0)
    dynamic([p], fragment("COUNT(?) > ? and COUNT(?) < ?", p.id, ^from, p.id, ^to))
  end

  def build_where_and(filter, op) do
    Enum.reduce(filter, true, fn
      %{"title" => value}, dynamic ->
        dynamic([p], ^dynamic and p.title == ^value)

      %{"author" => value}, dynamic ->
        dynamic([p], ^dynamic and p.author == ^value)

      %{"private_status" => value}, dynamic ->
        dynamic([p], ^dynamic and p.private_status == ^value)

      %{"locked_status" => value}, dynamic ->
        ## to do check if the dates need more processing
        dynamic([p], ^dynamic and p.locked_status == ^value)

      in_table, dynamic ->
        in_table(in_table, dynamic, op)
    end)
  end

  defp in_table(in_table, dynamic, _op) do
    key_string = in_table |> Map.keys() |> Enum.at(0)
    key_atom = key_string |> String.to_atom()
    value = in_table[key_string]

    case key_string do
      "title_alike" ->
        dynamic(
          [p],
          ^dynamic and
            fragment(
              "LOWER(?) ~ LOWER(?)",
              p.title,
              ^value
            )
        )

      _ ->
        dynamic([p], ^dynamic and field(p, ^key_atom) == ^value)
    end
  end

  # defp convert_to_string(duration) do
  #   cond do
  #     is_binary(duration) ->
  #       {int, _} = Integer.parse(duration)
  #       Integer.to_string(int)

  #     is_integer(duration) ->
  #       Integer.to_string(duration)

  #     is_float(duration) ->
  #       duration |> Float.to_string()
  #   end
  # end
end
