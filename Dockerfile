FROM node:current-alpine

# reviewdog
ENV REVIEWDOG_VERSION=v0.11.0

RUN wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh| sh -s -- -b /usr/local/bin/ ${REVIEWDOG_VERSION}
RUN apk --update add git && \
    rm -rf /var/lib/apt/lists/* && \
    rm /var/cache/apk/*

WORKDIR /textlint
COPY package.json package-lock.json configloader.js ./
COPY prh.yml prh-rules/ ./
COPY entrypoint.sh ./
RUN npm ci

ENTRYPOINT ["/textlint/entrypoint.sh"]
