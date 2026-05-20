FROM sonatype/nexus3:3.68.0

# ---------------------------------------------------------------------------
# Install the Google Cloud Storage Blob Store plugin for Nexus Repository OSS
# Plugin releases: https://github.com/sonatype-nexus-community/nexus-blobstore-google-cloud/releases
# ---------------------------------------------------------------------------

ARG GCS_PLUGIN_VERSION=0.17.0

USER root

# Download the plugin KAR archive and place it in Nexus deploy directory
RUN curl -fsSL \
    "https://github.com/sonatype-nexus-community/nexus-blobstore-google-cloud/releases/download/${GCS_PLUGIN_VERSION}/nexus-blobstore-google-cloud-${GCS_PLUGIN_VERSION}.kar" \
    -o /opt/sonatype/nexus/deploy/nexus-blobstore-google-cloud-${GCS_PLUGIN_VERSION}.kar \
  && chown nexus:nexus /opt/sonatype/nexus/deploy/nexus-blobstore-google-cloud-${GCS_PLUGIN_VERSION}.kar

# Switch back to the unprivileged nexus user (required by Sonatype hardening)
USER nexus

# Nexus HTTP UI port
EXPOSE 8081

# Nexus data volume — mount a PVC here to persist repositories & config
VOLUME ["/nexus-data"]

ENTRYPOINT ["/opt/sonatype/nexus/bin/nexus"]
CMD ["run"]
