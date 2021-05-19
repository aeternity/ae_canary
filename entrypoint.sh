#!/bin/bash

while ! pg_isready -q -h $POSTGRES_HOST -U $POSTGRES_USER
do
  echo "${POSTGRES_HOST}:${POSTGRES_PORT} - [${POSTGRES_USER}]"
  echo "$(date) - waiting for database to start"
  sleep 1
done

export PGPASSWORD="${POSTGRES_PASSWORD}"
if [[ `psql -Atqc "\\list ${POSTGRES_DB}" -h $POSTGRES_HOST -U $POSTGRES_USER postgres` ]]; then
  echo "Database $POSTGRES_DB already exists."
  mix ecto.migrate
else
  echo "Database $POSTGRES_DB does not exist. Creating..."
  mix ecto.setup
  mix run priv/repo/exchanges.exs
  echo "Database $POSTGRES_DB created."
fi

exec mix phx.server
