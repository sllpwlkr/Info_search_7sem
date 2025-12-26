FROM python:3.11-slim

WORKDIR /app

# Устанавливаем зависимости системы
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    make \
    libjsoncpp-dev \
    && rm -rf /var/lib/apt/lists/*

# Копируем зависимости и устанавливаем их
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt



# Копируем исходный код
COPY src/ ./src/
COPY config.yaml ./

RUN mkdir -p /app/bin && \
    g++ -O2 -std=c++17 /app/src/tokenizer.cpp -o /app/bin/tokenizer && \
    g++ -O2 -std=c++17 /app/src/zipf.cpp -o /app/bin/zipf && \
    g++ -O2 -std=c++17 /app/src/stemmer.cpp -o /app/bin/stemmer

RUN g++ -O2 -std=c++17 -I/usr/include/jsoncpp /app/src/indexer.cpp -o /app/bin/indexer -ljsoncpp
RUN g++ -O2 -std=c++17 -I/usr/include/jsoncpp /app/src/searching.cpp -o /app/bin/searching -ljsoncpp

COPY mongo-init.js ./


# Создаем папки для данных
RUN mkdir -p logs data

# Настройка pywikibot
RUN echo "family = 'wikipedia'" > user-config.py && \
    echo "mylang = 'ru'" >> user-config.py && \
    echo "usernames['wikipedia']['ru'] = 'SearchBot'" >> user-config.py

# Точка входа
CMD ["python", "-m", "src/crawler.py", "config.yaml"]