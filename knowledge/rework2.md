# Plan: Migrate consumer files from struct.Variant to lib.intellectorboard.plytree

## Context

`struct/Variant.hx` has been deleted. The replacement module `lib.intellectorboard.plytree`
already exists locally. All consumer files that imported `struct.Variant` or
`struct.Variant.VariantPath` are now broken.

This plan covers:
1. **Additions / fixes** to the existing lib module
2. **New analysis view files** replacing the four broken `Variant*` files
3. **Wiring updates** in ControlTabs, Analysis, LiveGame, ScreenType, ComponentConstructor,
   ShareDialog, StudyParamsDialog, and GameBoard

### Scope of path usage

`PlyTreePath` is kept **only** inside the DTO mapping layer (`net/models/study/mappers/`).
Every file outside that package works exclusively with node references (`PlyTreeNodeBase`,
`PlyTreePlyNode`). No `PlyTreePath` in view code, no navigation-by-path helpers.

### Other replacements to apply when touching files

- `net.shared.board.Situation` → `lib.intellectorboard.position.Position`
- `net.shared.board.RawPly` → `lib.intellectorboard.primitives.ply.RawPly`
- `net.shared.PieceColor` → `lib.intellectorboard.primitives.piece.PieceColor`
- `net.shared.utils.MathUtils` → look up counterpart in `lib.std` during implementation
- `Networker` / `Requests` calls remain broken; do not fix them

---

## Assessment: necessity of path-based interface methods

The old `IVariantView` interface used `VariantPath` as the node-identity type because `struct.Variant`
was an opaque object only addressable via paths. `PlyTree` exposes actual node objects — through
`addChild()` / `removeChild()`, the `children` array, and `parent` pointers — making paths
redundant as an internal identifier.

**`addChildNode(parentPath:VariantPath, ply, selectChild)`**
The sole external caller is `ControlTabs`, which calls only `addChildToSelectedNode` for board moves.
`addChildNode` with an explicit parent was only needed during view initialization from an existing
`Variant`, iterating nodes one by one. The new views are initialized by the constructor that receives
a complete `PlyTree` and traverses it directly. There are no other external callers.
→ **Remove from the interface entirely.**

**`removeNodeByPath(path:VariantPath)`**
Removal is triggered by ctrl+click *inside* the view, where the clicked UI component already holds a
`PlyTreePlyNode` reference. Deriving a path from the component just to pass it back to the view is
an unnecessary round-trip.
→ **Remove from the interface; keep as an internal method taking `PlyTreePlyNode`.**

**`getSelectedNode():VariantPath`**
`ControlTabs.redrawBranchingTab` calls this to preserve the selection when switching tab types.
A `Null<PlyTreePlyNode>` reference serves that purpose directly, without serializing to a path.
→ **Keep on the interface but change return type to `Null<PlyTreePlyNode>`.**

---

## Selected-branch representation

Selected state lives **only** in the view classes (UI side), never inside `lib.intellectorboard`.

```haxe
private var selectedBranch:Array<PlyTreePlyNode> = [];
// Invariant: selectedBranch forms a root-to-leaf path through the tree.
// selectedBranch[0] is a direct child of plyTree.root;
// selectedBranch[i+1] is always a child of selectedBranch[i].

private var selectedIndex:Int = -1;
// -1  → root position is displayed (no move played yet in the view)
// ≥ 0 → selectedBranch[selectedIndex] is the currently highlighted move
```

Building the selected branch from a clicked node `n:PlyTreePlyNode`:
```haxe
// 1. Extend to leftmost leaf
var leaf:PlyTreePlyNode = n;
while (leaf.children.length > 0)
    leaf = leaf.children[0];

// 2. Walk from leaf to root, collect, reverse
var branch:Array<PlyTreePlyNode> = [];
var cur:PlyTreeNodeBase = leaf;
while (cur.parent != null)
{
    branch.push(cast(cur, PlyTreePlyNode));
    cur = cur.parent;
}
branch.reverse();
selectedBranch = branch;
selectedIndex = n.depth - 1;   // depth-1 because root is at depth 0, branch[0] is at depth 1
```

