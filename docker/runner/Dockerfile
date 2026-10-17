ARG RUNNER_IMAGE
ARG PLAYWRIGHT_RUNNER_IMAGE
FROM ${PLAYWRIGHT_RUNNER_IMAGE} AS playwright
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/playwright
WORKDIR /workspace
COPY package.json package-lock.json ./
COPY .runtime/template-package/ .runtime/
RUN npm ci --ignore-scripts --no-audit --no-fund \
    && npx --no-install playwright install --with-deps chromium \
    && chmod -R a+rX /opt/playwright
ENV PATH=/workspace/node_modules/.bin:$PATH
HEALTHCHECK --interval=3s --timeout=3s --retries=20 \
    CMD node -e "const fs=require('fs');if(!fs.existsSync(require('@playwright/test').chromium.executablePath()))process.exit(1)"
CMD ["node", "-e", "setInterval(() => {}, 3600000)"]

FROM ${RUNNER_IMAGE} AS cypress
RUN apt-get update \
    && apt-get install -y --no-install-recommends xvfb x11vnc novnc websockify openbox x11-utils x11-xserver-utils \
    && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix
ENV CYPRESS_CACHE_FOLDER=/opt/cypress
ENV DISPLAY=:99
WORKDIR /workspace
COPY package.json package-lock.json ./
COPY .runtime/template-package/ .runtime/
RUN npm ci --no-audit --no-fund && chmod -R a+rwX /opt/cypress
ENV PATH=/workspace/node_modules/.bin:$PATH
COPY docker/runner/desktop.sh /opt/magelens/desktop.sh
COPY docker/runner/healthcheck.cjs /opt/magelens/healthcheck.cjs
HEALTHCHECK --interval=3s --timeout=3s --start-period=10s --retries=20 \
    CMD xdpyinfo -display "$DISPLAY" >/dev/null 2>&1 && node /opt/magelens/healthcheck.cjs
CMD ["bash", "/opt/magelens/desktop.sh"]
