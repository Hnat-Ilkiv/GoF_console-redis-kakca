import csv
import json
import redis
from kafka import KafkaProducer
import time

# Інтерфейс Стратегії
class OutputStrategy:
    def output(self, data):
        raise NotImplementedError

# Стратегія виводу в консоль
class ConsoleOutputStrategy(OutputStrategy):
    def output(self, data):
        for row in data:
            print(row)

# Стратегія виводу в Redis
class RedisOutputStrategy(OutputStrategy):
    def __init__(self, host='localhost', port=6379, db=0):
        self.client = redis.Redis(host=host, port=port, db=db)

    def output(self, data):
        print("Запис в Redis...")
        for i, row in enumerate(data):
            key = f"record:{i}"
            self.client.set(key, json.dumps(row))
            # print(f"[REDIS] {key} => {row}")

# Стратегія виводу в Kafka
class KafkaOutputStrategy(OutputStrategy):
    def __init__(self, topic='test-topic', bootstrap_servers='localhost:9092'):
        self.producer = KafkaProducer(
            bootstrap_servers=bootstrap_servers,
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )
        self.topic = topic

    def output(self, data):
        print("Запис в Kafka...")
        for row in data:
            self.producer.send(self.topic, row)
            # print(f"[KAFKA] {row}")
            time.sleep(0.1)  # Невелика пауза для тесту, необов’язково
        self.producer.flush()

# Клас для читання даних
class DataReader:
    def __init__(self, filepath):
        self.filepath = filepath

    def read_data(self):
        with open(self.filepath, mode='r', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            return list(reader)

# Головний процесор
class DataProcessor:
    def __init__(self, strategy: OutputStrategy):
        self.strategy = strategy

    def process(self, data):
        self.strategy.output(data)

# Функція для завантаження конфігурації
def load_config(path='config.json'):
    with open(path, 'r') as file:
        return json.load(file)

def main():
    config = load_config()

    # Вибір стратегії
    if config['output'] == 'console':
        strategy = ConsoleOutputStrategy()

    elif config['output'] == 'redis':
        redis_config = config.get('redis', {})
        strategy = RedisOutputStrategy(
            host=redis_config.get('host', 'localhost'),
            port=redis_config.get('port', 6379),
            db=redis_config.get('db', 0)
        )

    elif config['output'] == 'kafka':
        kafka_config = config.get('kafka', {})
        strategy = KafkaOutputStrategy(
            topic=kafka_config.get('topic', 'test-topic'),
            bootstrap_servers=kafka_config.get('bootstrap_servers', 'localhost:9092')
        )
    else:
        raise Exception("Невідома стратегія!")

    reader = DataReader('data.csv')
    data = reader.read_data()

    processor = DataProcessor(strategy)
    processor.process(data)

if __name__ == '__main__':
    main()
