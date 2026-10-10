# Incoming challenge notification

- **No HaxeUI `NotificationManager`.** Its template (title/close/rule/icon/text body), 300 px height
  cap, add/remove-only repositioning and app-wide singleton layout don't fit. A generic notification
  layer is added to HaxeFolio instead, covering only what every notification shares; layouts are the
  host's.
- **Correspondence time string** is Onest 13 / 500 (the spec's "Archivo" is a slip; the theme allows
  only Onest and IBM Plex Mono).
- **Several challenges from one caller are shown separately** (the server allows up to
  `max_same_callee_active_challenges` of them, each with its own id, each accepted on its own).
  The spec's "replace in place" rule is not implemented.
- **Time-control kind icons:** the old repo's coloured set (`assets/symbols/time_controls`, all six
  kinds), ported to `assets/images/common/time_controls`.
- **Board preview:** a bare `BoardSurface` (the "mini-board" of the spec).
- **Refresh semantics:** every pending challenge this tab hasn't announced yet raises a notification
  (on a fresh load - all of them; after a reconnect - only new ones). Hidden ones stay hidden for the
  session; challenges missing from a refresh are removed.
- **Spacing of the notification layer:** 12 px from the viewport edges in both layouts, 10 px between
  separate notifications.
