# MyOffGrid AI

**Your world, remembered.**

MyOffGrid AI is a private, offline-first personal AI assistant designed to run entirely on your own hardware. Every conversation, every memory, every document stays on your device — no cloud required. Pair it with local LLMs running on a Raspberry Pi, Mini-PC, or any Linux appliance, and you get a fully sovereign AI that learns, remembers, and helps manage your off-grid life.

---

## Why MyOffGrid AI?

Most AI assistants send your data to someone else's server. MyOffGrid AI doesn't.

- **100% local inference** — Your AI runs on your hardware.
- **Long-term memory** — The AI extracts facts from every conversation and remembers them permanently. It knows your soil pH, your generator maintenance schedule, your canning recipes — because you told it once.
- **Knowledge vault** — Upload PDFs, Word docs, spreadsheets, or write directly in the built-in editor. The AI indexes everything and draws from your documents when answering questions.
- **Privacy fortress** — One toggle cuts all outbound network traffic via iptables. Your device becomes a true air gap.
- **Works without internet** — Core AI, memory, knowledge, sensors, and the offline library all function with zero connectivity.

---

## Features

### Conversations
A streaming chat interface with real-time token-by-token responses. The AI draws from your memories and knowledge base automatically via RAG (Retrieval-Augmented Generation). Edit messages, regenerate responses, branch conversations, and watch the AI's chain-of-thought reasoning in collapsible thinking blocks.

### AI Memory
Every conversation is mined for facts. The AI extracts and embeds them as long-term memories tagged by importance — Critical, High, Medium, Low. Memories are semantically searchable and automatically injected into future conversations as relevant context. You tell the AI something once; it remembers forever.

### Knowledge Vault
Your personal document library that the AI can search and reference. Upload files (PDF, DOCX, XLSX, PPTX, RTF, images with OCR, plain text) or create rich-text documents directly in the built-in Quill editor. Documents are chunked, embedded, and indexed for semantic search. Fetch content from URLs or import web search results directly into your vault.

### AI Judge
An optional quality-control layer. A second local model scores every AI response on a 0–10 scale. If the score falls below your configured threshold, the system can automatically escalate to a cloud frontier model (Claude, GPT, or Grok) for an enhanced response — giving you local speed with cloud quality as a safety net.  If AI Judge is enabled, you can also choose to save whatever enhanced data is retrieved so that your local AI Memory is expanded with that information making it relevant and used with future chats.

### Sensors
Connect physical sensors (temperature, humidity, soil moisture, power, voltage) via serial port. The dashboard shows live readings, 24-hour history charts, and configurable threshold alerts. When a sensor crosses a threshold, the AI creates a memory and sends a push notification. Sensor data can trigger automated events and can also be used with LLM data to give highly-relevant contemporary answers to your questions or notifications.  "Based on your soil conditions right now, you should plant the Blue Lake beans we talked about last week in the second garden this weekend."

### Events & Automation
Schedule tasks with cron expressions, set recurring intervals, or trigger actions when sensor values cross thresholds. Actions include push notifications, AI prompts (ask the AI a question on a schedule), and AI summaries of recent conversations — all running autonomously on your device.  If using MyOffGridAI mobile app on your Android device, you can have fully functional push notifications entirely offline and off-grid with just a regular WiFi router and your MyOffGridAI-Server.

### Skills
Built-in AI capabilities that go beyond chat:
- **Inventory Tracker** — manage off-grid supplies with low-stock alerts across categories (food, water, fuel, medical, tools, seeds, and more)
- **Recipe Generator** — creates recipes from your current food inventory using either your favorite uploaded recipes or AI generated
- **Resource Calculator** — estimates power, water, and food runway based on your supplies
- **Task Planner** — AI-generated step-by-step plans with resource estimates
- **Document Summarizer** — condenses knowledge vault documents

### Offline Library
Three ways to access knowledge without internet:
- **Ebook Library** — download and read EPUBs and PDFs in the built-in reader
- **Kiwix** — load ZIM files (compressed snapshots of Wikipedia, Stack Overflow, medical references, survival guides) and browse them locally
- **Project Gutenberg** — search and import from 70,000+ free public domain books

### Proactive Insights
Every night, the AI analyzes patterns across your conversations, memories, sensors, and inventory to generate actionable insights — resource warnings, seasonal reminders, health observations, and homestead recommendations. Delivered as notifications by morning.

### Notifications
Real-time push notifications via MQTT to all local WiFi connected devices. Sensor alerts, event triggers, insight summaries, and system warnings arrive instantly — even on mobile with background service support on Android.

### Privacy & Data Sovereignty
- **Fortress Mode** — blocks all outbound network traffic at the firewall level
- **Sovereignty Report** — see exactly what data exists and where it's stored
- **Audit Log** — every API call logged with user, action, timestamp, and duration
- **Data Export** — download all your data as an AES-256-GCM encrypted zip
- **Data Wipe** — GDPR-compliant single-action deletion across all tables
- **Encrypted secrets** — all API keys encrypted at rest with AES-256-GCM

### Model Management
Browse the HuggingFace catalog, discover LLM models, select optimal quantization levels, and download GGUF models directly to your device. Switch active models, monitor inference health, and restart the inference server — all from the settings screen.

### MCP Server
MyOffGrid AI implements the Model Context Protocol, allowing Claude Desktop or other LLM systems to call your device's tools directly — search your knowledge base, query your sensors, manage your inventory, and browse your memories, all from Claude's desktop app.

