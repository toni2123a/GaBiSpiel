FROM python:3.13-slim
WORKDIR /app
COPY spiel/server.py /app/server.py
COPY godot/build/ /app/dist/
RUN mkdir /data && chown 10001:10001 /data
USER 10001:10001
ENV GAME_DB=/data/game.sqlite PORT=8080 PYTHONUNBUFFERED=1
EXPOSE 8080
VOLUME ["/data"]
HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/api/state',timeout=2)" || exit 1
CMD ["python", "server.py"]
