#!/bin/sh
# Login shell for Codex Desktop SSH connections.
# Codex Desktop SSHes in and this shell starts the App Server on stdio —
# the transport is piped over the SSH connection, no port-forward needed.
exec codex app-server --listen stdio://
