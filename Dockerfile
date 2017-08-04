FROM google/dart:1
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
