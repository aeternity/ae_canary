defmodule AeCanary.Settings do
  @moduledoc """
  The Settings context.
  """

  import Ecto.Query, warn: false
  alias AeCanary.Repo

  alias AeCanary.Settings.Dashboard

  @doc """
  Returns the list of dashboard.

  ## Examples

      iex> list_dashboard()
      [%Dashboard{}, ...]

  """
  def list_dashboard do
    Repo.all(Dashboard)
  end

  def active_dashboard_messages do
    from(msg in Dashboard,
      where: msg.active == true,
      order_by: [desc: msg.date]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single dashboard.

  Raises `Ecto.NoResultsError` if the Dashboard does not exist.

  ## Examples

      iex> get_dashboard!(123)
      %Dashboard{}

      iex> get_dashboard!(456)
      ** (Ecto.NoResultsError)

  """
  def get_dashboard!(id), do: Repo.get!(Dashboard, id)

  @doc """
  Creates a dashboard.

  ## Examples

      iex> create_dashboard(%{field: value})
      {:ok, %Dashboard{}}

      iex> create_dashboard(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_dashboard(attrs \\ %{}) do
    %Dashboard{}
    |> Dashboard.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a dashboard.

  ## Examples

      iex> update_dashboard(dashboard, %{field: new_value})
      {:ok, %Dashboard{}}

      iex> update_dashboard(dashboard, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_dashboard(%Dashboard{} = dashboard, attrs) do
    dashboard
    |> Dashboard.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a dashboard.

  ## Examples

      iex> delete_dashboard(dashboard)
      {:ok, %Dashboard{}}

      iex> delete_dashboard(dashboard)
      {:error, %Ecto.Changeset{}}

  """
  def delete_dashboard(%Dashboard{} = dashboard) do
    Repo.delete(dashboard)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking dashboard changes.

  ## Examples

      iex> change_dashboard(dashboard)
      %Ecto.Changeset{data: %Dashboard{}}

  """
  def change_dashboard(%Dashboard{} = dashboard, attrs \\ %{}) do
    Dashboard.changeset(dashboard, attrs)
  end
end
