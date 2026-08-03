# Stage 1: Build
FROM public.ecr.aws/amazonlinux/amazonlinux:2023 AS builder

RUN dnf update -y && \
    dnf install -y dotnet-sdk-8.0 && \
    dnf clean all

RUN dnf install -y shadow-utils && \
    groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /build

COPY --chown=appuser:appuser GadgetsOnline/GadgetsOnline.csproj GadgetsOnline/GadgetsOnline.csproj

RUN dotnet restore GadgetsOnline/GadgetsOnline.csproj

COPY --chown=appuser:appuser GadgetsOnline/ GadgetsOnline/

RUN dotnet publish GadgetsOnline/GadgetsOnline.csproj -c Release -o /app/publish --no-restore

# Stage 2: Runtime
FROM public.ecr.aws/amazonlinux/amazonlinux:2023 AS runtime

RUN dnf update -y && \
    dnf install -y aspnetcore-runtime-8.0 \
        krb5-libs \
        libicu \
        openssl-libs \
        zlib \
        fontconfig && \
    dnf clean all

RUN dnf install -y shadow-utils && \
    groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

COPY --chown=appuser:appuser --from=builder /app/publish .

USER appuser

EXPOSE 8080

ENV ASPNETCORE_URLS=http://+:8080

CMD ["dotnet", "GadgetsOnline.dll"]
