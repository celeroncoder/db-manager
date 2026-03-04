# DB Manager

A native macOS app built with SwiftUI that manages database instances entirely through Docker. Select a database engine, and the app pulls the image, spins up a container, configures credentials, and hands you a ready-to-use connection string.

## Features

- **One-click database creation** — Pick an engine, configure credentials, and get a running database in seconds
- **Full container lifecycle** — Start, stop, restart, and delete containers from the UI
- **Connection strings** — Auto-generated URIs with one-click copy to clipboard
- **Live logs** — Stream container logs with search and filtering
- **Resource monitoring** — CPU, memory, network, and block I/O stats
- **Independent filters** — Sidebar and dashboard have separate filter controls
- **Auto-refresh** — Container list polls every 5 seconds
- **Image auto-pull** — Fetches Docker images automatically if not present locally
- **Keyboard shortcuts** — Cmd+N to create, Cmd+R to refresh, Escape to go back
- **Accessibility** — VoiceOver labels on all interactive elements

## Supported Databases

| Database | Image | Default Port |
|----------|-------|-------------|
| PostgreSQL | `postgres:16-alpine` | 5432 |
| MySQL | `mysql:8.0` | 3306 |
| MariaDB | `mariadb:11` | 3306 |
| MongoDB | `mongo:7` | 27017 |
| Redis | `redis:7-alpine` | 6379 |

## Requirements

- **macOS 14.0** (Sonoma) or later
- **Xcode 15.0+** / **Swift 5.10+** (for building)
- **Docker** runtime — any of:
  - [Docker Desktop](https://www.docker.com/products/docker-desktop/)
  - [OrbStack](https://orbstack.dev/)
  - [Colima](https://github.com/abiosoft/colima)

## Getting Started

### Download

Grab the latest release from [Releases](https://github.com/celeroncoder/db-manager/releases) and run the binary directly.

### Build from Source

```bash
# Clone the repo
git clone https://github.com/celeroncoder/db-manager.git
cd db-manager

# Build with Swift Package Manager
swift build

# Run the app
.build/debug/DBManager
```

Or open the project in Xcode:

```bash
open Package.swift
```

Then hit **Cmd+R** to build and run.

### Development

The project uses Swift Package Manager with zero external dependencies. The full source lives under `DBManager/`.

```bash
# Build (debug)
swift build

# Build (release)
swift build -c release

# Clean build artifacts
swift package clean
```

## Architecture

```
SwiftUI Views
  → @Observable ViewModels (local filter state per view)
    → DockerService (actor-isolated)
      → Shell (async Process wrapper)
        → Docker CLI → Docker Engine
```

All Docker operations go through the CLI using `Process` with JSON output parsing. Containers created by the app are labeled `app=db-manager` so they can be filtered from other Docker containers.

### Project Structure

```
DBManager/
├── DBManagerApp.swift              # App entry point
├── ContentView.swift               # Root NavigationSplitView
├── Models/
│   ├── DatabaseEngine.swift        # Engine enum (postgres, mysql, etc.)
│   ├── DatabaseContainer.swift     # Container model parsed from docker ps
│   ├── DatabaseConfig.swift        # Creation config + docker run builder
│   ├── ContainerState.swift        # running, stopped, exited, etc.
│   └── ContainerFilter.swift       # Shared filter enum (all/running/stopped)
├── Services/
│   ├── DockerService.swift         # Actor-isolated Docker CLI wrapper
│   └── ConnectionStringBuilder.swift
├── ViewModels/
│   ├── AppViewModel.swift          # Global app state + polling
│   ├── ContainerListViewModel.swift
│   └── CreateDatabaseViewModel.swift
├── Views/
│   ├── Sidebar/
│   │   └── SidebarView.swift       # Sidebar with own filter + grouped pill bar
│   ├── Dashboard/
│   │   ├── DashboardView.swift     # Dashboard with own clickable stat filters
│   │   └── ContainerCard.swift     # Container card with proper hit targets
│   ├── Create/
│   │   ├── CreateDatabaseSheet.swift
│   │   └── EnginePickerView.swift
│   ├── Detail/
│   │   ├── ContainerDetailView.swift  # Detail view with back button + toolbar
│   │   ├── ConnectionInfoView.swift
│   │   └── ContainerLogsView.swift
│   └── Components/
│       ├── StatusBadge.swift
│       ├── EngineIcon.swift
│       ├── CopyButton.swift
│       └── MetricGauge.swift
└── Utilities/
    ├── Shell.swift                 # Async Process wrapper
    └── Constants.swift
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd+N | New database |
| Cmd+R | Refresh containers |
| Escape | Back to dashboard (from detail view) |

## How It Works

1. The app executes Docker CLI commands via `/bin/zsh -l -c` to ensure Docker is on the PATH
2. All managed containers are labeled with `app=db-manager` for easy filtering
3. Container metadata (engine, credentials, port) is stored as Docker labels — no separate database needed
4. Connection strings are built from the container labels at display time
5. Sidebar and dashboard maintain independent filter states

### Docker Commands Used

| Operation | Command |
|-----------|---------|
| List containers | `docker ps -a --filter label=app=db-manager --format '{{json .}}'` |
| Create + run | `docker run -d --name X -e ... -p PORT:PORT --label app=db-manager IMAGE` |
| Start / Stop | `docker start\|stop <id>` |
| Remove | `docker rm -f <id>` |
| Logs | `docker logs --tail 200 <id>` |
| Stats | `docker stats --no-stream --format '{{json .}}' <id>` |
| Pull image | `docker pull <image>` |

## Tech Stack

| Layer | Choice |
|-------|--------|
| UI Framework | SwiftUI (macOS 14+) |
| State | `@Observable` macro |
| Concurrency | `async/await` + `actor` isolation |
| Docker | `Process` API → Docker CLI |
| Dependencies | Zero — pure SwiftUI + Foundation |

## License

MIT
