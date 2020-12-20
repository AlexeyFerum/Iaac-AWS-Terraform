FROM owasp/zap2docker-stable:latest
HEALTHCHECK NONE
USER root
RUN pip install croniter
COPY autostart.py autostart.py
USER zap