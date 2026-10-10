# Challenges across tabs

- Which challenges are pending is the server's state: every change reaches all of the user's tabs as
  a WS event on their own channels, including changes the user made themselves.
- What the user has dismissed or seen is the browser's state: localStorage, synced to open tabs by
  the `storage` event. Not per account.
- Tabs share the dismissed challenge ids: hidden (×, Ignore all), declined, cleared by an Accept, or
  arrived while a dropdown was open. A new tab or a reload shows exactly what's still on display
  elsewhere. The stored set keeps the newest 100 ids and only grows otherwise (each write merges
  with what's stored), so a tab that hasn't received a challenge yet can't erase its mark.
- Tabs share a "seen up to" incoming challenge id: opening the dropdown raises it to the newest
  pending one, and so does an arrival while a dropdown is open. The incoming arrow is accent while a
  pending incoming challenge is above it.
- The active notification (which card is expanded) stays per tab.
- An acceptance locks the replies until its request resolves, even if the accepted challenge leaves
  the inbox first (the server's own event can beat the response).
- The game started by the other side accepting the user's challenge opens in one tab:
  - the tab that has focus when it's known navigates at once;
  - otherwise every tab blinks "Game started!" with the notification favicon, and the first tab
    focused navigates; the others stop blinking. The claim is a monotonic "redirected game id" in
    localStorage, so a tab learning about the game after it was claimed does nothing;
  - the redirect happens even if the game has ended by then.
- An outgoing challenge missing from a refresh may have been accepted while disconnected: the app
  fetches it and, if it has a resulting game, treats it as accepted.
