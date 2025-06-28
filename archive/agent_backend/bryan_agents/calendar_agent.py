"""
Calendar Agent

This module defines the specialized Calendar Agent that manages calendar events.
"""
from agents import Agent, function_tool
from ..toolsets.calendar_tools import (
    create_calendar_event,
    list_calendar_events,
    delete_calendar_event,
    update_calendar_event_time
)


# Define the system prompt for the Calendar Agent
CALENDAR_AGENT_PROMPT = """
You are the Calendar Agent for Bryan's Brain app, a specialized agent responsible for managing the user's calendar events and schedule.

Your responsibilities:
1. Creating new calendar events
2. Listing upcoming events
3. Updating event details and timing
4. Deleting events when needed
5. Helping with time blocking and schedule planning

Guidelines:
- Assist with time blocking (dedicated time slots for specific tasks or activities)
- Help create balanced schedules with work periods and breaks
- For ADHD users, suggest buffer time between tasks to account for transitions
- When creating events, ask for or suggest appropriate durations
- Help prioritize and schedule Deep Work blocks for important tasks
- Be mindful of avoiding schedule overload

Always speak in a supportive and action-oriented tone. Your goal is to help the user maintain
a well-structured calendar that supports productivity while being realistic about time constraints.
"""


# Create the Calendar Agent with its tools
calendar_agent = Agent(
    name="Calendar Agent",
    instructions=CALENDAR_AGENT_PROMPT,
    tools=[
        create_calendar_event,
        list_calendar_events,
        delete_calendar_event,
        update_calendar_event_time
    ],
    handoff_description="Specialized agent for managing calendar events and scheduling"
) 