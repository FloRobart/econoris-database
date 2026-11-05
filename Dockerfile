# Production migrations image: applies the pending migrations, then exits.

# The upstream image is only used to retrieve the statically linked dbmate binary.
# Its Alpine userland (shell, package manager, pg_dump) is not shipped in the final image.
FROM ghcr.io/amacneil/dbmate:2.36.0@sha256:520c740c6e0ad73fde2cd1ea7e2b779aaf789d22aca8858f87a478e7094535fb AS dbmate-source


# Distroless rather than dhi.io/static: the CI builds this image without any dhi.io login.
FROM gcr.io/distroless/static-debian13:nonroot@sha256:25ac8f0c3b2334a9eb05452266bd4697864a8c8ef0ef71e5e6480d7f92868329

COPY --from=dbmate-source /usr/local/bin/dbmate /usr/local/bin/dbmate

# dbmate looks for ./db/migrations, relative to the working directory
WORKDIR /
COPY ./db/migrations /db/migrations

USER 65532:65532

ENTRYPOINT ["/usr/local/bin/dbmate"]

# --no-dump-schema: the image has no pg_dump, and the schema file must never change in production
CMD ["--wait", "--no-dump-schema", "up"]
