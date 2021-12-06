FROM bitwalker/alpine-elixir-phoenix:latest

# Set exposed ports
EXPOSE 4000
ENV MIX_ENV=prod
ENV PORT=4000
ENV EMAIL_SITE_ADDRESS=$EMAIL_SITE_ADDRESS
ENV SECRET_KEY_BASE=$SECRET_KEY_BASE
ENV GUARDIAN_SECRET_KEY=$GUARDIAN_SECRET_KEY

ENV POSTGRES_PASSWORD=$POSTGRES_PASSWORD
ENV POSTGRES_USER=$POSTGRES_USER
ENV POSTGRES_DB=$POSTGRES_DB
ENV POSTGRES_HOST=$POSTGRES_HOST

RUN apk add postgresql postgresql-contrib 


# Cache elixir deps
ADD mix.exs mix.lock ./
RUN mix do deps.get, deps.compile

# Same with npm deps
ADD assets/package.json assets/
RUN cd assets && \
    npm install

ADD . .

# Run frontend build, compile, and digest assets
RUN cd assets/ && \
    npm run deploy && \
    cd - && \
    mix do compile, phx.digest

CMD ["./entrypoint.sh"]
