# Redis Docker Setup

This directory contains a complete Docker Compose setup for Redis, configured for use in the microservices architecture with caching, session storage, and data persistence.

## Quick Start

1. **Copy environment file** (optional):
   ```bash
   cp env.example .env.local
   ```

2. **Start Redis**:
   ```bash
   docker-compose up -d
   ```

3. **Test connection**:
   ```bash
   docker exec -it redis-server redis-cli -a redis123 ping
   ```

## Configuration

### Environment Variables

The following environment variables can be customized in the `.env.local` file:

| Variable | Default | Description |
|----------|---------|-------------|
| `REDIS_PASSWORD` | `redis123` | Redis authentication password |
| `REDIS_MAXMEMORY` | `256mb` | Maximum memory limit |
| `REDIS_MAXMEMORY_POLICY` | `allkeys-lru` | Memory eviction policy |
| `REDIS_BIND` | `0.0.0.0` | Network binding address |
| `REDIS_PORT` | `6379` | Redis port |
| `REDIS_APPENDONLY` | `yes` | Enable AOF persistence |
| `REDIS_APPENDFSYNC` | `everysec` | AOF sync frequency |

### Ports

| Port | Service | Description |
|------|---------|-------------|
| 6379 | Redis | Main Redis protocol port |

### Memory Policies

Available memory eviction policies:
- `noeviction` - Return errors when memory limit is reached
- `allkeys-lru` - Remove least recently used keys (default)
- `volatile-lru` - Remove least recently used keys with expiration
- `allkeys-random` - Remove random keys
- `volatile-random` - Remove random keys with expiration
- `volatile-ttl` - Remove keys with shortest TTL

## Features

### Pre-configured Settings

The setup includes optimized configuration for:

- **Caching**: LRU eviction policy for efficient memory usage
- **Persistence**: Both RDB snapshots and AOF for data durability
- **Security**: Password authentication and protected mode
- **Performance**: Optimized network and memory settings
- **Monitoring**: Health checks and logging

### Data Persistence

Redis uses two persistence mechanisms:

1. **RDB (Redis Database)**: Point-in-time snapshots
   - Automatic saves: 900s (15min) if 1+ key changed
   - Manual saves: `SAVE` or `BGSAVE` commands

2. **AOF (Append Only File)**: Log of write operations
   - Enabled by default
   - Sync frequency: every second
   - Automatic rewrite when file gets too large

## Usage in Microservices

### Connection String

For your Go microservices, use the following connection string:

```
redis://:redis123@localhost:6379/0
```

### Example Connection (Go)

```go
package main

import (
    "context"
    "fmt"
    "log"
    "time"

    "github.com/redis/go-redis/v9"
)

func main() {
    // Create Redis client
    rdb := redis.NewClient(&redis.Options{
        Addr:     "localhost:6379",
        Password: "redis123",
        DB:       0,
        PoolSize: 10,
        DialTimeout:  5 * time.Second,
        ReadTimeout:  3 * time.Second,
        WriteTimeout: 3 * time.Second,
    })

    ctx := context.Background()

    // Test connection
    _, err := rdb.Ping(ctx).Result()
    if err != nil {
        log.Fatalf("Failed to connect to Redis: %v", err)
    }

    // Set a key
    err = rdb.Set(ctx, "key", "value", 0).Err()
    if err != nil {
        log.Fatalf("Failed to set key: %v", err)
    }

    // Get a key
    val, err := rdb.Get(ctx, "key").Result()
    if err != nil {
        log.Fatalf("Failed to get key: %v", err)
    }

    fmt.Printf("key = %s\n", val)

    // Close connection
    rdb.Close()
}
```

### Caching Example

```go
package main

import (
    "context"
    "encoding/json"
    "log"
    "time"

    "github.com/redis/go-redis/v9"
)

type User struct {
    ID   string `json:"id"`
    Name string `json:"name"`
    Email string `json:"email"`
}

func main() {
    rdb := redis.NewClient(&redis.Options{
        Addr:     "localhost:6379",
        Password: "redis123",
        DB:       0,
    })
    defer rdb.Close()

    ctx := context.Background()

    // Cache user data
    user := User{ID: "1", Name: "John Doe", Email: "john@example.com"}
    userJSON, _ := json.Marshal(user)
    
    // Set with expiration (1 hour)
    err := rdb.Set(ctx, "user:1", userJSON, time.Hour).Err()
    if err != nil {
        log.Printf("Failed to cache user: %v", err)
    }

    // Get cached user
    cachedUserJSON, err := rdb.Get(ctx, "user:1").Result()
    if err == redis.Nil {
        log.Println("User not found in cache")
    } else if err != nil {
        log.Printf("Failed to get user from cache: %v", err)
    } else {
        var cachedUser User
        json.Unmarshal([]byte(cachedUserJSON), &cachedUser)
        log.Printf("Cached user: %+v", cachedUser)
    }
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
docker-compose logs -f redis

# Restart services
docker-compose restart
```

