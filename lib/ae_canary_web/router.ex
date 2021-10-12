defmodule AeCanaryWeb.Router do
  use AeCanaryWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Our pipeline implements "maybe" authenticated. We'll use the `:ensure_auth` below for when we need to make sure someone is logged in.
  pipeline :auth do
    plug AeCanaryWeb.Accounts.Pipeline
  end

  # We use ensure_auth to fail if there is no one logged in
  pipeline :ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated
    plug AeCanaryWeb.Accounts.AddCurrentUser
  end

  pipeline :ensure_admin do
    plug AeCanaryWeb.Accounts.CheckAdmin
  end


  # Maybe logged in routes
  scope "/", AeCanaryWeb do
    pipe_through [:browser, :auth]

    get "/", PageController, :index
    get "/login", SessionController, :new
    post "/login", SessionController, :login
    get "/logout", SessionController, :logout

    # Definitely logged in scope
    scope "/" do
      pipe_through [:ensure_auth]

      ## current user account management
      scope "/account" do
        get "/", UserController, :show_my
        get "/edit", UserController, :edit_my
        put "/", UserController, :update_my
        get "/password", UserController, :edit_my_password
        post "/password", UserController, :set_my_password
      end

      scope "/exchanges", Exchanges, as: :exchanges do
        get "/dashboard", ExchangeController, :dashboard
      end
    end

    # administrator pages
    scope "/" do
      pipe_through [:ensure_auth, :ensure_admin]

      ## user management
      resources "/users", UserController
      get "/users/:id/password", UserController, :edit_password
      post "/users/:id/password", UserController, :set_password

      scope "/exchanges", Exchanges, as: :exchanges do
        resources "/exchanges", ExchangeController
        resources "/addresses", AddressController
        get "/addresses/new/:exchange_id", AddressController, :new_by_exchange
      end

    scope "/tainted", TaintedAccounts, as: :tainted_accounts do
      resources "/accounts", AccountController
    end

    scope "/settings" do
      resources "/dashboard", DashboardController
      get "/dashboard/:id/toggle", DashboardController, :toggle_active
    end

    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", AeCanaryWeb do
  #   pipe_through :api
  # end

  if Mix.env == :dev do
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: AeCanaryWeb.Telemetry
    end
  end
end
