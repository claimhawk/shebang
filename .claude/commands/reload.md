# /reload - Rebuild and restart Shebang

Rebuild the Shebang app and restart it. Use this during development to quickly test changes.

## Instructions

1. Run the build script: `./build.sh`
2. If build succeeds, restart the app by:
   - First, use `osascript` to quit the current app
   - Then launch the newly built app

```bash
./build.sh && osascript -e 'quit app "Shebang"' && sleep 1 && open Shebang.app
```

This will:
- Build Shebang.app from source
- Close the currently running instance
- Launch the new build

Note: The current session will end when the app restarts, but dtach preserves the session state.
