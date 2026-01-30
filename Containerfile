ARG SOURCE_DISTRO
ARG SOURCE_TAG
ARG BUILD_VERSION

FROM docker.io/${SOURCE_DISTRO}:${SOURCE_TAG}

ARG SOURCE_DISTRO
ARG SOURCE_TAG
ARG BUILD_VERSION

LABEL 	org.label-schema.changelog-url="https://github.com/LearningToPi/mrtg/"
LABEL 	org.label-schema.description="Lightweight image to run MRTG to generate the image data. Map the /var/www/mrtg to an appropriate web server (none included)"
LABEL 	org.label-schema.name="mrtg"
LABEL 	org.label-schema.release="${SOURCE_DISTRO}-${SOURCE_TAG}-${BUILD_VERSION}"
LABEL 	org.label-schema.schema-version="1.0"
LABEL 	org.label-schema.usage="README.md"
LABEL 	org.label-schema.vcs-url="https://github.com/LearningToPi/mrtg"
LABEL 	org.label-schema.vendor="LearningToPi.com"
LABEL 	org.label-schema.version="${BUILD_VERSION}"
LABEL   org.opencontainers.image.base.name="${SOURCE_DISTRO}:${SOURCE_TAG}"
LABEL 	org.opencontainers.image.ref.name="${SOURCE_DISTRO}"
LABEL 	org.opencontainers.image.version="${SOURCE_TAG}"

RUN 	apt-get update && apt-get -y upgrade && apt-get -y install snmp snmp-mibs-downloader mrtg cron mrtg-ping-probe iputils-ping dnsutils lighttpd
RUN	echo '*/5 * * * * mrtg bash -c "source /tmp/env && /usr/bin/mrtg /etc/mrtg/mrtg.cfg 2>&1"' > /etc/cron.d/mrtg

ADD	lighttpd.conf /etc/lighttpd/lighttpd.conf
ADD 	entrypoint.sh /entrypoint.sh
ADD	healthcheck.sh /healthcheck.sh
ADD README.md /README.md

HEALTHCHECK	--interval=5m --timeout=60s --retries=3 CMD /healthcheck.sh

ENTRYPOINT	["/entrypoint.sh"]
