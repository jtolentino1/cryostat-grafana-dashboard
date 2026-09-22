FROM quay.io/centos/centos:stream9-minimal@sha256:3d8e44f855b4649f6fb52952734b9396d2e12a51d471e70aab7aea9d518fe915
ARG UID=101
ARG PORT=3000
ARG GRAFANA_VERSION=12.4.11

WORKDIR /usr/share/grafana
ENV VERSION=${GRAFANA_VERSION}
ENV GF_PATHS_HOME=/usr/share/grafana
ENV HOME=/usr/share/grafana
ENV GF_PATHS_PROVISIONING=/etc/grafana/provisioning
ENV GF_PATHS_DATA=/var/lib/grafana
ENV GF_PATHS_LOGS=/var/log/grafana
ENV GF_PATHS_PLUGINS=/var/lib/grafana/plugins
ENV GF_PATHS_CONFIG=/etc/grafana/grafana.ini

LABEL name="cryostat/cryostat-grafana-dashboard" \
      version="${VERSION}" \
      usage="podman run -d --name grafana -p ${PORT}:${PORT} -v grafana-data:${GF_PATHS_DATA} quay.io/cryostat/cryostat-grafana-dashboard" \
      maintainer="Cryostat Maintainers <cryostat-development@googlegroups.com>" \
      io.k8s.display-name="Grafana" \
      io.openshift.expose-services="3000:grafana" \
      io.openshift.tags="grafana,monitoring,dashboard"

# Use Grafana's upstream RPM for the React modules required by Infinity.
COPY grafana.repo /etc/yum.repos.d/grafana.repo

RUN useradd -u ${UID} -g 0 -r -d $GF_PATHS_HOME -s /sbin/nologin grafana && \
    rpm --import https://rpm.grafana.com/gpg.key && \
    microdnf upgrade -y && \
    microdnf install -y --setopt=tsflags=nodocs grafana-${GRAFANA_VERSION} && \
    microdnf clean all && \
    /usr/sbin/grafana cli plugins install yesoreyeram-infinity-datasource && \
    chgrp -R 0 /etc/grafana /var/lib/grafana /var/log/grafana && \
    chmod -R g=u /var/lib/grafana /var/log/grafana

COPY --chown=grafana:grafana \
    dashboards.yaml \
    dashboards/*.dashboard.json \
    ${GF_PATHS_PROVISIONING}/dashboards/

COPY --chown=grafana:grafana \
    datasource.yaml \
    ${GF_PATHS_PROVISIONING}/datasources/

COPY --chown=grafana:grafana \
    grafana.ini \
    ${GF_PATHS_CONFIG}

COPY --chown=grafana:grafana \
    entrypoint.bash \
    /usr/bin/run-grafana

# Listen address of jfr-datasource
ENV JFR_DATASOURCE_URL "http://0.0.0.0:8080"

USER ${UID}

EXPOSE ${PORT}

ENTRYPOINT [ "/usr/bin/run-grafana" ]
