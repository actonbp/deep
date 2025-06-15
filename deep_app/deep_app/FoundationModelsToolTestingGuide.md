# Foundation Models Tool Response Testing Guide

This guide helps diagnose and potentially work around the tool response recognition issue in iOS 26 beta.

## Quick Test Sequence

### 1. Basic Tool Functionality Test
First, verify that tools are being called:

```
"Add task: Test task creation"
```

Expected: Task should be created successfully (this usually works)

### 2. Enhanced Diagnostic Tests

Try each format to see which (if any) the model recognizes:

```
"Run diagnostic test hello with format plain"
"Run diagnostic test hello with format json"
"Run diagnostic test hello with format markdown"
"Run diagnostic test hello with format structured"
```

Watch the console for debug output showing the tool response.

### 3. Task Retrieval Format Tests

Test different response formats for task retrieval:

```
"List current tasks with format simple"
"List current tasks with format json"
"List current tasks with format structured"
"List current tasks with format plain"
```

### 4. Experimental Tool Tests

Try the experimental tool that uses simpler response patterns:

```
"Use experimental tool to count tasks"
"Use experimental tool to list tasks"
"Use experimental tool to check tasks"
```

## What to Look For

### In Console Output
- `DEBUG [ToolName]: Tool called` - Confirms tool execution
- `DEBUG [ToolName]: Returning response:` - Shows what's being returned
- `DEBUG [AppleFoundationService]: Response content:` - Shows model's interpretation

### Success Indicators
- Model correctly repeats diagnostic responses
- Model mentions specific task counts or names
- Model acknowledges receiving data from tools

### Failure Indicators
- "I can't see your tasks"
- "I don't have access to that information"
- "I'm unable to retrieve..."
- Model acts as if no data was returned

## Potential Workarounds

### 1. Use Creation Confirmation Pattern
Since task creation works, you might get indirect confirmation:

```
User: "Add task: Review project documentation"
AI: "I've added 'Review project documentation' to your task list"
User: "How many tasks do I have now?"
AI: [May fail to retrieve count]
```

### 2. Use Experimental Tool
If standard retrieval fails, try:

```
"Use the experimental tool to check how many tasks I have"
```

### 3. Format Discovery
If any diagnostic format works better, you can request that format:

```
"List my tasks using the [working format] format"
```

### 4. Fallback to OpenAI
In Settings, disable "Use On-Device Model (Free)" for reliable tool functionality.

## Debug Mode Commands

For developers investigating the issue:

### Enable Verbose Logging
Look for these patterns in console:
- Tool execution confirmation
- Response content
- Model interpretation

### Test Tool Response Pipeline
1. Confirm tool is called
2. Verify response is generated
3. Check if response reaches model
4. Observe model's interpretation

## Known Working Patterns

These tool uses typically work:
- `addTaskToList` - Creating new tasks
- Basic conversational responses
- Tools that perform actions (vs returning data)

## Known Failing Patterns

These typically fail in iOS 26 beta:
- `listCurrentTasks` - Retrieving task lists
- `getTodaysCalendarEvents` - Calendar queries
- `getScratchpad` - Reading notes
- Any tool that returns data for display

## Reporting the Issue

If you discover a pattern that works:
1. Document the exact prompt used
2. Note the response format that worked
3. Include console debug output
4. Share findings in GitHub issues

## Future Resolution

This issue is expected to be resolved when:
- iOS 26 exits beta
- Apple updates Foundation Models framework
- Official documentation addresses tool responses

Until then, use these diagnostic tools to explore potential workarounds.