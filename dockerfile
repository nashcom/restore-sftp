ARG BASE_IMAGE=alpine
FROM ${BASE_IMAGE} 

COPY install /install

RUN chmod 755 /install/install.sh && /install/install.sh

EXPOSE 2222

ENTRYPOINT ["/entrypoint.sh"]
