defmodule Qtfile.Util do
  alias Algae.Either.{Left, Right}

  def get_ip_address(%{remote_ip: ip}) do
    Qtfile.IPAddressObfuscation.normalise_ip_address(ip)
  end

  def mapSequence(list, mapping) do
    List.foldr(list, {:ok, []}, fn(x, exs) ->
      case {mapping.(x), exs} do
        {{:ok, x}, {:ok, xs}} -> {:ok, [x | xs]}
        _ -> :error
      end
    end)
  end

  def multiDelete(map, keys) do
    Enum.reduce(keys, map, fn (n, c) ->
      Map.delete(c, n)
    end)
  end

  def multiPut(map, kvpairs) do
    Enum.reduce(kvpairs, map, fn ({k, v}, c) ->
      Map.put(c, k, v)
    end)
  end

  def errToEither(e) do
    case e do
      :ok -> Right.new
      {t, v} ->
        m =
          case t do
            :ok -> Right
            :error -> Left
          end
        m.new v
      :error -> Left.new
    end
  end

  def nilToEither(n) do
    case n do
      nil -> Left.new
      x -> Right.new(x)
    end
  end

  def mapLeft(%Left{left: l}, f) do
    %Left{left: f.(l)}
  end

  def mapLeft(%Right{} = r, _) do
    r
  end

  def tagLeft(e, t) do
    mapLeft(e, fn(v) ->
      {t, v}
    end)
  end

  def errToEitherTag(e, t) do
    e |> errToEither |> tagLeft(t)
  end

  def nilToEitherTag(e, t) do
    e |> nilToEither |> tagLeft(t)
  end

  def convert_setting(%{value: v, type: "int"}) do
    case Integer.parse(v) do
      {i, <<>>} -> Right.new(i)
      _ -> Left.new(:could_not_parse_int)
    end
  end

  def convert_setting(%{value: "true", type: "bool"}) do
    Right.new(true)
  end

  def convert_setting(%{value: "false", type: "bool"}) do
    Right.new(false)
  end

  def convert_setting(%{value: _, type: "bool"}) do
    Left.new(:could_not_parse_bool)
  end

  def convert_setting(%{value: _, type: _}) do
    Left.new(:could_not_recognise_setting_type)
  end

  def convert_setting(%{}) do
    Left.new(:invalid_setting)
  end
end