`getSelectedNode()` returns `selectedIndex >= 0 ? selectedBranch[selectedIndex] : null`.

---

## Dependency diagram

```
Phase 0: Additions/fixes to lib.intellectorboard.plytree
  PlyTree.getMainLineBranch()
  PlyTreeNodeBase.subtreeWidth()
  Fix: collectNodesToTheRight() return type
       |
Phase 1: New analysis view files
  IPlyTreeView          (replaces IVariantView)
  PlyTreeOutline        (replaces VariantOutline)
  PlyTreeGraph          (replaces VariantTree)
  PlyTreePlainText      (replaces VariantPlainText)
       |
Phase 2: Wiring files
  ControlTabs, ComponentConstructor, ScreenType
  GameBoard, Analysis, LiveGame
  ShareDialog, StudyParamsDialog
```

---

## Key API mapping

| Old (`struct.Variant`) | New |
|---|---|
| `new Variant(situation)` | `new PlyTree(position:Position)` |
| `variant.startingPosition` | `plyTree.root.positionAfter` |
| `variant.getMainLineBranch()` | `plyTree.getMainLineBranch()` → `Array<PlyTreePlyNode>` |
| `variant.getAllNodes()` | `plyTree.collectPlyNodes()` — for DTO use only |
| `variant.addChildToNode(ply, path)` | `node.addChild(ply)` → `PlyTreePlyNode` |
| `variant.removeNode(path)` | `node.parent.removeChild(node)` |
| `variant.clear(newPos)` | `plyTree = new PlyTree(newPos ?? plyTree.root.positionAfter)` |
| `variant.serialize()` | *(removed — DTO mappers handle that)* |
| `Variant.deserialize(str)` | *(removed — DTO mappers handle that)* |
| `ply.toNotation(situation, b)` | `PlyFormatter.toNotation(ply, position, b)` |
| Right siblings of node `n` | `n.parent.children` sliced from `indexOf(n)+1` |
| `path.asArray()[depth-1]--` | **eliminated** — stable `id`-based maps, no remap |

---

## Phase 0: Additions and fixes to lib.intellectorboard.plytree

### Fix: `PlyTreeNodeBase.collectNodesToTheRight()` return type

The existing implementation declares `var resultingNodes:Array<PlyTreePlyNode>` but pushes
`PlyTreeNodeBase` values returned by `collectDescendants()`. Change to:

```haxe
public function collectNodesToTheRight():Array<PlyTreeNodeBase>
{
    var resultingNodes:Array<PlyTreeNodeBase> = [];
    ...
}
```

Callers that need only ply nodes can filter or cast; the root node never appears in the
result because `HorizontalNodeIterator` only yields `PlyTreePlyNode` values.

### Add: `PlyTree.getMainLineBranch():Array<PlyTreePlyNode>`

```haxe
public function getMainLineBranch():Array<PlyTreePlyNode>
{
    var result:Array<PlyTreePlyNode> = [];
    var cur:PlyTreeNodeBase = root;
    while (cur.children.length > 0)
    {
        var next:PlyTreePlyNode = cur.children[0];
        result.push(next);
        cur = next;
    }
    return result;
}
```

### Add: `PlyTreeNodeBase.subtreeWidth():Int`

Number of leaf nodes in the subtree — equals the number of HCI (horizontal cell index)
columns the subtree occupies in `PlyTreeGraph`.

```haxe
public function subtreeWidth():Int
{
    if (children.length == 0)
        return 1;

    var total:Int = 0;
    for (child in children)
        total += child.subtreeWidth();
    return total;
}
```

### Note: `PlyTreePath` helpers

No new helpers are added to `PlyTreePath`. The existing API (`getChild`, `getParent`,
`getDependency`, `fromString`, `toString`) is sufficient for the DTO mapping layer.
`PlyTreeNodeBase.collectDescendantsWithPaths` provides paths where needed for DTO output.

---

## Phase 1: New analysis view files

Delete the four broken files and create named replacements:

