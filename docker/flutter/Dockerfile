# Ambiente de build do app (Flutter + Android SDK + JDK), pra gerar o APK sem instalar nada na máquina.
# A imagem da Cirrus Labs já traz o Android SDK; só atualizamos o Flutter, porque o pubspec exige >= 3.47.
#
# Uso (Git Bash, na raiz do repo), gera frontend/build/apk/passe-release.apk a partir da main:
#   docker build -t passe-flutter docker/flutter
#   git archive origin/main frontend | MSYS_NO_PATHCONV=1 docker run --rm -i \
#     -v "$(cd frontend && pwd -W)/build/apk:/out" -v passe-gradle-cache:/root/.gradle passe-flutter sh -c '
#       mkdir -p /work && tar -xf - -C /work && cd /work/frontend && flutter pub get &&
#       flutter build apk --release --dart-define=API_URL=https://passe-api-vlzh.onrender.com &&
#       cp build/app/outputs/flutter-apk/app-release.apk /out/passe-release.apk'
FROM ghcr.io/cirruslabs/flutter:latest

RUN git config --global --add safe.directory '*' \
 && cd "$FLUTTER_HOME" \
 && git fetch --depth 1 origin +refs/heads/stable:refs/remotes/origin/stable \
 && git checkout -B stable origin/stable \
 && rm -rf bin/cache \
 && flutter precache --android \
 && flutter --version

WORKDIR /app
