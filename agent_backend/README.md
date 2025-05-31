# Agent Backend - Multi-Agent Proof of Concept

**Status: Future Enhancement / Proof of Concept**

This directory contains a proof-of-concept implementation of a multi-agent backend using the [OpenAI Agents SDK](https://github.com/openai/openai-python-agents). 

## What's Here

- **FastAPI Backend**: Multi-agent architecture with specialized agents
- **OrchestratorAgent**: Main coordinator that handles user requests
- **TodoAgent**: Specialized for task management operations  
- **CalendarAgent**: Specialized for calendar operations
- **Toolsets**: Modular tool implementations for different domains
- **API Endpoints**: RESTful endpoints for iOS app integration

## Architecture

```
User Message → OrchestratorAgent → Specialized Agents (Todo/Calendar)
                     ↓
              FastAPI Backend (/chat endpoint)
                     ↓  
              iOS App (future integration)
```

## Current Decision

We're focusing on improving the existing single-agent Swift implementation in the main iOS app for now. This multi-agent backend will be considered for future versions when:

1. The core iOS app functionality is more mature
2. We need more sophisticated agent coordination 
3. We want to scale beyond single-agent capabilities

## Setup (For Future Reference)

```bash
cd agent_backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env  # Add your OPENAI_API_KEY
uvicorn main:app --reload
```

## What Was Implemented

- ✅ Multi-agent orchestration with handoffs
- ✅ Specialized agents for different domains
- ✅ Tool implementations (todo and calendar operations)
- ✅ FastAPI REST endpoints
- ✅ In-memory data persistence
- ✅ Proper error handling and type safety

## What Would Be Next

- iOS app integration via HTTP client
- Persistent data storage (SQLite/PostgreSQL)
- Additional specialized agents
- Enhanced guardrails and testing
- Production deployment setup

See the main `TODO.md` for the complete roadmap. 