| Old file | New file |
|---|---|
| `gfx/analysis/IVariantView.hx` | `gfx/analysis/IPlyTreeView.hx` |
| `gfx/analysis/VariantOutline.hx` | `gfx/analysis/PlyTreeOutline.hx` |
| `gfx/analysis/VariantTree.hx` | `gfx/analysis/PlyTreeGraph.hx` |
| `gfx/analysis/VariantPlainText.hx` | `gfx/analysis/PlyTreePlainText.hx` |

### 1a. `IPlyTreeView.hx`

```haxe
package gfx.analysis;

import lib.intellectorboard.plytree.PlyTreePlyNode;
import lib.intellectorboard.primitives.ply.RawPly;
import lib.intellectorboard.position.Position;
import gfx.utils.PlyScrollType;

interface IPlyTreeView
{
    public function init(eventHandler:PeripheralEvent->Void):Void;
    public function clear(?newStartingPosition:Position):Void;
    public function addChildToSelectedNode(ply:RawPly, selectChild:Bool):Void;
    public function getSelectedNode():Null<PlyTreePlyNode>;
    public function handlePlyScrolling(type:PlyScrollType):Void;
}
```

Note: `addChildNode(parent, ply, select)` and `removeNode(node)` are **not** on the
interface. They are internal implementation methods. The interface only covers what
`ControlTabs` actually calls from outside.

### 1b. `PlyTreeOutline.hx` (replaces `VariantOutline`)

**Extends:** `TreeView implements IPlyTreeView`

**State:**
```haxe
private var plyTree:PlyTree;
private var rootNode:TreeViewNode;
private var eventHandler:PeripheralEvent->Void;

private var selectedBranch:Array<PlyTreePlyNode> = [];
private var selectedIndex:Int = -1;
```

**HaxeUI node data schema:** `{plyNodeId:Int}` stored on each `TreeViewNode`.
All HaxeUI path lookups (`findNodeByPath`) use the sequence of per-level child indices.
To navigate from a HaxeUI `TreeViewNode` to its `PlyTreePlyNode`: look it up from a
`Map<Int, TreeViewNode>` keyed by `PlyTreePlyNode.id` maintained alongside the tree view.

**`getSelectedNode():Null<PlyTreePlyNode>`**
```haxe
return selectedIndex >= 0 ? selectedBranch[selectedIndex] : null;
```

**`addRec(parentTreeNode:TreeViewNode, node:PlyTreePlyNode)`**
```haxe
private function addRec(parentTreeNode:TreeViewNode, node:PlyTreePlyNode)
{
    var childTreeNode:TreeViewNode = addUiChildNode(parentTreeNode, node);
    for (child in node.children)
        addRec(childTreeNode, child);
}
```

**`addUiChildNode(parentTreeNode, plyNode:PlyTreePlyNode):TreeViewNode`**
- Label: `'${plyNode.depth}. ${PlyFormatter.toNotation(plyNode.ply, plyNode.parent.positionAfter, false)}'`
  (adjust turn number for starting color if needed)
- `nodeId` = child index among parent's `children`: `plyNode.parent.children.indexOf(plyNode)`
- Store `{plyNodeId: plyNode.id}` in node data
- Register `childTreeNode` in `Map<Int, TreeViewNode>` keyed by `plyNode.id`

**`addChildToSelectedNode(ply, selectChild)`**
- `parentPlyNode = selectedIndex >= 0 ? selectedBranch[selectedIndex] : cast(plyTree.root, PlyTreeNodeBase)`
- `var newPlyNode:PlyTreePlyNode = parentPlyNode.addChild(ply)`
- `var parentTreeNode:TreeViewNode = selectedIndex >= 0 ? nodeViewById.get(parentPlyNode.id) : rootNode`
- Call `addUiChildNode(parentTreeNode, newPlyNode)`
- If `selectChild`: rebuild selected branch through `newPlyNode`

