FROM ghcr.io/actions/actions-runner:2.336.0

RUN sudo apt-get update \
    && sudo apt-get install -y --no-install-recommends jq curl \
    && sudo rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN sudo chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]