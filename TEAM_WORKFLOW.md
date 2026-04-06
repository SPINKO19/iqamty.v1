# Team Workflow Guide

To work effectively as a team and avoid merge conflicts, please follow these guidelines:

## 1. Branch Strategy
- **NEVER** commit directly to `main` or `develop`.
- Create a feature branch for every task: `git checkout -b feature/your-task-name`.
- Before merging, pull the latest `develop`: `git pull origin develop`.
- Resolve any conflicts locally before making a Pull Request.

## 2. Ownership & Modules
To minimize overlap, we've divided the app into modules. Check `BACKLOG.md` to see who is assigned to what. 
- Try to stay within your module's files.
- If you need to change a core file (e.g., `router.dart`), coordinate with the team first.

## 3. Communication
- Update `BACKLOG.md` when you start or finish a task.
- Use descriptive commit messages: `feat: add login validation`, `fix: burger menu overflow`.
- If you're stuck, ask for help early!

## 4. Code Standards
- Run `flutter analyze` before committing.
- Follow the official [Dart style guide](https://dart.dev/guides/language/effective-dart/style).