**`removeUiNode(treeNode:TreeViewNode)`** (ctrl+click handler, internal)
- Get `plyNodeId` from `treeNode.data`
- Find the `PlyTreePlyNode` via `nodeViewById` (iterate to find by id) or maintain a parallel `Map<Int, PlyTreePlyNode>`
- Handle selected-branch update (if on branch: select parent, rebuild branch via leaf of remaining sibling tree)
- Update HaxeUI `nodeId` for right siblings: for each right sibling of the removed node, its `nodeId` decrements by 1. Right siblings = `parent.children` slice starting from `indexOf(node)+1`. Update their `TreeViewNode.data.nodeId` before calling `parent.removeChild(node)`.
- `treeNode.parentNode.removeNode(treeNode)`
- `parent.removeChild(node)`
- Remove entry from `nodeViewById`

**`refreshSelection()`**
```haxe
if (selectedIndex < 0)
    rootNode.selected = true;
else
{
    var target:TreeViewNode = nodeViewById.get(selectedBranch[selectedIndex].id);
    target.selected = true;
}
```

**`selectBranchUnsafe(branch:Array<PlyTreePlyNode>, index:Int)`**
Store `selectedBranch = branch; selectedIndex = index;` then call `refreshSelection()`.

**`handlePlyScrolling(type:PlyScrollType)`**
Adjust `selectedIndex` within `[-1, selectedBranch.length - 1]`, call `refreshSelection()`:
- `Home` → `-1`
- `Prev` → `max(-1, selectedIndex - 1)`
- `Next` → `min(selectedBranch.length - 1, selectedIndex + 1)`
- `End` → `selectedBranch.length - 1`
- `Precise(n)` → `n - 1` (0 = root position → index -1)

**`clear(?newStartingPosition:Position)`**
```haxe
rootNode.clearNodes();
nodeViewById = [];
plyTree = new PlyTree(newStartingPosition ?? plyTree.root.positionAfter);
selectedBranch = [];
selectedIndex = -1;
```

**Constructor:** `new(plyTree:PlyTree, ?selectedNode:Null<PlyTreePlyNode>)`
- Store reference, create root `TreeViewNode`, call `addRec` over `plyTree.root.children`
- Initial selection: if `selectedNode != null`, build branch through it; else build main-line branch

### 1c. `PlyTreeGraph.hx` (replaces `VariantTree`)

**Extends:** `Absolute implements IPlyTreeView`

#### Node grid layout

- **VCI** (vertical cell index) = `node.depth`
- **HCI** (horizontal cell index): root = 1; first child = parent's HCI; Nth sibling (N > 0) = max HCI of all previous siblings' subtrees + 1
- Column width = widest label among nodes at that HCI
- Node position: X = sum of widths+spacers for columns 1…HCI-1; Y = VCI × row height

#### Maps (keyed by `PlyTreeNodeBase.id`)

```haxe
private var nodes:Map<Int, Node> = [];
private var arrows:Map<Int, Arrow> = [];      // arrow INTO node; none for root
private var plyNodeRefs:Map<Int, PlyTreePlyNode> = [];
private var columnWidths:Map<Int, Float> = [];
```

#### State

```haxe
private var plyTree:PlyTree;
private var selectedBranch:Array<PlyTreePlyNode> = [];
private var selectedIndex:Int = -1;
private var indicateColors:Bool;
```

#### `getSelectedNode()`
`return selectedIndex >= 0 ? selectedBranch[selectedIndex] : null;`

#### `drawFromScratch(plyTree, ?selectedNode:Null<PlyTreePlyNode>)`

```haxe
var rootNode:Node = new Node(scale, plyTree.root.id, startingPositionLabel, false, onSelect, _ -> {});
nodes.set(plyTree.root.id, rootNode);
addComponent(rootNode);

for (data in plyTree.collectPlyNodes())
{
    var n:PlyTreePlyNode = cast data.node;
    var label:String = PlyFormatter.toNotation(n.ply, n.parent.positionAfter, indicateColors);
    var node:Node = new Node(scale, n.id, label, false, onSelect, onRemove);
    var arrow:Arrow = new Arrow(scale);
    nodes.set(n.id, node);
    arrows.set(n.id, arrow);
    plyNodeRefs.set(n.id, n);
    addComponent(node); addComponent(arrow); arrow.moveComponentToBack();
}
```

