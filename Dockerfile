#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:3.1 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:3.1 AS build
WORKDIR /src
COPY ["splunk-apm-dotnetcore-example.csproj", "."]
RUN dotnet restore "./splunk-apm-dotnetcore-example.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "splunk-apm-dotnetcore-example.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "splunk-apm-dotnetcore-example.csproj" -c Release -o /app/publish

FROM base AS final

ARG TRACER_VERSION=0.2.1
ADD https://github.com/signalfx/signalfx-dotnet-tracing/releases/download/v${TRACER_VERSION}/signalfx-dotnet-tracing_${TRACER_VERSION}_amd64.deb /signalfx-package/signalfx-dotnet-tracing.deb
RUN dpkg -i /signalfx-package/signalfx-dotnet-tracing.deb
RUN rm -rf /signalfx-package


RUN mkdir -p /var/log/signalfx/dotnet && \
    chmod a+rwx /var/log/signalfx/dotnet

ENV CORECLR_ENABLE_PROFILING=1 \
    CORECLR_PROFILER='{B4C89B0F-9908-4F73-9F59-0D77C5A06874}' \
    CORECLR_PROFILER_PATH=/opt/signalfx-dotnet-tracing/SignalFx.Tracing.ClrProfiler.Native.so \
    SIGNALFX_INTEGRATIONS=/opt/signalfx-dotnet-tracing/integrations.json \
    SIGNALFX_DOTNET_TRACER_HOME=/opt/signalfx-dotnet-tracing

WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "splunk-apm-dotnetcore-example.dll"]
