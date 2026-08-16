FROM ghcr.io/actions/actions-runner:2.336.0

RUN sudo apt-get update \
    && sudo apt-get install -y --no-install-recommends \
        jq curl xz-utils unzip zip \
        docker.io \
        openjdk-17-jdk-headless \
    && sudo rm -rf /var/lib/apt/lists/*

# Android SDK: only the cmdline-tools bootstrap + platform-tools are baked
# into the image. Everything else a build actually needs (platforms,
# build-tools, NDK) is auto-downloaded by the Android Gradle Plugin on the
# first `flutter build apk`, landing under ANDROID_SDK_ROOT — a persisted
# named volume (see docker-compose.yml), so it's paid for once, not on every
# job, same reasoning as the _work/.pub-cache volumes.
ENV ANDROID_SDK_ROOT=/home/runner/android-sdk
ENV PATH="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

RUN CMDLINE_TOOLS_VERSION=11076708 \
    && curl -fsSL -o /tmp/cmdline-tools.zip "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VERSION}_latest.zip" \
    && mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools" \
    && unzip -q /tmp/cmdline-tools.zip -d "${ANDROID_SDK_ROOT}/cmdline-tools" \
    && mv "${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools" "${ANDROID_SDK_ROOT}/cmdline-tools/latest" \
    && rm /tmp/cmdline-tools.zip \
    && yes | sdkmanager --licenses > /dev/null \
    && sdkmanager --install "platform-tools" > /dev/null

COPY entrypoint.sh /entrypoint.sh
RUN sudo chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]