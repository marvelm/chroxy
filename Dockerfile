# ===== BUILDER =====
FROM hexpm/elixir:1.18.4-erlang-28.1-debian-trixie-20250908 AS builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential git curl \
      libssl-dev libncurses6 libtinfo6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENV MIX_ENV=prod

# Install Hex/Rebar
RUN mix local.hex --force && mix local.rebar --force

# Get deps
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

# Build app
COPY . .
RUN mix compile --no-deps-check
RUN mix release

# ===== RUNTIME =====
FROM linuxserver/chrome:latest

# Install minimal runtime deps
RUN apt update && \
    apt install -y --no-install-recommends libstdc++6 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

WORKDIR /app
COPY --from=builder /app/_build/prod/rel/chroxy ./chroxy

# Create non-root user and set ownership
RUN useradd -m -s /bin/sh chroxy && \
    chown -R chroxy:chroxy /app/chroxy

USER chroxy
ENV PORT=4000

EXPOSE 4000
CMD ["sh", "-c", "SHELL=/bin/sh exec /app/chroxy/bin/chroxy start"]
