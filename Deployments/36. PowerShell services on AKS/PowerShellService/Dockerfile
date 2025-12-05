FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04

# Set working directory
WORKDIR /app

# Copy PowerShell scripts
COPY . /app

# Install Pode web framework
RUN pwsh -Command "Install-Module -Name Pode -Force -Scope AllUsers -AcceptLicense"

# Expose port
EXPOSE 8080

# Set environment variable
ENV ASPNETCORE_URLS=http://+:8080

# Run the PowerShell service
CMD ["pwsh", "-File", "/app/server.ps1"]


