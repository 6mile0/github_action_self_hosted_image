FROM debian:bullseye-slim

ARG TOKEN
ARG USERNAME
ARG REPOSITORY

ENV DL_URL=https://github.com/actions/runner/releases/download/v2.312.0/actions-runner-linux-x64-2.312.0.tar.gz

# Check if PERSONAL_ACCESS_TOKEN is set
RUN if [ -z $TOKEN ]; then echo "[Error] No token specified."; exit 1; else echo "OK"; fi

# Check if USERNAME is set
RUN if [ -z $USERNAME ]; then echo "[Error] No username specified."; exit 2; else echo "OK"; fi

# Check if REPOSITORY is set
RUN if [ -z $REPOSITORY ]; then echo "[Error] No repository name specified."; exit 2; else echo "OK"; fi

ENV RUNNER_GROUP=Default
ENV RUNNER_LABELS="self-hosted,Linux,X64"
ENV RUNNER_WORKDIR=_work

ENV TZ Asia/Tokyo

RUN apt-get update && \
    apt-get install -y curl sudo wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install .NET SDK
RUN wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN rm packages-microsoft-prod.deb

RUN apt-get update && \
    apt-get install -y dotnet-sdk-6.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN useradd runner && \
    echo "runner:runner" | chpasswd && \
    chsh -s /usr/bin/bash runner && \
    usermod -aG sudo runner && \
    mkdir /actions-runner && \
    chown runner:runner /actions-runner

USER runner
WORKDIR /actions-runner

RUN curl -fsSL -o actions-runner.tar.gz -L $DL_URL && \
    tar xf actions-runner.tar.gz && \
    rm actions-runner.tar.gz

RUN ./config.sh \
        --unattended \
        --url https://github.com/$USERNAME/$REPOSITORY \
        --token $TOKEN \
        --name `date +%s` \
        --runnergroup $RUNNER_GROUP \
        --labels $RUNNER_LABELS \
        --work $RUNNER_WORKDIR

CMD ["./run.sh"]