Initial selection via `selectedNode` (or main line if null).

#### `buildOptimalDisplacement():DisplacementInfo`

Same algorithm as old `VariantTree.buildOptimalDisplacement()`:
- `info.cellularMapping` keyed by `Int` (node id) instead of path string
- Recursive traversal uses `node.children` instead of `childCount(path)` + `path.child(n)`
- `node.depth` replaces `path.length`
- `node.children.length > 0` replaces `variantRef.pathExists(...)`

#### `refreshLayout()`

Identical in structure to old `VariantTree.refreshLayout()`, using id keys.
Arrow endpoints: `nodes.get(plyNode.parent.id).outputPos()` and `nodes.get(plyNode.id).inputPos()`.

#### `addChildToSelectedNode(ply, selectChild)`

1. `parentNode = getSelectedNode() ?? cast plyTree.root`
2. `var wasLeaf:Bool = parentNode.children.length == 0`
3. `var newNode:PlyTreePlyNode = parentNode.addChild(ply)`
4. Create `Node` + `Arrow`, key by `newNode.id`; add as components
5. If `wasLeaf`: new node shares parent's HCI column → call `refreshLayout()`
6. If `!wasLeaf`: new sibling shifts all right-nodes by 1 HCI column → call `refreshLayout()`
   - *(Prefer full `refreshLayout()` over manual pixel arithmetic for correctness)*
7. If `selectChild`: rebuild selected branch through `newNode`

#### `removeNodeByPath` → `removeUiNode(node:PlyTreePlyNode)` (internal, triggered by ctrl+click)

1. Handle selected-branch reselection (if `node` or a descendant is selected: select parent)
2. Collect `node`'s full subtree: `node.collectDescendants()` cast appropriately
3. Remove each from `nodes`, `arrows`, `plyNodeRefs`; call `removeComponent` for each UI element
4. `var isOnlyChild:Bool = node.parent.children.length == 1`
5. `node.parent.removeChild(node)`
6. If `!isOnlyChild`: right siblings gained a lower HCI → call `refreshLayout()`
7. If `isOnlyChild`: parent's column is now empty, layout shifts → call `refreshLayout()`

> **Use `refreshLayout()` for all post-mutation layout.** The `subtreeWidth()` and pixel-shift
> calculations described in the Ultraplan are an optimization that can be added later. Correctness
> first.

#### `deselectAll()`

Walk `selectedBranch[0..selectedIndex]`; deselect `nodes.get(n.id)`, unhighlight `arrows.get(n.id)`.

#### `selectBranchUnsafe(branch:Array<PlyTreePlyNode>, index:Int)`

1. `deselectAll()`
2. If `index < 0`: select root node (highlight nothing)
3. For `i in 0...branch.length`: highlight `arrows.get(branch[i].id)` as "on branch" vs "past selection"
4. Select `nodes.get(branch[index].id)` if `index >= 0`
5. Store `selectedBranch = branch; selectedIndex = index`

#### `handlePlyScrolling` — same arithmetic as `PlyTreeOutline`

#### Node click handler `onSelect(nodeId:Int)`

```haxe
private function onSelect(nodeId:Int)
{
    var clickedPlyNode:Null<PlyTreePlyNode> = plyNodeRefs.get(nodeId);

    if (clickedPlyNode == null)   // root node clicked
    {
        selectBranchUnsafe(selectedBranch, -1);
        eventHandler(ScrollBtnPressed(Precise(0)));
        return;
    }

    var newBranch:Array<PlyTreePlyNode> = buildBranchThrough(clickedPlyNode);
    var newIndex:Int = clickedPlyNode.depth - 1;

    if (selectedBranch.length > 0 && selectedBranch[newIndex] == clickedPlyNode)
    {
        // Node is already on current branch — just scroll
        selectBranchUnsafe(selectedBranch, newIndex);
        eventHandler(ScrollBtnPressed(Precise(clickedPlyNode.depth)));
    }
    else
    {
        selectBranchUnsafe(newBranch, newIndex);
        var plys:Array<RawPly> = newBranch.map(n -> n.ply);
        var notation:Array<String> = newBranch.map(n -> PlyFormatter.toNotation(n.ply, n.parent.positionAfter, indicateColors));
        eventHandler(BranchSelected(plys, notation, clickedPlyNode.depth));
    }
}
```

