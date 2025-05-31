"""
Calendar Toolset

This module defines tools for managing calendar events.
"""
from typing import List, Optional
from datetime import datetime, timedelta
from agents import function_tool
from pydantic import BaseModel, Field


class CalendarEvent(BaseModel):
    """Representation of a calendar event."""
    id: str = Field(description="Unique identifier for the calendar event")
    title: str = Field(description="The title of the event")
    start_time: datetime = Field(description="Start time of the event")
    end_time: datetime = Field(description="End time of the event")
    description: Optional[str] = Field(
        description="Description of the event", 
        default=None
    )
    location: Optional[str] = Field(
        description="Location of the event",
        default=None
    )


# In-memory store for calendar events (would be replaced with proper API calls in production)
_calendar_events = []


@function_tool
def create_calendar_event(
    title: str,
    start_time: str,
    duration_minutes: int,
    description: Optional[str] = None,
    location: Optional[str] = None
) -> str:
    """
    Create a new calendar event.
    
    Args:
        title: The title of the event
        start_time: Start time in ISO format (YYYY-MM-DDTHH:MM:SS)
        duration_minutes: Duration of the event in minutes
        description: Optional description
        location: Optional location
        
    Returns:
        Confirmation message with the event ID
    """
    import uuid
    
    try:
        # Parse the start time
        start_datetime = datetime.fromisoformat(start_time)
        
        # Calculate end time
        end_datetime = start_datetime + timedelta(minutes=duration_minutes)
        
        # Generate a unique ID
        event_id = str(uuid.uuid4())
        
        # Create the calendar event
        event = CalendarEvent(
            id=event_id,
            title=title,
            start_time=start_datetime,
            end_time=end_datetime,
            description=description,
            location=location
        )
        
        # Add to our in-memory store
        _calendar_events.append(event)
        
        return f"Calendar event created with ID: {event_id}"
    
    except ValueError:
        return "Error: Invalid datetime format. Please use ISO format (YYYY-MM-DDTHH:MM:SS)"


@function_tool
def list_calendar_events(date: Optional[str] = None) -> List[CalendarEvent]:
    """
    List calendar events, optionally filtered by date.
    
    Args:
        date: Optional date in YYYY-MM-DD format to filter events
        
    Returns:
        List of calendar events
    """
    if date is None:
        return _calendar_events
    
    try:
        filter_date = datetime.fromisoformat(date)
        filtered_events = []
        
        for event in _calendar_events:
            event_date = event.start_time.date()
            if event_date == filter_date.date():
                filtered_events.append(event)
                
        return filtered_events
        
    except ValueError:
        # If invalid date format, return all events
        return _calendar_events


@function_tool
def delete_calendar_event(event_id: str) -> str:
    """
    Delete a calendar event.
    
    Args:
        event_id: The unique identifier of the event to delete
        
    Returns:
        Confirmation message
    """
    global _calendar_events
    
    before_count = len(_calendar_events)
    _calendar_events = [event for event in _calendar_events if event.id != event_id]
    after_count = len(_calendar_events)
    
    if before_count == after_count:
        return f"No event found with ID: {event_id}"
    
    return f"Event with ID: {event_id} has been deleted"


@function_tool
def update_calendar_event_time(
    event_id: str,
    start_time: Optional[str] = None,
    duration_minutes: Optional[int] = None,
) -> str:
    """
    Update the timing of a calendar event.
    
    Args:
        event_id: The unique identifier of the event
        start_time: Optional new start time in ISO format (YYYY-MM-DDTHH:MM:SS)
        duration_minutes: Optional new duration in minutes
        
    Returns:
        Confirmation message
    """
    for event in _calendar_events:
        if event.id == event_id:
            changes = []
            
            if start_time is not None:
                try:
                    new_start = datetime.fromisoformat(start_time)
                    duration = (event.end_time - event.start_time).total_seconds() / 60
                    
                    event.start_time = new_start
                    event.end_time = new_start + timedelta(minutes=duration)
                    changes.append("start time")
                    
                except ValueError:
                    return "Error: Invalid datetime format for start_time"
            
            if duration_minutes is not None:
                if duration_minutes <= 0:
                    return "Error: Duration must be greater than 0 minutes"
                
                event.end_time = event.start_time + timedelta(minutes=duration_minutes)
                changes.append("duration")
            
            if not changes:
                return "No changes specified"
                
            return f"Event with ID: {event_id} has been updated ({', '.join(changes)})"
    
    return f"No event found with ID: {event_id}" 