FROM ghcr.io/foundry-rs/foundry:latest

WORKDIR /opt/rcp

# Add Tini
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

COPY . .

CMD ["./start.sh"]

