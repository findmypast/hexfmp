FROM elixir:1.4
RUN mix local.hex --force && \
    mix local.rebar --force

# Install tini entrypoint
ENV TINI_VERSION v0.13.1
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - \
 && apt-get install -y nodejs postgresql-client inotify-tools

# Copy whole app source
COPY . /usr/src/app

WORKDIR /usr/src/app

# Set environment variables
ENV PORT 4000
EXPOSE 4000

# Install elixir dependencies
RUN mix do deps.get, deps.compile

WORKDIR /usr/src/app/assets

RUN npm install -g brunch
RUN npm install
RUN brunch build --production

WORKDIR /usr/src/app

# Compile phoenix app
RUN mix compile && \
    mix phx.digest
    
ENTRYPOINT ["/tini", "--"]

CMD ["mix", "phx.server"]
