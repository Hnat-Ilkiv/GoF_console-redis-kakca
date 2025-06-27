{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "redis-kafka-env";

  buildInputs = [
    pkgs.python311
    pkgs.python311Packages.pip
    pkgs.python311Packages.redis
    pkgs.python311Packages.kafka-python
    pkgs.redis
    pkgs.confluent-platform # додаємо сюди, щоб мати kafka і zookeeper
    pkgs.netcat
    pkgs.curl
    pkgs.jdk # Kafka потребує Java
  ];

  shellHook = ''
    echo "============================="
    echo " 🚀 Ініціалізація середовища"
    echo "============================="

    # Redis
    if nc -z localhost 6379; then
        echo "⚠️ Redis вже працює на порті 6379, пропускаємо запуск"
    else
        echo "🔧 Запуск Redis..."
        redis-server --port 6379 &
        REDIS_PID=$!
        sleep 2
    fi

    if redis-cli -p 6379 ping | grep -q "PONG"; then
        echo "✅ Redis успішно запущений!"
    else
        echo "❌ Redis не стартував!"
        exit 1
    fi

#     # Zookeeper
#     echo "🔧 Запуск Zookeeper..."
#
#     mkdir -p ./config
#     mkdir -p /tmp/zookeeper-data
#
#     if [ ! -f ./config/zookeeper.properties ]; then
#         cat > ./config/zookeeper.properties <<EOF
#     tickTime=2000
#     dataDir=/tmp/zookeeper-data
#     clientPort=2181
#     initLimit=5
#     syncLimit=2
#     admin.enableServer=false
#     EOF
#     fi
#
#     zookeeper-server-start ./config/zookeeper.properties &
#     ZOOKEEPER_PID=$!
#
#     for i in {1..10}; do
#         if nc -z localhost 2181; then
#         echo "✅ Zookeeper успішно запущений!"
#         break
#         fi
#         echo "⏳ Очікування Zookeeper..."
#         sleep 2
#     done
#
#     if ! nc -z localhost 2181; then
#         echo "❌ Не вдалося підключитися до Zookeeper!"
#         [ -n "$REDIS_PID" ] && kill $REDIS_PID
#         [ -n "$ZOOKEEPER_PID" ] && kill $ZOOKEEPER_PID
#         exit 1
#     fi
#
#     # Kafka
#     echo "🔧 Запуск Kafka..."
#
#     KAFKA_DIR=$(dirname $(dirname $(which kafka-server-start.sh)))
#     $KAFKA_DIR/bin/kafka-server-start.sh $KAFKA_DIR/config/server.properties > /tmp/kafka.log 2>&1 &
#     KAFKA_PID=$!
#     sleep 5
#
#     if ps -p $KAFKA_PID > /dev/null; then
#         echo "✅ Kafka успішно запущена!"
#     else
#         echo "❌ Не вдалося запустити Kafka!"
#         [ -n "$REDIS_PID" ] && kill $REDIS_PID
#         [ -n "$ZOOKEEPER_PID" ] && kill $ZOOKEEPER_PID
#         exit 1
#     fi

    cleanup() {
        echo "🛑 Зупинка Redis, Kafka та Zookeeper..."
        redis-cli -p 6379 shutdown

        if [ -n "$KAFKA_PID" ] && ps -p $KAFKA_PID > /dev/null; then
        kill $KAFKA_PID
        fi

        if [ -n "$ZOOKEEPER_PID" ] && ps -p $ZOOKEEPER_PID > /dev/null; then
        kill $ZOOKEEPER_PID
        fi

        echo "✅ Сервіси зупинені."
    }

    trap cleanup EXIT
    '';
}
