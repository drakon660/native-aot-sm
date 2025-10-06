# Build stage
FROM mcr.microsoft.com/dotnet/nightly/sdk:10.0.0-rc.1 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY StandardMinimalApi/StandardMinimalApi.csproj StandardMinimalApi/
RUN dotnet restore StandardMinimalApi/StandardMinimalApi.csproj

# Copy source code and build
COPY StandardMinimalApi/ StandardMinimalApi/
WORKDIR /src/StandardMinimalApi
RUN dotnet publish -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/nightly/aspnet:10.0.0-rc.1 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

ENTRYPOINT ["dotnet", "StandardMinimalApi.dll"]
