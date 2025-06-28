# Agent Guidance (AI Context)

This directory houses documents that provide additional context and guidance for the AI agents used in the **Bryan's Brain** project.

Place any Markdown (**.md**) or plain-text files here that the AI should reference when generating responses or making decisions, for example:

* **User profile / preferences** – preferred working hours, writing style, recurring commitments, etc.
* **Project overviews** – high-level descriptions of ongoing projects or courses.
* **Glossaries or vocabulary** – domain-specific terms the assistant should recognise.
* **Example workflows or prompts** – illustrated conversations demonstrating desired behaviour.

Developers can extend the prompt-building logic (e.g. in `ChatViewModel`) to read the contents of these files and inject them into the system prompt or as ephemeral context for the model.

> ⚠️  Do **NOT** commit sensitive personal data, credentials, or API keys to version control. Treat this folder as public documentation.

Suggested starting files:

```
agent_guidance/
├─ README.md          ← this file
├─ user_profile.md    ← brief bio & working preferences
├─ projects.md        ← list & description of active projects
└─ glossary.md        ← domain terms & acronyms
```

Feel free to adjust this structure to your needs. 