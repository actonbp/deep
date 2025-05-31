"""
Todo List Toolset

This module defines tools for managing todo items.
"""
from typing import List, Optional
from agents import function_tool
from pydantic import BaseModel, Field


class TodoItem(BaseModel):
    """Representation of a todo item."""
    id: str = Field(description="Unique identifier for the todo item")
    description: str = Field(description="The text description of the todo item")
    is_done: bool = Field(description="Whether the todo item is completed", default=False)
    priority: int = Field(description="Priority of the task (1-5, where 1 is highest)", default=3)
    estimated_duration_minutes: Optional[int] = Field(
        description="Estimated time to complete the task in minutes", 
        default=None
    )
    category: Optional[str] = Field(
        description="Category or context of the task", 
        default=None
    )
    project_or_path: Optional[str] = Field(
        description="Project or path the task belongs to",
        default=None
    )


# In-memory store for todos (would be replaced with DB in production)
_todos = []


@function_tool
def add_task_to_list(
    description: str, 
    priority: int = 3,
    estimated_duration_minutes: Optional[int] = None,
    category: Optional[str] = None,
    project_or_path: Optional[str] = None
) -> str:
    """
    Add a new task to the todo list.
    
    Args:
        description: The description of the task
        priority: Priority from 1-5 (1 is highest)
        estimated_duration_minutes: Estimated time to complete in minutes
        category: Category or context of the task
        project_or_path: Project or path the task belongs to
        
    Returns:
        Confirmation message with the task ID
    """
    import uuid
    
    # Generate a unique ID
    task_id = str(uuid.uuid4())
    
    # Create the todo item
    todo_item = TodoItem(
        id=task_id,
        description=description,
        priority=priority,
        estimated_duration_minutes=estimated_duration_minutes,
        category=category,
        project_or_path=project_or_path
    )
    
    # Add to our in-memory store
    _todos.append(todo_item)
    
    return f"Task added with ID: {task_id}"


@function_tool
def list_current_tasks() -> List[TodoItem]:
    """
    List all current tasks in the todo list.
    
    Returns:
        List of todo items
    """
    return _todos


@function_tool
def remove_task_from_list(task_id: str) -> str:
    """
    Remove a task from the todo list.
    
    Args:
        task_id: The unique identifier of the task to remove
        
    Returns:
        Confirmation message
    """
    global _todos
    
    before_count = len(_todos)
    _todos = [todo for todo in _todos if todo.id != task_id]
    after_count = len(_todos)
    
    if before_count == after_count:
        return f"No task found with ID: {task_id}"
    
    return f"Task with ID: {task_id} has been removed"


@function_tool
def update_task_status(task_id: str, is_done: bool) -> str:
    """
    Update the completion status of a task.
    
    Args:
        task_id: The unique identifier of the task
        is_done: Whether the task is complete
        
    Returns:
        Confirmation message
    """
    for todo in _todos:
        if todo.id == task_id:
            todo.is_done = is_done
            status = "completed" if is_done else "marked as not complete"
            return f"Task with ID: {task_id} has been {status}"
    
    return f"No task found with ID: {task_id}"


@function_tool
def update_task_priority(task_id: str, priority: int) -> str:
    """
    Update the priority of a task.
    
    Args:
        task_id: The unique identifier of the task
        priority: New priority (1-5, where 1 is highest)
        
    Returns:
        Confirmation message
    """
    if priority < 1 or priority > 5:
        return "Priority must be between 1 and 5"
    
    for todo in _todos:
        if todo.id == task_id:
            todo.priority = priority
            return f"Task with ID: {task_id} has been updated to priority {priority}"
    
    return f"No task found with ID: {task_id}"


@function_tool
def update_task_estimated_duration(task_id: str, estimated_duration_minutes: int) -> str:
    """
    Update the estimated duration of a task.
    
    Args:
        task_id: The unique identifier of the task
        estimated_duration_minutes: Estimated time to complete in minutes
        
    Returns:
        Confirmation message
    """
    if estimated_duration_minutes <= 0:
        return "Duration must be greater than 0 minutes"
    
    for todo in _todos:
        if todo.id == task_id:
            todo.estimated_duration_minutes = estimated_duration_minutes
            return f"Task with ID: {task_id} has been updated with estimated duration of {estimated_duration_minutes} minutes"
    
    return f"No task found with ID: {task_id}"


@function_tool
def update_task_metadata(
    task_id: str, 
    category: Optional[str] = None,
    project_or_path: Optional[str] = None
) -> str:
    """
    Update the metadata (category and/or project_or_path) of a task.
    
    Args:
        task_id: The unique identifier of the task
        category: New category
        project_or_path: New project or path
        
    Returns:
        Confirmation message
    """
    for todo in _todos:
        if todo.id == task_id:
            changes = []
            
            if category is not None:
                todo.category = category
                changes.append(f"category='{category}'")
                
            if project_or_path is not None:
                todo.project_or_path = project_or_path
                changes.append(f"project_or_path='{project_or_path}'")
                
            if not changes:
                return "No changes specified"
                
            return f"Task with ID: {task_id} has been updated with {', '.join(changes)}"
    
    return f"No task found with ID: {task_id}" 