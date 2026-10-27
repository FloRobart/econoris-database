# ============================================
# Econoris migrations image
# Contains dbmate and every migration file.
# When started, it applies the pending migrations, then exits.
# The database itself runs on the official postgres image.
# ============================================

FROM ghcr.io/amacneil/dbmate:2.36.0

# dbmate reads migrations from ./db/migrations (the image working directory is /)
COPY ./db/migrations /db/migrations

# The entrypoint of the base image is dbmate:
#   --wait            wait until the database accepts connections
#   --no-dump-schema  never regenerate db/schema.sql in production
#   up                apply pending migrations (creates the database if missing)
CMD ["--wait", "--no-dump-schema", "up"]
