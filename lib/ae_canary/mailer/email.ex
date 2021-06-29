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
    |> subject("[AeCanary] Large deposit notification")
    |> assign(:name, name)
    |> assign(:tx, tx)
    |> assign(:exchange, exchange_name)
    |> assign(:addr, addr)
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
    |> subject("[AeCanary] Boundary crossed notification")
    |> assign(:name, name)
    |> assign(:tx, tx)
    |> assign(:exchange, exchange_name)
    |> assign(:addr, addr)
    |> render(:boundary)
  end
end
