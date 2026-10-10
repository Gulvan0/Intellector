# Incoming challenge notification - deferred

## 2. Request error handling

**Why deferred:** there is no app-wide presentation for failed requests yet. Decline (single and
"Decline all") removes the entry at once and a failed request is silently ignored - the challenge
stays pending on the server. A failed Accept re-enables the card's buttons.

**How to apply:** once failed requests have a common presentation, route Accept/Decline failures
through it; a 404 on Accept (challenge already gone) should remove the entry instead.

## 3. "Ignore incoming challenges" preference

**Why deferred:** `Preferences.silentChallenges` exists (with its migration and locale label) but
nothing reads it, so the notification still appears with the preference enabled. In the old app the
challenge still reached the challenges menu, only the dialog, tab blink and sound were skipped.

**How to apply:** while it's enabled, receive incoming challenges without putting them on the
notification. `ChallengeInbox.receive` with `notify` off is close, but it also marks them seen, so
decide first whether ignored challenges should still turn the widget's incoming arrow accent.
