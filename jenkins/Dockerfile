FROM jenkins/jenkins:lts-jdk17
USER root
RUN apt-get update \
    && apt-get install -y python3 python3-venv python3-pip curl ca-certificates docker.io \
    && curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && rm -rf /var/lib/apt/lists/*
# Stay root so Jenkins can use the Docker socket (fine for a college demo).
USER root
