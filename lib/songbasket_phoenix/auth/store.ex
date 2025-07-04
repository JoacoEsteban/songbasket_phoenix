defmodule SongbasketPhoenix.Auth.Store do
  alias SongbasketPhoenix.MemoryStore, as: Store

  def new_token do
    {public, private} = pair()
    Store.put(public, private)

    {:ok, {public, private}}
  end

  def put_user_token(public, token) do
    {:ok, private} = Store.get(public)
    key = compound_key(public, private)

    false = is_valid?(key)

    Store.put(key, token)
    :ok
  end

  def retrieve_user_token({public_key, private_key}) do
    case Store.get(compound_key(public_key, private_key)) do
      {:ok, token} ->
        :ok = invalidate({public_key, private_key})
        {:ok, token}

      error ->
        error
    end
  end

  def is_valid?(token) do
    case Store.get(token) do
      {:ok, value} when value != nil -> true
      _ -> false
    end
  end

  def is_correct?(token, expected) do
    case Store.get(token) do
      {:ok, ^expected} -> true
      _ -> false
    end
  end

  defp invalidate({public, private}) do
    Store.delete(public)
    Store.delete(compound_key(public, private))

    :ok
  end

  defp delete_key(key) do
    Store.delete(key)
  end

  defp pair do
    {rand(), rand()}
  end

  def rand do
    :crypto.strong_rand_bytes(10)
    |> Base.encode16(case: :lower)
  end

  defp compound_key(public, private) do
    public <> ":" <> private
  end
end
