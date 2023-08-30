FROM python:3.9-slim
ENV PYTHONBUFFERED True
EXPOSE 8080
WORKDIR /app
RUN apt-get update && apt-get install -y \
    build-essential \
    software-properties-common \
    git \
    && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
COPY frontend.py .
RUN mkdir -p .streamlit
COPY config.toml .streamlit
RUN pip3 install -r requirements.txt
ENTRYPOINT ["streamlit", "run", "frontend.py", "--server.port=8080", "--server.address=0.0.0.0"]