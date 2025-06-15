# Foundation Models IPC Crash Workaround

## Issue

The Apple Foundation Models framework in iOS 26 beta is experiencing IPC (Inter-Process Communication) crashes when handling tool calls. This manifests as:

- "IPC error: Underlying connection interrupted"
- "Error occurred while sending EndOfStream message"
- "Attempting to send message using a canceled session"
- "voucher_get_current_persona_originator_info() failed: 0"

## Root Cause

The Foundation Models service runs in a separate process and crashes when:
1. Multiple tools are registered (complexity overload)
2. The session is under memory pressure
3. Security sandbox violations occur during tool execution
4. The beta framework has stability issues

## Implemented Workarounds

### 1. Progressive Tool Degradation
- **Attempt 1**: Full tool set (22 tools) - Most features
- **Attempt 2**: Essential tools only (3 tools) - Basic task management
- **Attempt 3**: No tools - Text-only responses

### 2. Session Stabilization
- Session prewarming before requests
- 0.5s delay on retries to let system recover
- 30-second timeout to prevent hanging

### 3. Retry Logic
- Up to 3 attempts with different configurations
- 1-second delay between crash retries
- User-friendly error messages

## User Recommendations

### For Best Stability:
1. **Use Simple Requests**: "Show my tasks" instead of complex multi-tool operations
2. **Switch to OpenAI**: In Settings, disable "Use On-Device Model" for stable tool calling
3. **Wait Between Requests**: Give the system time to recover after crashes
4. **Restart App**: If crashes persist, force-quit and restart the app

### Known Working Commands:
- ✅ "What's on my todo list?"
- ✅ "Create a task to [simple description]"
- ✅ "Mark [task] as done"
- ⚠️ Complex commands may fail

### Known Issues:
- ❌ Rapid consecutive requests
- ❌ Calendar integration with local model
- ❌ AI-enhanced features (task breakdown, enrichment)

## Future Improvements

Once iOS 26 exits beta, we expect:
- Improved IPC stability
- Better memory management
- Full tool support without crashes
- Faster response times

## Debug Information

Enable debug logs to see crash details:
```
DEBUG [AppleFoundationService]: Attempt 1 with all tools
DEBUG [AppleFoundationService]: Attempt 2 with essential tools only
DEBUG [AppleFoundationService]: Attempt 3 with no tools (text only)
```

## Temporary Solution

Until Apple fixes these issues, the app will:
1. Automatically retry with fewer tools
2. Fall back to text-only mode if needed
3. Suggest switching to OpenAI for complex tasks 