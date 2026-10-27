# todo-sync
Task: Add user accounts and syncing across devices to the todo app.
Window: 3

## Open
- 1. Where should synced todos be stored? (asked; blocks: sync backend)
  a) SQLite on a small server  b) Postgres  c) A hosted service such as Firebase
  Recommendation: a), simplest to run.
- 2. How should users sign in? (asked; blocks: accounts)
  a) JWT with email and password  b) Magic links by email  c) OAuth with GitHub
  Recommendation: a).
- 3. Should existing local todos be uploaded on first sign-in? (asked)
  Recommendation: yes.

## Queued
- 4. How should conflicting edits from two devices be resolved? (after 1)
- 5. Should the CLI work offline and sync later? (after 1)
- 6. Should todos get a "last modified" timestamp? (after 4)

## Decided

## Dropped

## Assumptions in use
