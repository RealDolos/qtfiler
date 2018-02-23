defmodule Qtfile.Util do
  alias Algae.Either

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
      :ok -> Either.Right.new
      {t, v} ->
        m =
          case t do
            :ok -> Either.Right
            :error -> Either.Left
          end
        m.new v
      :error -> Either.Left.new
    end
  end

  def mapLeft(%Either.Left{left: l}, f) do
    %Either.Left{left: f.(l)}
  end

  def mapLeft(%Either.Right{} = r, _) do
    r
  end

  def tagLeft(e, t) do
    mapLeft(e, fn(v) ->
      {t, v}
    end)
  end

  def errToEitherTag(e, t) do
    e |> errToEither |> tagLeft t
  end
end
