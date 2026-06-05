FROM dart:stable

WORKDIR /app

COPY pubspec.yaml /app/pubspec.yaml
COPY lib /app/lib
COPY bin /app/bin

RUN dart pub get

EXPOSE 8100

CMD ["dart", "run", "bin/bridge_server.dart"]
