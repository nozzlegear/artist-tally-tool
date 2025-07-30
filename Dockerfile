FROM google/dart:1@sha256:b0a3c5f4c5370c18bbcf3114bd48b4691f5bedc419eaf28d2f7b3531e4da71e9
WORKDIR /app

# Install dos2unix for executing the analyze.sh file
RUN apt-get update
RUN apt-get install dos2unix

# copy project and restore as distinct layers
COPY pubspec.* ./
RUN pub get

# copy everything else and build
COPY . ./
RUN dos2unix /app/analyze.sh
RUN pub get --offline
RUN dart tool/build.dart
RUN chmod u+x /app/analyze.sh
RUN /app/analyze.sh

RUN /usr/bin/dart --version

CMD ["/usr/bin/dart", "/app/lib/main.dart"]
