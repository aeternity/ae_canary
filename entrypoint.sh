#!/bin/bash

while ! pg_isready -q -h $POSTGRES_HOST -U $POSTGRES_USER
do
  echo "${POSTGRES_HOST}:${POSTGRES_PORT} - [${POSTGRES_USER}]"
  echo "$(date) - waiting for database to start"
  sleep 1
done

mix ecto.setup
mix run priv/repo/exchanges.exs

exec mix phx.server
