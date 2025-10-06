# Build stage
FROM mcr.microsoft.com/dotnet/nightly/sdk:10.0.0-rc.1 AS build

# Install native AOT prerequisites
RUN apt-get update && apt-get install -y clang zlib1g-dev && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Copy csproj and restore dependencies
COPY AotMinimalApi/AotMinimalApi.csproj AotMinimalApi/
RUN dotnet restore AotMinimalApi/AotMinimalApi.csproj

# Copy source code and build
COPY AotMinimalApi/ AotMinimalApi/
WORKDIR /src/AotMinimalApi
RUN dotnet publish -c Release -o /app/publish /p:PublishAot=true

# Runtime stage - using minimal runtime image for AOT
FROM mcr.microsoft.com/dotnet/nightly/runtime-deps:10.0.0-rc.1 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

ENTRYPOINT ["./AotMinimalApi"]
