from fastapi import FastAPI, HTTPException
from agents import Runner
from pydantic import BaseModel
from dotenv import load_dotenv
import os
from typing import List, Optional
import asyncio
import sys

# Add the current directory to the path so imports work correctly
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Import our agents
from bryan_agents.orchestrator_agent import orchestrator_agent
from bryan_agents.todo_agent import todo_agent
from bryan_agents.calendar_agent import calendar_agent

# Import toolsets for direct data access
from toolsets.todo_tools import _todos
from toolsets.calendar_tools import _calendar_events, CalendarEvent as CalendarEventModel

# Load environment variables from .env file
load_dotenv()

# Check if OPENAI_API_KEY is loaded (required for agents to work)
if not os.getenv("OPENAI_API_KEY"):
    print("ERROR: OPENAI_API_KEY not found in environment. Agent calls will fail.")
    print("Create a .env file with your API key: OPENAI_API_KEY=sk-...")

# Initialize FastAPI app
app = FastAPI(
    title="Bryan's Brain - Agent Backend",
    description="Multi-agent backend service for Bryan's Brain iOS app using OpenAI Agents SDK.",
    version="0.1.0",
)

# --- Define request and response models for the API ---
class ChatRequest(BaseModel):
    user_message: str
    conversation_history: Optional[List[dict]] = None

class ChatResponse(BaseModel):
    assistant_response: str

class TaskItem(BaseModel):
    id: str
    description: str
    is_done: bool
    priority: int
    estimated_duration_minutes: Optional[int] = None
    category: Optional[str] = None
    project_or_path: Optional[str] = None

class TaskListResponse(BaseModel):
    tasks: List[TaskItem]

class CalendarEvent(BaseModel):
    id: str
    title: str
    start_time: str
    end_time: str
    description: Optional[str] = None
    location: Optional[str] = None

class CalendarResponse(BaseModel):
    events: List[CalendarEvent]

# --- API Endpoint for Chat with the orchestrator agent ---
@app.post("/chat", response_model=ChatResponse)
async def handle_chat_request(request: ChatRequest):
    """
    Receives a user message, processes it with the Orchestrator agent,
    which may hand off to specialized agents, and returns the assistant's response.
    """
    print(f"Received message: {request.user_message}")

    try:
        # Run the orchestrator agent with the user's input
        agent_result = await Runner.run(
            agent=orchestrator_agent, 
            input=request.user_message,
            timeout_s=30
        )
        
        assistant_output = agent_result.final_output if agent_result.final_output else "Sorry, I didn't get a response."
        print(f"Assistant response: {assistant_output}")

    except Exception as e:
        print(f"Error running agent: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Error processing request: {str(e)}"
        )

    return ChatResponse(assistant_response=assistant_output)

# --- API Endpoint to directly access Todo agent ---
@app.post("/todos", response_model=TaskListResponse)
async def get_todos():
    """
    Retrieves the current list of todos by running the Todo agent with a list request.
    """
    try:
        # In a production app, you would have a proper database
        # This simplified approach just accesses the in-memory todos
        return TaskListResponse(tasks=_todos)
        
    except Exception as e:
        print(f"Error getting todos: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving todos: {str(e)}"
        )

# --- API Endpoint to directly access Calendar agent ---
@app.post("/calendar", response_model=CalendarResponse)
async def get_calendar(date: Optional[str] = None):
    """
    Retrieves calendar events, optionally filtered by date.
    """
    try:
        # In a production app, you would make real API calls to calendar providers
        # This simplified approach just accesses the in-memory calendar events
        
        # Filter events by date if provided
        filtered_events = _calendar_events
        if date:
            try:
                from datetime import datetime
                filter_date = datetime.fromisoformat(date).date()
                filtered_events = [e for e in _calendar_events if e.start_time.date() == filter_date]
            except ValueError:
                # Invalid date format, return all events
                pass
        
        # Convert datetime objects to strings for JSON serialization
        events = []
        for event in filtered_events:
            events.append(CalendarEvent(
                id=event.id,
                title=event.title,
                start_time=event.start_time.isoformat(),
                end_time=event.end_time.isoformat(),
                description=event.description,
                location=event.location
            ))
        
        return CalendarResponse(events=events)
        
    except Exception as e:
        print(f"Error getting calendar: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving calendar events: {str(e)}"
        )

# --- Basic Root Endpoint for Health Check ---
@app.get("/")
async def root():
    return {
        "message": "Bryan's Brain Multi-Agent Backend is running.",
        "agents": [
            "Orchestrator (Bryan's Brain)",
            "Todo Agent",
            "Calendar Agent"
        ]
    }

# To run this app (from the agent_backend directory, with venv activated):
# uvicorn main:app --reload 