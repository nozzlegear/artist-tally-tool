FROM google/dart:1@sha256:b0a3c5f4c5370c18bbcf3114bd48b4691f5bedc419eaf28d2f7b3531e4da71e9
WORKDIR /app

RUN /usr/bin/dart --version

# copy project and restore as distinct layers
COPY pubspec.* ./
RUN pub get

# copy everything else and build
COPY . ./
RUN pub get --offline
RUN dart tool/build.dart
RUN chmod u+x /app/analyze.sh
RUN /app/analyze.sh

ARG COMMIT_SHA
LABEL org.opencontainers.image.source=https://github.com/keith-m-merrick-co-inc/artist-tally-tool
LABEL org.opencontainers.image.revision=$COMMIT_SHA

CMD ["/usr/bin/dart", "/app/lib/main.dart"]
