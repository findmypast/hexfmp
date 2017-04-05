FROM elixir:1.4

RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - \
 && apt-get install -y nodejs postgresql-client inotify-tools

# Copy whole app source
COPY . /usr/src/app

WORKDIR /usr/src/app

# Set environment variables
ENV PORT 4000
EXPOSE 4000
# Install elixir dependencies
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix do deps.get, deps.compile

# Compile phoenix app
RUN mix compile && \
    mix phx.digest

WORKDIR /usr/src/app/assets

RUN npm install

WORKDIR /usr/src/app
CMD ["mix", "phx.server"]
