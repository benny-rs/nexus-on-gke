FROM sonatype/nexus3:3.57.0

ARG GCS_PLUGIN_VERSION=0.57.0
ARG MAVEN_CENTRAL=https://repo1.maven.org/maven2/org/sonatype/nexus/plugins/nexus-blobstore-google-cloud

USER root

RUN curl -fsSL \
    "${MAVEN_CENTRAL}/${GCS_PLUGIN_VERSION}/nexus-blobstore-google-cloud-${GCS_PLUGIN_VERSION}-bundle.kar" \
    -o /opt/sonatype/nexus/deploy/nexus-blobstore-google-cloud-${GCS_PLUGIN_VERSION}-bundle.kar \
  && chown nexus:nexus \
       /opt/sonatype/nexus/deploy/nexus-blobstore-google-cloud-${GCS_PLUGIN_VERSION}-bundle.kar

USER nexus

EXPOSE 8081

VOLUME ["/nexus-data"]

ENTRYPOINT ["/opt/sonatype/nexus/bin/nexus"]
CMD ["run"]
