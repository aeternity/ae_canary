defmodule AeCanary.Email do
  use Bamboo.Template, view: AeCanary.Email.NotificationView

  alias AeCanary.Accounts.User

  def notification_email(
        %User{email: email, name: name},
        exchange_name,
        addr,
        %AeCanary.Transactions.Tx{} = tx
      ) do
    new_email()
    |> to({name, email})
    |> from({"AeCanary", "canary@aeternity.io"})
    |> put_html_layout({AeCanary.Email.NotificationView, "layout.html"})
    |> put_text_layout({AeCanary.Email.NotificationView, "big_deposit.text"})
    |> subject("[AeCanary] Large deposit")
    |> assign(:name, name)
    |> assign(:tx, tx)
    |> assign(:exchange, exchange_name)
    |> assign(:addr, addr)
    |> assign(:site_address, Application.fetch_env!(:ae_canary, :site_address))
    |> render(:big_deposit)
  end

  def notification_email(
        %User{email: email, name: name},
        exchange_name,
        addr,
        %{date: _date, message: _message} = tx
      ) do
    new_email()
    |> to({name, email})
    |> from({"AeCanary", "canary@aeternity.io"})
    |> put_html_layout({AeCanary.Email.NotificationView, "layout.html"})
    |> put_text_layout({AeCanary.Email.NotificationView, "boundary.text"})
    |> subject("[AeCanary] Boundary crossed")
    |> assign(:name, name)
    |> assign(:tx, tx)
    |> assign(:exchange, exchange_name)
    |> assign(:addr, addr)
    |> assign(:site_address, Application.fetch_env!(:ae_canary, :site_address))
    |> render(:boundary)
  end

  def fork_notification_email(%User{email: email, name: name}, forkPoint, forks) do
    new_email()
    |> to({name, email})
    |> from({"AeCanary", "canary@aeternity.io"})
    |> put_html_layout({AeCanary.Email.NotificationView, "layout.html"})
    |> put_text_layout({AeCanary.Email.NotificationView, "fork_detection.text"})
    |> subject("[AeCanary] Fork detected")
    |> assign(:name, name)
    |> assign(:forkPoint, forkPoint)
    |> assign(:forks, forks)
    |> assign(:site_address, Application.fetch_env!(:ae_canary, :site_address))
    |> render(:fork_detection)
  end
end