**Helper `buildBranchThrough(n:PlyTreePlyNode):Array<PlyTreePlyNode>`** — the
extend-to-leaf + walk-to-root pattern described in the **Selected-branch representation** section.

### 1d. `PlyTreePlainText.hx` (replaces `VariantPlainText`)

**Extends:** `HBox implements IPlyTreeView`

#### State changes

```haxe
private var plyTree:PlyTree;
private var nodeById:Map<Int, NodeInfo> = [];      // keyed by PlyTreePlyNode.id
private var plyNodeRefs:Map<Int, PlyTreePlyNode> = [];

private var selectedBranch:Array<PlyTreePlyNode> = [];
private var selectedIndex:Int = -1;
private var selectedPlyNode:Null<PlyNodeLink> = null;
```

`NodeInfo` gains a `plyNode:PlyTreePlyNode` field.

#### `PlyNodeLink` (private class, replaces `PlyNode`)

Stores a reference to its `PlyTreePlyNode`. Style (italic) is computed live:
```haxe
private function isOnMainLine(node:PlyTreePlyNode):Bool
{
    var cur:PlyTreeNodeBase = node;
    while (cur.parent != null)
    {
        if (cur.parent.children[0] != cur)
            return false;
        cur = cur.parent;
    }
    return true;
}
```
Called in `set_plyNode` to update italic style. No `PlyTreePath` involved.

Label and turn number:
```haxe
var label:String = '${node.depth}. ${PlyFormatter.toNotation(node.ply, node.parent.positionAfter, false)}';
```

On ctrl+click: call `removeUiNode(this.plyNode)`.
On click: call `onSelectNode(this.plyNode)`.

#### `addChildToSelectedNode(ply, selectChild)`

1. `parentPlyNode = getSelectedNode() ?? cast plyTree.root`
2. `var nodeNum:Int = parentPlyNode.children.length` (before addChild)
3. `var newNode:PlyTreePlyNode = parentPlyNode.addChild(ply)`
4. Create `PlyNodeLink`, wrap in `NodeInfo`; store in `nodeById` and `plyNodeRefs`
5. Insertion position logic (determining where to splice into the flat item list) is
   unchanged in structure from the old `VariantPlainText.addChildNode`. Sibling lookups
   replace `nodeByCode.get(siblingCode)` with `nodeById.get(sibling.id)` where `sibling` is
   retrieved from `parentPlyNode.children[nodeNum - 1]` etc.
6. Sibling references are obtained directly from `parentPlyNode.children` and `plyNodeRefs`

#### `removeUiNode(node:PlyTreePlyNode)` (internal)

Structure is identical to old `VariantPlainText.removeNodeByPath` for the visual splice logic.
Key changes:
- `nodeInfo = nodeById.get(node.id)` replaces `nodeByCode.get(path.code())`
- `totalSiblings = node.parent.children.length` (before removal)
- After `parent.removeChild(node)`: right-sibling nodes (formerly at higher child indices) have
  their effective main-line status change. Update each `PlyNodeLink` style by calling
  `link.plyNode = link.plyNode` (retrigger `set_plyNode`) — the `isOnMainLine` check uses the
  live `parent.children` array which is already updated after `removeChild`.
- **No map key remapping**: `nodeById` is keyed by stable `id`. Only `PlyNodeLink.plyNode`
  re-assignment (for style refresh) is needed; that reference is unchanged.
- Remove `node` and all its descendants from `nodeById` + `plyNodeRefs`

#### `onSelectNode(node:PlyTreePlyNode)`

Same structure as `PlyTreeGraph.onSelect`: detect on-branch vs off-branch, build/reuse
`selectedBranch`, fire `BranchSelected` or `ScrollBtnPressed`.

#### `getSelectedNode()`

