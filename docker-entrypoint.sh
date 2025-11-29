#!/bin/bash
set -e

# Determine if we're running an interactive server or a one-off command
# If no args passed, default to phx.server
if [ $# -eq 0 ]; then
    COMMAND="mix phx.server"
    FULL_SETUP=true
else
    COMMAND="$*"
    FULL_SETUP=false
fi

# Quick commands that don't need any setup
case "$1" in
    sh|bash)
        exec "$@"
        ;;
esac

# Minimal setup for all mix commands
# CRITICAL: Clean any host-compiled NIFs that are incompatible with container
if [ -d "_build/dev/lib/exqlite" ]; then
    rm -rf _build/dev/lib/exqlite
fi

# Install Hex and Rebar if not already installed (quiet)
if [ ! -d "$MIX_HOME" ] || [ ! -f "$MIX_HOME/rebar" ]; then
    mix local.hex --force --if-missing > /dev/null 2>&1
    mix local.rebar --force > /dev/null 2>&1
fi

# Full setup only for server mode (no args passed)
if [ "$FULL_SETUP" = true ]; then
    echo "==> Starting Mydia development environment..."

    # Install Mix dependencies
    echo "==> Installing dependencies..."
    mix deps.get --only dev

    # Compile exqlite if needed
    if [ -d "deps/exqlite" ] && [ ! -f "_build/dev/lib/exqlite/priv/sqlite3_nif.so" ]; then
        echo "==> Compiling exqlite..."
        mix deps.compile exqlite
    fi

    # Setup database
    echo "==> Setting up database..."
    mix ecto.create --quiet 2>/dev/null || true
    mix mydia.backup_before_migrate
    mix ecto.migrate

    # Install and build assets if needed
    if [ ! -d "assets/node_modules" ] || [ -z "$(ls -A assets/node_modules 2>/dev/null)" ]; then
        echo "==> Installing Node.js dependencies..."
        mix assets.setup
    fi

    if [ ! -d "priv/static/assets" ] || [ -z "$(ls -A priv/static/assets 2>/dev/null)" ]; then
        echo "==> Building assets..."
        mix assets.build
    fi

    echo "==> Starting Phoenix server..."
fi

exec $COMMAND