### Search
Unified search across all three domains simultaneously — conversations, memories, and knowledge documents — with results organized by tab.

### Multi-User
Role-based access for the whole household:
- **Owner** — full device control, fortress mode, factory reset, model management
- **Admin** — user management, system settings
- **Member** — full feature access
- **Viewer** — read-only access
- **Child** — restricted access

### Setup Wizard
On first boot, the device broadcasts a WiFi access point (`MyOffGridAI-Setup`). Connect from any phone or laptop, and a captive portal walks you through WiFi configuration, owner account creation, and device initialization. No terminal required.

---

## Architecture

MyOffGrid AI is a two-part system:

| Component | Technology | Description |
|-----------|-----------|-------------|
| **Server** | Java 21 / Spring Boot | REST API, AI inference orchestration, RAG pipeline, sensor polling, MQTT, MCP server |
| **Client** | Flutter (Dart) | Cross-platform UI for iOS, Android, and web browsers |

### How It Runs

```
┌──────────────────────────────────────────────────────┐
│                 Your Hardware                        │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌─────────────────────┐ │
│  │ Flutter  │  │  Spring  │  │  Ollama /           │ │
│  │ Client   │──│  Boot    │──│  LM Studio /        │ │
│  │ (App)    │  │  Server  │  │  llama-server       │ │
│  └──────────┘  └────┬─────┘  └─────────────────────┘ │
│                     │                                │
│         ┌───────────┼───────────┐                    │
│         │           │           │                    │
│    ┌────┴────┐ ┌────┴────┐ ┌────┴─────┐              │
│    │ Postgres│ │Mosquitto│ │ Sensors  │              │
│    │+pgvector│ │  (MQTT) │ │ (Serial) │              │
│    └─────────┘ └─────────┘ └──────────┘              │
└──────────────────────────────────────────────────────┘
```

- **PostgreSQL + pgvector** — stores conversations, memories, knowledge chunks, and 768-dimensional vector embeddings for semantic search
- **Mosquitto MQTT** — delivers real-time push notifications to mobile devices
- **Serial sensors** — Arduino, Raspberry Pi GPIO, or any serial-connected sensor hardware
- **Local LLM** — runs inference and embedding models entirely on-device

---

## Getting Started

### Prerequisites

- Java 21+
- PostgreSQL 16 with the [pgvector](https://github.com/pgvector/pgvector) extension
- An inference provider: [Ollama](https://ollama.ai), [LM Studio](https://lmstudio.ai), or llama-server
- An embedding model (e.g., `nomic-embed-text`)
- Flutter 3.41+ (for building the client from source)
- Optional: Mosquitto MQTT broker (for push notifications)

### Server

```bash
cd MyOffGridAI-Server
./mvnw clean package -DskipTests
./mvnw spring-boot:run
```

The server starts on port **8080**. On first launch, visit `http://localhost:8080` to run the setup wizard and create your owner account.

### Client

```bash
cd MyOffGridAI-Client
flutter pub get
flutter run          # mobile/desktop
flutter run -d chrome # web
```

The login screen lets you configure the server URL at runtime — no hardcoded addresses.

### Default Dev Credentials

- **Username:** `admin`
- **Password:** `test`

---

## Configuration

The server is configured via Spring profiles:

| Setting | Dev | Production |
|---------|-----|------------|
| Database DDL | Hibernate auto-update | Flyway migrations |
| Password minimum | 4 characters | 12 characters |
| CORS | Allow all origins | Restricted |
| Fortress / AP mode | Mocked | Real (iptables, hostapd) |

### Key Environment Variables

| Variable | Description |
|----------|-------------|
| `JWT_SECRET` | HMAC-SHA256 signing key (required in production) |
| `ENCRYPTION_KEY` | AES-256-GCM key for encrypting API secrets at rest |
| `INFERENCE_PROVIDER` | `ollama` or `llama-server` |
| `INFERENCE_BASE_URL` | Inference server URL (default: `http://localhost:1234`) |
| `DB_URL` | PostgreSQL JDBC URL |

### Optional Cloud APIs

All optional — the system works fully offline without any of these:

| Service | Purpose |
|---------|---------|
| Anthropic (Claude) | Frontier model fallback via AI Judge |
| OpenAI | Frontier model fallback |
| Grok (xAI) | Frontier model fallback |
| Brave Search | Web search enrichment for the knowledge vault |
| HuggingFace | Model catalog browsing and downloads |

API keys are configured in Settings and encrypted at rest with AES-256-GCM.

---

## Design

The client uses a nature-inspired, earth-toned design system built on Material 3:

- **Forest green** (`#2D5016`) — primary actions and branding
- **Warm amber** (`#8B5E1A`) — secondary accent
- **Deep olive** dark mode / **Warm parchment** light mode
- Supports Light, Dark, and System theme modes

Desktop and tablet layouts feature a collapsible sidebar with the full conversation list and navigation. Mobile uses a bottom navigation bar.

---

## Tech Stack

### Server
Java 21, Spring Boot 3.4, Spring Security (JWT), Spring AI MCP, PostgreSQL 16 + pgvector, jSerialComm, Apache PDFBox, Apache POI, Tesseract OCR (tess4j), Bucket4j, Eclipse Paho MQTT, jsoup, SpringDoc OpenAPI

### Client
Flutter 3.41, Dart 3.11, Riverpod, GoRouter, Dio, flutter_quill, fl_chart, mqtt_client, flutter_secure_storage, epub_view, pdfx, webview_flutter, flutter_markdown

---

## License

Private repository. All rights reserved.