`return selectedIndex >= 0 ? selectedBranch[selectedIndex] : null;`

#### `handlePlyScrolling` — same arithmetic as other views

#### `addRec(parentPlyNode:PlyTreeNodeBase, node:PlyTreePlyNode)` (initialization only)

```haxe
private function addRec(parentPlyNode:PlyTreeNodeBase, node:PlyTreePlyNode)
{
    addChildToSelectedNodeImpl(parentPlyNode, node);  // internal add without selection side-effects
    for (child in node.children)
        addRec(node, child);
}
```

Keep pack/unpack bracketing logic from old `VariantPlainText` — it's correct, just replace
path-code keys with id-based lookups throughout.

#### `clear(?newStartingPosition:Position)`

```haxe
removeAllComponents();
plyTree = new PlyTree(newStartingPosition ?? plyTree.root.positionAfter);
if (plyTree.root.positionAfter.turnColor == Black)
    addComponent(label("..."));
nodeById = [];
plyNodeRefs = [];
selectedBranch = [];
selectedIndex = -1;
selectedPlyNode = null;
items = [];
```

#### Constructor `new(plyTree:PlyTree, ?selectedNode:Null<PlyTreePlyNode>)`

- `this.plyTree = plyTree`
- If `plyTree.root.positionAfter.turnColor == Black`: add "…" label
- `for (child in plyTree.root.children) addRec(plyTree.root, child)`
- Initial selection: build branch through `selectedNode` (or main-line leaf if null)

---

## Phase 2: Wiring files

### 2a. `gfx/analysis/ControlTabs.hx`

- Remove `import struct.Variant`; add `import lib.intellectorboard.plytree.PlyTree`
- `private var variantView:IVariantView` → `private var plyTreeView:IPlyTreeView`
- `redrawBranchingTab(variant:Variant)` → `redrawBranchingTab(plyTree:PlyTree)`:
  - `var selectedNode:Null<PlyTreePlyNode> = plyTreeView.getSelectedNode()`
  - Recreate tab, pass `selectedNode` to new view constructor
- `drawBranchingTab(initialVariant:Variant, ?selectedNode:VariantPath)` →
  `drawBranchingTab(initialPlyTree:PlyTree, ?selectedNode:Null<PlyTreePlyNode>)`
- Instantiations:
  - `new VariantTree(...)` → `new PlyTreeGraph(initialPlyTree, selectedNode)`
  - `new VariantOutline(...)` → `new PlyTreeOutline(initialPlyTree, selectedNode)`
  - `new VariantPlainText(...)` → `new PlyTreePlainText(initialPlyTree, selectedNode)`
- Constructor: `new(initialPlyTree:PlyTree, eventHandler:PeripheralEvent->Void)`
- Also import `lib.intellectorboard.plytree.PlyTreePlyNode`

### 2b. `gfx/common/ComponentConstructor.hx`

```haxe
package gfx.common;

import lib.intellectorboard.plytree.PlyTree;
import gfx.game.LiveGameConstructor;

enum ComponentConstructor
{
    Live(constr:LiveGameConstructor);
    Analysis(initialPlyTree:PlyTree);
}
```

### 2c. `gfx/ScreenType.hx`

- Remove `import struct.Variant.VariantPath` (unused in file body)
- `Analysis(initialVariantStr:Null<String>, ...)` → `Analysis(initialPlyTree:Null<PlyTree>, ...)`
- Add `import lib.intellectorboard.plytree.PlyTree`

### 2d. `gameboard/GameBoard.hx`

In the `Analysis` switch case:
```haxe
case Analysis(initialPlyTree):
    this._startingSituation = initialPlyTree.root.positionAfter.copy();
    this._currentSituation = _startingSituation.copy();
    super(_startingSituation, Free, Free, _startingSituation.turnColor, Preferences.marking.get());
    for (plyNode in initialPlyTree.getMainLineBranch())
        makeMove(plyNode.ply);
```

- Remove `import struct.Variant`; add `import lib.intellectorboard.plytree.PlyTree`

