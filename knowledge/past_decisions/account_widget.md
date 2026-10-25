# Account widget

- The account `NormalMenu` is replaced by a persistent widget on every menu layout, so the account
  menu stays reachable from the collapsed menu bar and the rail; the side bar no longer has an
  account group.
- The trigger and its menu are a new generic HaxeFolio component, `haxefolio.menu.MenuDropdownWidget`
  (a `DropdownWidget` with `MenuItemDefinition` rows styled like a `NormalMenu`'s, and a header
  slot). In the rail layout it opens right of the rail, like every `DropdownWidget`.
- Icon, a 24 px borderless disc in every state: `ink` with the nickname's first letter (`barBg`
  text) for a player; `borderHover`, the games icon's hexagon fill, with the guest number in `ink`
  for a guest (the last 3 digits past 999, 3 digits in a smaller font), or "?" while the guest
  number is unknown. All captions are Onest SemiBold.
- The menu's header shows the identity's name (the nickname for a player). For a player it is the
  link to their profile and replaces the "My profile" item, keeping its icon; for a guest it is
  muted, plain text.
- Dropdown width on the expanded menu bar: 240 px.
- Room for a fourth menu bar widget (planned):
    - Collapsed bar: HaxeFolio shows the home icon in place of the site name whenever the name
      doesn't fit beside the persistent widgets (measured, not a fixed width). With three widgets
      that happens below about 323 px; with four, below about 371 px.
    - Rail: every target is 40 px (app CSS) and the rail's padding is 6 px, so two top items and four
      widgets fit 280 px tall with 4 px to spare. The hamburger's centre still matches the side bar's
      cross.
