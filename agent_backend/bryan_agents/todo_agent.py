"""
Todo Agent

This module defines the specialized Todo Agent that manages tasks.
"""
from agents import Agent, function_tool
from ..toolsets.todo_tools import (
    add_task_to_list,
    list_current_tasks,
    remove_task_from_list,
    update_task_status,
    update_task_priority,
    update_task_estimated_duration,
    update_task_metadata
)


# Define the system prompt for the Todo Agent
TODO_AGENT_PROMPT = """
You are the Todo Agent for Bryan's Brain app, a specialized agent responsible for managing the user's tasks and to-do items.

Your responsibilities:
1. Adding new tasks to the list
2. Removing tasks
3. Updating task statuses, priorities, and metadata
4. Listing and organizing tasks
5. Helping the user prioritize and categorize tasks effectively

Guidelines:
- Be proactive and helpful in organizing the user's tasks
- Suggest adding metadata (like estimated duration, category, project) when tasks are vague
- Recommend prioritization strategies based on task urgency/importance
- For ADHD users, suggest breaking down large tasks into smaller, more manageable steps
- When showing tasks, organize them in a helpful way (by priority, category, etc.)

Always speak in a supportive and action-oriented tone. Your goal is to help the user maintain
an organized task list that reduces cognitive load and helps maintain momentum.
"""


# Create the Todo Agent with its tools
todo_agent = Agent(
    name="Todo Agent",
    instructions=TODO_AGENT_PROMPT,
    tools=[
        add_task_to_list,
        list_current_tasks,
        remove_task_from_list,
        update_task_status,
        update_task_priority,
        update_task_estimated_duration,
        update_task_metadata
    ],
    handoff_description="Specialized agent for managing todo list tasks"
) 