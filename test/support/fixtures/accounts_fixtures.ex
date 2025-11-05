defmodule Mydia.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Mydia.Accounts` context.
  """

  alias Mydia.Accounts

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    default_attrs = %{
      username: "testuser#{System.unique_integer([:positive])}",
      email: "user#{System.unique_integer([:positive])}@example.com",
      password: "securepassword123",
      role: "user",
      display_name: "Test User"
    }

    attrs = Map.merge(default_attrs, attrs)

    {:ok, user} = Accounts.create_user(attrs)
    user
  end

  @doc """
  Generate an admin user.
  """
  def admin_user_fixture(attrs \\ %{}) do
    user_fixture(Map.merge(%{role: "admin"}, attrs))
  end
end
