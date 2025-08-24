# RabbitMQ Docker Setup

This directory contains a complete Docker Compose setup for RabbitMQ with management interface, configured for use in the microservices architecture.

## Quick Start

1. **Copy environment file** (optional):
   ```bash
   cp env.example .env
   ```

2. **Start RabbitMQ**:
   ```bash
   docker-compose up -d
   ```

3. **Access Management UI**:
   - URL: http://localhost:15672
   - Username: `admin`
   - Password: `admin123`

## Configuration

### Environment Variables

The following environment variables can be customized in the `.env` file:

| Variable | Default | Description |
|----------|---------|-------------|
| `RABBITMQ_USER` | `admin` | Default username |
| `RABBITMQ_PASSWORD` | `admin123` | Default password |
| `RABBITMQ_VHOST` | `/` | Default virtual host |
| `RABBITMQ_ERLANG_COOKIE` | `SWQOKODSQALRPCLNMEQG` | Erlang cookie for clustering |
| `RABBITMQ_NODE_NAME` | `rabbit@rabbitmq-server` | Node name |

### Ports

| Port | Service | Description |
|------|---------|-------------|
| 5672 | AMQP | Main RabbitMQ protocol port |
| 15672 | Management UI | Web-based management interface |
| 15692 | Prometheus | Metrics endpoint for monitoring |

## Services

### Pre-configured Queues

The setup includes the following queues for the microservices architecture:

- `user.events` - User management events
- `auth.events` - Authentication events  
- `notification.events` - Notification events
- `dead.letter.queue` - Dead letter queue for failed messages

### Pre-configured Exchanges

- `user.exchange` (topic) - User-related events
- `auth.exchange` (topic) - Authentication events
- `notification.exchange` (topic) - Notification events
- `dead.letter.exchange` (direct) - Dead letter exchange

## Usage in Microservices

### Connection String

For your Go microservices, use the following connection string:

```go
amqp://admin:admin123@localhost:5672/
```

### Example Connection (Go)

```go
package main

import (
    "github.com/streadway/amqp"
    "log"
)

func main() {
    // Connect to RabbitMQ
    conn, err := amqp.Dial("amqp://admin:admin123@localhost:5672/")
    if err != nil {
        log.Fatalf("Failed to connect to RabbitMQ: %v", err)
    }
    defer conn.Close()

    // Create channel
    ch, err := conn.Channel()
    if err != nil {
        log.Fatalf("Failed to open channel: %v", err)
    }
    defer ch.Close()

    // Declare queue
    q, err := ch.QueueDeclare(
        "user.events", // name
        true,          // durable
        false,         // delete when unused
        false,         // exclusive
        false,         // no-wait
        nil,           // arguments
    )
    if err != nil {
        log.Fatalf("Failed to declare queue: %v", err)
    }

    log.Printf("Connected to RabbitMQ successfully!")
}
```

## Management

### Start/Stop Services

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f rabbitmq

# Restart services
docker-compose restart
```

### Data Persistence

Data is persisted in Docker volumes:
- `rabbitmq_data` - Message store and metadata
- `rabbitmq_logs` - Log files

To backup data:
```bash
docker run --rm -v rabbitmq_data:/data -v $(pwd):/backup alpine tar czf /backup/rabbitmq-backup.tar.gz -C /data .
```

### Health Check

The container includes a health check that verifies RabbitMQ is responding:
```bash
docker-compose ps
```

## Troubleshooting

### Common Issues

1. **Port already in use**:
   ```bash
   # Check what's using the port
   netstat -tulpn | grep :5672
   
   # Stop conflicting service or change ports in docker-compose.yml
   ```

2. **Permission denied**:
   ```bash
   # Ensure Docker has proper permissions
   sudo usermod -aG docker $USER
   ```

3. **Memory issues**:
   - Adjust memory limits in `docker-compose.yml`
   - Monitor with `docker stats`

### Logs

View detailed logs:
```bash
docker-compose logs rabbitmq
```

### Reset Everything

To completely reset RabbitMQ (⚠️ **WARNING**: This will delete all data):
```bash
docker-compose down -v
docker-compose up -d
```

## Security Notes

⚠️ **Important**: The default credentials (`admin/admin123`) are for development only. For production:

1. Change default credentials in `.env`
2. Use strong passwords
3. Consider using RabbitMQ's password hashing
4. Restrict network access
5. Enable SSL/TLS
6. Use proper firewall rules

## Monitoring

### Management UI Features

- Queue monitoring
- Message rates
- Connection status
- Node health
- Performance metrics

### Prometheus Metrics

Access metrics at: http://localhost:15692/metrics

## Network Configuration

The setup creates a custom network `rabbitmq-network` that other services can connect to:

```yaml
# In other docker-compose files
networks:
  - rabbitmq-network

networks:
  rabbitmq-network:
    external: true
```

This allows secure communication between microservices and RabbitMQ.
