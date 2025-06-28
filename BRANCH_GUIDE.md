# Git Branch Guide for Bryan's Brain

## Current Branch Structure (December 28, 2024)

```
main
├── feature/image-upload      ← ChatGPT-style image upload feature
└── feature/enhanced-roadmap  ← ADHD-focused roadmap improvements
```

## Branch Purposes

### `main` Branch
- **Status**: Stable, warning-free, production-ready
- **Last Update**: December 28, 2024 - Fixed all Xcode warnings
- **Use**: Always safe to build and run from this branch
- **Protection**: Never commit directly unless feature is tested

### `feature/image-upload` Branch  
- **Purpose**: Add image upload capability to chat interface
- **Features**:
  - PHPickerViewController for image selection
  - ChatGPT-style image preview in input area
  - OpenAI Vision API integration (gpt-4o model)
  - Image display in chat messages
- **Status**: In development

### `feature/enhanced-roadmap` Branch
- **Purpose**: Enhance roadmap tab for ADHD users
- **Features**:
  - Task dependency visualization
  - Visual path connections between related tasks
  - Individual task detail views
  - "Next action" clarity improvements
- **Status**: Planned

## Working with Branches

### Check Current Branch
```bash
git branch
```

### Switch Branches
```bash
git checkout main                    # Go to stable branch
git checkout feature/image-upload    # Work on image feature
git checkout feature/enhanced-roadmap # Work on roadmap feature
```

### Create New Feature Branch
```bash
git checkout main                    # Start from stable base
git checkout -b feature/new-feature  # Create and switch to new branch
```

### Merge Feature When Complete
```bash
git checkout main                    # Switch to main
git merge feature/image-upload       # Merge completed feature
git push                            # Push to GitHub
```

## Important Notes

1. **Always test on device** before merging to main
2. **Keep main stable** - it's our safety net
3. **One feature per branch** - easier to manage and rollback
4. **Commit frequently** on feature branches
5. **Update documentation** when features are complete

## Emergency Rollback

If something breaks badly:
```bash
git checkout main        # Return to stable version
git branch -D feature/broken-feature  # Delete broken branch
```

The main branch at commit `f6dd888` is always a safe checkpoint!