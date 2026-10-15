FROM ghcr.io/cirruslabs/flutter:stable

# Diretório de trabalho
WORKDIR /app

# Como você vai usar volumes no docker-compose, isso serve mais para agilizar a primeira execução
COPY pubspec.* ./
RUN flutter pub get

# Expor a porta do servidor de desenvolvimento do Flutter
EXPOSE 8080