### Redis CLI Access

```bash
# Connect to Redis CLI
docker exec -it redis-server redis-cli -a redis123

# Basic commands
127.0.0.1:6379> SET mykey "Hello Redis"
127.0.0.1:6379> GET mykey
127.0.0.1:6379> INFO memory
127.0.0.1:6379> MONITOR
127.0.0.1:6379> EXIT
```

### Data Persistence

Data is persisted in Docker volumes:
- `redis_data` - Redis database files (RDB, AOF)
- `redis_logs` - Log files

To backup data:
```bash
# Create backup
docker exec redis-server redis-cli -a redis123 BGSAVE

# Copy backup files
docker cp redis-server:/data/dump.rdb ./backup/
docker cp redis-server:/data/appendonly.aof ./backup/
```

### Health Check

The container includes a health check that verifies Redis is responding:
```bash
docker-compose ps
```

## Monitoring

### Redis INFO Command

```bash
# Get server information
docker exec -it redis-server redis-cli -a redis123 INFO

# Get memory information
docker exec -it redis-server redis-cli -a redis123 INFO memory

# Get replication information
docker exec -it redis-server redis-cli -a redis123 INFO replication
```

### Key Metrics to Monitor

- **Memory usage**: `used_memory`, `used_memory_peak`
- **Connected clients**: `connected_clients`
- **Commands processed**: `total_commands_processed`
- **Keyspace hits/misses**: `keyspace_hits`, `keyspace_misses`
- **Network I/O**: `total_net_input_bytes`, `total_net_output_bytes`

## Troubleshooting

### Common Issues

1. **Connection refused**:
   ```bash
   # Check if Redis is running
   docker-compose ps
   
   # Check logs
   docker-compose logs redis
   ```

2. **Authentication failed**:
   ```bash
   # Verify password in .env.local
   cat .env.local | grep REDIS_PASSWORD
   
   # Test with correct password
   docker exec -it redis-server redis-cli -a redis123 ping
   ```

3. **Memory issues**:
   ```bash
   # Check memory usage
   docker exec -it redis-server redis-cli -a redis123 INFO memory
   
   # Adjust memory limits in docker-compose.yml
   ```

### Logs

View detailed logs:
```bash
docker-compose logs redis
```

### Reset Everything

To completely reset Redis (⚠️ **WARNING**: This will delete all data):
```bash
docker-compose down -v
docker-compose up -d
```

## Security Notes

⚠️ **Important**: The default password (`redis123`) is for development only. For production:

1. Change default password in `.env.local`
2. Use strong passwords
3. Enable SSL/TLS if needed
4. Restrict network access
5. Use proper firewall rules
6. Consider Redis ACLs for fine-grained access control

## Performance Tuning

### Memory Optimization

- **Set appropriate maxmemory**: Based on available RAM
- **Choose eviction policy**: `allkeys-lru` for caching, `noeviction` for critical data
- **Monitor memory usage**: Use `INFO memory` command

### Network Optimization

- **Connection pooling**: Use connection pools in your applications
- **Pipeline commands**: Batch multiple commands for better performance
- **Use appropriate timeouts**: Set reasonable connection timeouts

### Persistence Tuning

- **RDB frequency**: Adjust save intervals based on data change frequency
- **AOF sync**: Use `everysec` for good balance of performance and durability
- **Background processes**: Monitor impact of RDB/AOF operations

## Network Configuration

The setup creates a custom network `redis-network` that other services can connect to:

```yaml
# In other docker-compose files
networks:
  - redis-network

networks:
  redis-network:
    external: true
```

This allows secure communication between microservices and Redis.

## Integration with Microservices

### Service Layer Usage

In your service layer, use Redis for:
- **Caching**: Frequently accessed data
- **Session storage**: User sessions and tokens
- **Rate limiting**: API rate limiting counters
- **Distributed locks**: Coordination between services
- **Pub/Sub**: Event broadcasting

### Application Service Layer Usage

In your application services, use Redis for:
- **Response caching**: Cache API responses
- **User sessions**: Store session data
- **Temporary data**: Short-lived data storage
- **Queue management**: Simple job queues
