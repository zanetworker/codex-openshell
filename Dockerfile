FROM registry.access.redhat.com/ubi9/ubi

RUN dnf install -y \
    iproute shadow-utils \
    && dnf clean all

ARG TARGETARCH
ARG CODEX_VERSION=0.147.0
RUN case "${TARGETARCH}" in \
        amd64)  CODEX_ARCH="x86_64-unknown-linux-musl" ;; \
        arm64)  CODEX_ARCH="aarch64-unknown-linux-musl" ;; \
        *) echo "Unsupported arch: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    curl -fsSL \
        "https://github.com/openai/codex/releases/download/rust-v${CODEX_VERSION}/codex-${CODEX_ARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin/ \
    && mv /usr/local/bin/codex-${CODEX_ARCH} /usr/local/bin/codex \
    && chmod +x /usr/local/bin/codex

# codex-ssh-shell is the login shell for Codex Desktop SSH connections.
# OpenShell's SSH relay execs this via the supervisor (no sshd needed).
# Must be in /etc/shells — supervisor validates before startup hardening.
COPY codex-ssh-shell.sh /usr/local/bin/codex-ssh-shell
RUN chmod +x /usr/local/bin/codex-ssh-shell \
    && echo "/usr/local/bin/codex-ssh-shell" >> /etc/shells

# No baked-in user — OpenShell assigns the UID at runtime and chowns /sandbox.
# /sandbox is world-writable so any runtime UID can use it.
RUN install -d /sandbox && chmod 1777 /sandbox

WORKDIR /sandbox

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 8888

CMD ["/usr/local/bin/start.sh"]