*(Note: `_startingSituation` field type may already be deprecated `Situation`; leave any
resulting type error as pre-existing.)*

### 2e. `gfx/screens/Analysis.hx`

- `private var variant:Variant` → `private var plyTree:PlyTree`
- Constructor signature: `new(?initialPlyTree:PlyTree, ?selectedMainlineMove:Int)`
  - `plyTree = initialPlyTree ?? new PlyTree(Position.defaultStarting())`
  - Remove `Variant.deserialize` / `new Variant(...)` calls
- `new GameBoard(Analysis(plyTree))`
- `new ControlTabs(plyTree, handlePeripheralEvent)`
- `controlTabs.redrawBranchingTab(plyTree)` (in `handleGlobalEvent`)
- `shareDialog.initInAnalysis(board.shownSituation, board.orientationColor, plyTree, ...)`
- Remove `import struct.Variant`; add `import lib.intellectorboard.plytree.PlyTree`
  and `import lib.intellectorboard.position.Position`

### 2f. `gfx/screens/LiveGame.hx`

Replace `new Variant(board.startingSituation)` block with:
```haxe
private function buildPlyTree():PlyTree
{
    var tree:PlyTree = new PlyTree(board.startingSituation);
    var cur:PlyTreeNodeBase = tree.root;
    for (ply in board.plyHistory.getPlySequence())
    {
        cur = cur.addChild(ply);
    }
    return tree;
}
```

Call site: `SceneManager.toScreen(Analysis(buildPlyTree(), board.plyHistory.pointer, null))`.

- Remove `import struct.Variant`; add `import lib.intellectorboard.plytree.PlyTree`

*(If `plyHistory.getPlySequence()` returns something other than `Array<RawPly>`, adapt
accordingly — this is a pre-existing API to check at implementation time.)*

### 2g. `gfx/common/ShareDialog.hx`

- `initInAnalysis(..., variant:Variant, ...)` → `initInAnalysis(..., plyTree:PlyTree, ...)`
- `Create(variant)` → `Create(plyTree)`, `CreateOrOverwrite(variant, ...)` → `CreateOrOverwrite(plyTree, ...)`
- Remove `import struct.Variant`; add `import lib.intellectorboard.plytree.PlyTree`

### 2h. `gfx/popups/StudyParamsDialog.hx`

- Enum:
  - `Create(variant:Variant)` → `Create(plyTree:PlyTree)`
  - `CreateOrOverwrite(newVariant:Variant, ...)` → `CreateOrOverwrite(newPlyTree:PlyTree, ...)`
- `generateKeySIP(plyTree:PlyTree):String`:
  ```haxe
  private function generateKeySIP(plyTree:PlyTree):String
  {
      if (!plyTree.root.positionAfter.isDefaultStarting())
          return Sip.fromPosition(plyTree.root.positionAfter);

      var leaf:PlyTreeNodeBase = plyTree.root;
      while (leaf.children.length > 0)
          leaf = leaf.children[0];
      return Sip.fromPosition(leaf.positionAfter);
  }
  ```
- `serializedVariant` field: remove. Replace `info.variantStr = serializedVariant` with
  `// TODO: wire StudyPlyTreeMapper.toDto(plyTree) into the DTO once Requests are updated`
  (leave the resulting compile error visible so it's not silently broken)
- Remove `import struct.Variant`; add `import lib.intellectorboard.plytree.PlyTree`,
  `import lib.intellectorboard.plytree.PlyTreeNodeBase`, `import lib.intellectorboard.Sip`

---

## Verification

```bash
grep -r "struct\.Variant" src/        # must return nothing
grep -r "VariantPath" src/            # must return nothing
grep -r "IVariantView" src/           # must return nothing
grep -r "VariantOutline\|VariantTree\|VariantPlainText" src/   # must return nothing
```

Build: `haxe html5.hxml` — errors must not reference any deleted symbol.
Manual smoke-test: Analysis screen loads; all three branching tab types render; nodes can be
added (by playing moves on the board) and removed (ctrl+click); switching tab types preserves
selection; navigating from LiveGame → Analysis arrives with the main line selected.


