FROM dart:2.18
COPY . ./
WORKDIR /root/server
RUN dart pub get
RUN dart compile exe bin/server.dart
CMD [ "/root/server/bin/server.exe" ]
