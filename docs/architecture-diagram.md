# Microservices Architecture Diagram

This diagram illustrates the layered architecture and communication patterns of the microservices backend system.

```mermaid
flowchart TD
    %% External Client
    Client[Client Applications] --> Gateway
    
    %% Gateway Layer
    Gateway[Gateway Layer<br/>Reverse Proxy<br/>Single Entry Point]
    
    %% Application Service Layer
    Gateway --> AppService1[Application Service 1<br/>User Management]
    Gateway --> AppService2[Application Service 2<br/>RBAC System]
    Gateway --> AppService3[Application Service 3<br/>Notifications]
    
    %% Service Layer
    AppService1 -.->|gRPC| Service1[Service Layer 1<br/>User Service]
    AppService1 -.->|gRPC| Service2[Service Layer 2<br/>Auth Service]
    AppService2 -.->|gRPC| Service2
    AppService2 -.->|gRPC| Service3[Service Layer 3<br/>Permission Service]
    AppService3 -.->|gRPC| Service4[Service Layer 4<br/>Notification Service]
    
    %% Database Layer
    Service1 --> DB[(PostgreSQL<br/>Primary Database)]
    Service2 --> DB
    Service3 --> DB
    Service4 --> DB
    
    %% Caching Layer
    Service1 --> Redis[(Redis<br/>Caching Layer)]
    Service2 --> Redis
    Service3 --> Redis
    Service4 --> Redis
    
    %% Message Queue Layer
    AppService1 -.->|Events| RabbitMQ[RabbitMQ<br/>Message Queue]
    AppService2 -.->|Events| RabbitMQ
    AppService3 -.->|Events| RabbitMQ
    
    %% Async Communication
    RabbitMQ -.->|Async Processing| Service1
    RabbitMQ -.->|Async Processing| Service2
    RabbitMQ -.->|Async Processing| Service3
    RabbitMQ -.->|Async Processing| Service4
    
    %% Styling
    classDef clientClass fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef gatewayClass fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef appServiceClass fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef serviceClass fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef dbClass fill:#ffebee,stroke:#c62828,stroke-width:2px
    classDef queueClass fill:#fff8e1,stroke:#f57f17,stroke-width:2px
    
    class Client clientClass
    class Gateway gatewayClass
    class AppService1,AppService2,AppService3 appServiceClass
    class Service1,Service2,Service3,Service4 serviceClass
    class DB,Redis dbClass
    class RabbitMQ queueClass
```

## Architecture Components

### Communication Patterns

1. **Synchronous Communication (Solid Lines)**
   - Client → Gateway: HTTP requests
   - Gateway → Application Services: HTTP routing
   - Application Services → Service Layer: gRPC calls
   - Service Layer → Database: Direct database connections
   - Service Layer → Redis: Cache operations

2. **Asynchronous Communication (Dotted Lines)**
   - Application Services → RabbitMQ: Event publishing
   - RabbitMQ → Service Layer: Event consumption and processing

### Layer Responsibilities

- **Gateway Layer**: Single entry point, request routing, load balancing
- **Application Service Layer**: Business logic orchestration, client-facing APIs
- **Service Layer**: Core business services, data access, reusable components
- **Database Layer**: Data persistence and retrieval
- **Caching Layer**: Performance optimization and session management
- **Message Queue Layer**: Event-driven processing and service decoupling
