FROM dart:stable@sha256:02a254b6bf6a92f78f30d446aff485fcffd5cd1da23f632782175071eb0926e4 AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

# copy everything else and build
COPY . ./

# Ensure packages are still up-to-date if anything has changed
RUN dart pub get --offline
RUN mkdir -p ./bin
RUN dart compile exe -o ./bin/main ./lib/main.dart

# Build minimal image from AOT-compiled `/app/bin/main` and required system
# libraries and configuration files stored in `/runtime/` from the build stage.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/main /app/bin/

ARG REPO_URL
ARG COMMIT_SHA
LABEL org.opencontainers.image.source=$REPO_URL
LABEL org.opencontainers.image.revision=$COMMIT_SHA

CMD ["/app/bin/main"]
