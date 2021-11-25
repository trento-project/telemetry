FROM golang:1.17 as go-build
ADD . /build
WORKDIR /build
RUN make build

FROM gcr.io/distroless/base:debug AS telemetry
COPY --from=go-build /build/telemetry /app/telemetry
LABEL org.opencontainers.image.source="https://github.com/trento-project/telemetry"
EXPOSE 10000/tcp
ENTRYPOINT ["/app/telemetry"]
