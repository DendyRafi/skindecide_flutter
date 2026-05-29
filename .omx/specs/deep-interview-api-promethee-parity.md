# Deep Interview Summary: API PROMETHEE Parity

Final decision from user: Flutter must take the API from http://pikskinmlbb.gamer.gd or https://pikskinmlbb.gamer.gd; it must not be configurable in Flutter because it must point to that web/API.

## Requirements
- Flutter calculation must call the web API endpoint, not rely on local PROMETHEE calculation as primary behavior.
- Endpoint is fixed to pikskinmlbb.gamer.gd.
- UI/result should match web behavior: rank table with name, leaving flow, entering flow, net flow, recommendation marker.
- Verify API works from Flutter code path as much as possible and run Flutter tests/analyze.

## Non-goals
- No user-configurable API base URL in Flutter.
- No admin criteria API migration unless required for calculation.
- No broad UI redesign beyond loading/error/result parity.

## Decision boundaries
- Agent may add HTTP dependency and small API client/service.
- Agent may add loading/error UI and tests.
- Agent may keep local helpers only if they are not the primary calculation path or are needed for tests/compatibility.
