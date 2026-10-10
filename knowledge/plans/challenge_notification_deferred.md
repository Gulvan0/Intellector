# Incoming challenge notification - deferred

## 3. "Ignore incoming challenges" preference

**Why deferred:** `Preferences.silentChallenges` exists (with its migration and locale label) but
nothing reads it, so the notification still appears with the preference enabled. In the old app the
challenge still reached the challenges menu, only the dialog, tab blink and sound were skipped.

**How to apply:** while it's enabled, receive incoming challenges without putting them on the
notification. `ChallengeInbox.receive` with `notify` off is close, but it also marks them seen, so
decide first whether ignored challenges should still turn the widget's incoming arrow accent.
