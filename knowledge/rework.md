# Plan: Migrate consumer files from struct.Variant to lib.intellectorboard.plytree

## Context

`struct/Variant.hx` has been deleted. The replacement module `lib.intellectorboard.plytree`
already exists locally. All consumer files that imported `struct.Variant` are now broken.

This plan covers:
1. **Additions** to the existing module that the consumers need (methods not yet present)
2. **New analysis view files** replacing the four broken Variant* files
3. **Wiring updates** in ControlTabs, Analysis, LiveGame, ScreenType, ComponentConstructor,
   ShareDialog, StudyParamsDialog, and GameBoard

### Other important replacements

- `net.shared.board.Position` -> `lib.intellectorboard.position.Position`
- a variety of classes inside net.shared -> classes inside either `lib.intellectorboard` or `client.datatypes`
- `Networker` and `Requests` are deprecated, calls to them are broken, but should be left as they are

### Design principle for renderers

The old code indexed nodes and arrows by a path-string key (e.g. `"0:1:2"`). The new code
**does not use paths for internal state tracking or map keys in renderers**. Renderers
maintain a `Map<Int, Node>` / `Map<Int, Arrow>` / `Map<Int, PlyTreePlyNode>` keyed by
`PlyTreeNodeBase.id`. Path-based navigation is restricted to the interface boundary
(`addChildNode(parentPath)`, `removeNodeByPath(path)`, `getSelectedNode()`) where paths are
immediately converted to node references via `PlyTreeNavigator.findNode`.

---

## Dependency diagram

```
Phase 0: Additions to lib.intellectorboard.plytree
  PlyTree.getMainLineBranch()
  PlyTreeNodeBase.subtreeWidth()
  PlyTreePath: missing helpers (startsWith, subpath, etc.)
       |
Phase 1: New analysis view files
  IPlyTreeView  (replaces IVariantView)
  PlyTreeOutline  (replaces VariantOutline)
  PlyTreeGraph    (replaces VariantTree)
  PlyTreePlainText  (replaces VariantPlainText)
       |
Phase 2: Wiring files
  ControlTabs, ComponentConstructor, ScreenType
  GameBoard, Analysis, LiveGame
  ShareDialog, StudyParamsDialog
```

---

## Key API mapping

| Old (`struct.Variant`) | New (`lib.intellectorboard.plytree`) |
|---|---|
| `new Variant(situation)` | `new PlyTree(position:Position)` |
| `variant.startingPosition` | `plyTree.root.positionAfter` |
| `variant.getMainLineBranch()` | `plyTree.getMainLineBranch()` → `Array<PlyTreePlyNode>` |
| `variant.getAllNodes()` | `plyTree.collectPlyNodes()` → `Array<PlyTreePlyNode>` |
| `variant.getPositionByPath(path)` | `PlyTreeNavigator.findNode(tree,path).positionAfter` |
| `variant.childCount(path)` | `node.children.length` (via stored node ref or `findNode`) |
| `variant.addChildToNode(ply,path)` | `node.addChild(ply)` → returns `PlyTreePlyNode` |
| `variant.removeNode(path)` | `node.parent.removeChild(node)` |
| `variant.extendPathLeftmost(path)` | `PlyTreeNavigator.extendLeftmost(node)` |
| `variant.getBranchByPath(path)` | walk from node to root collecting `.ply` fields |
| `variant.getBranchNotationByPath(path)` | same walk but produce notation strings |
| `variant.getFamilyPaths(path)` | **eliminated** — use id-based maps |
| `variant.getRightSiblingsPaths(path, _)` | `node.collectNodesToTheRight()` (see Phase 0) |
| `variant.getRightmostSiblingPath(path)` | `node.parent.children[node.parent.children.length-1]` |
| `variant.pathExists(path)` | `PlyTreeNavigator.findNode(tree,path) != null` |
| `variant.getLastMainLineDescendantPath(p)` | `PlyTreeNavigator.extendLeftmost(node)` |
| `variant.clear(newPosition)` | `plyTree = new PlyTree(newPosition ?? plyTree.root.positionAfter)` |
| `variant.serialize()` | *(removed — DTO mappers handle that)* |
| `Variant.deserialize(str)` | *(removed — DTO mappers handle that)* |
| `VariantPath.fromCode("0:1:2")` | `PlyTreePath.fromString("0:1:2")`|
| `path.code()` | `path.toString()` |
| `path.child(n)` | `path.getChild(n)` |
| `path.parent()` | `path.getParent()` |
| `path.length` | `path.depth` |
| `path.subpath(n)` | `path.subpath(n)` |
| `path.isRoot()` | `path.isRoot()` |
| `path.isMainLine()` | `path.isMainLine()` |
| `path.lastNodeNum()` | `path.lastChildIndex()` |
| `path.equals(other)` | `path.equals(other)` |
| `selectedBranch.contains(path)` | `selectedBranch.startsWith(path)` |
| `path.copy()` | `path.copy()` |
| `path.asArray()[depth-1]--` | **eliminated** — stable ids, no remap |
| `ply.toNotation(situation, b)` | check actual API on `RawPly` / `Notation` in existing module |

---

## Phase 0: Additions to lib.intellectorboard.plytree

These methods are needed by the consumer files. Add them to the existing module if absent.

### `PlyTree.getMainLineBranch():Array<PlyTreePlyNode>`

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

### `PlyTreeNodeBase.collectNodesToTheRight():Array<PlyTreePlyNode>`

Returns all nodes whose horizontal layout position shifts when this node's HCI column count
changes — i.e., right siblings at every ancestor level and all of their descendants.

```haxe
public function collectNodesToTheRight():Array<PlyTreePlyNode>
{
    var result:Array<PlyTreePlyNode> = [];
    var cur:PlyTreeNodeBase = this;
    while (cur.parent != null)
    {
        var p = cur.parent;
        var idx = p.children.indexOf(cast cur);
        for (i in (idx + 1)...p.children.length)
            collectSubtreeInto(p.children[i], result);
        cur = p;
    }
    return result;
}

private static function collectSubtreeInto(node:PlyTreePlyNode, out:Array<PlyTreePlyNode>)
{
    out.push(node);
    for (child in node.children) collectSubtreeInto(child, out);
}
```

### `PlyTreeNodeBase.subtreeWidth():Int`

The number of distinct HCI columns occupied by this node and all its descendants.
Needed to compute the shift amount when removing a subtree.

```haxe
public function subtreeWidth():Int
{
    if (children.length == 0) return 1;
    var total = 0;
    for (c in children) total += c.subtreeWidth();
    return total;
}
```

### `PlyTreePath` helpers (verify against existing implementation)

Confirm these methods exist; add if missing:
- `startsWith(prefix:PlyTreePath):Bool` — true when `prefix` is a prefix of this path
- `subpath(n:Int):PlyTreePath` — first n steps
- `isRoot():Bool`, `isMainLine():Bool`, `lastChildIndex():Int`, `equals(other):Bool`, `copy():PlyTreePath`
- `getChild(n:Int):PlyTreePath`, `getParent():PlyTreePath`

---

## Phase 1: New analysis view files

Delete the four broken files and create replacements. Old names → new names:
- `src/gfx/analysis/IVariantView.hx` → `src/gfx/analysis/IPlyTreeView.hx`
- `src/gfx/analysis/VariantOutline.hx` → `src/gfx/analysis/PlyTreeOutline.hx`
- `src/gfx/analysis/VariantTree.hx` → `src/gfx/analysis/PlyTreeGraph.hx`
- `src/gfx/analysis/VariantPlainText.hx` → `src/gfx/analysis/PlyTreePlainText.hx`

### 1a. `IPlyTreeView.hx`

Identical structure to `IVariantView` but:
- `VariantPath` → `PlyTreePath`
- Add `import lib.intellectorboard.position.Position`; use `Position` everywhere `Situation` was used
- Interface renamed to `IPlyTreeView`

```haxe
interface IPlyTreeView
{
    public function init(eventHandler:PeripheralEvent->Void):Void;
    public function clear(?newStartingPosition:Position):Void;
    public function addChildNode(parentPath:PlyTreePath, ply:RawPly, selectChild:Bool):Void;
    public function addChildToSelectedNode(ply:RawPly, selectChild:Bool):Void;
    public function getSelectedNode():PlyTreePath;
    public function removeNodeByPath(path:PlyTreePath):Void;
    public function handlePlyScrolling(type:PlyScrollType):Void;
}
```

### 1b. `PlyTreeOutline.hx` (replaces VariantOutline)

**Selected-state tracking:** Replace `selectedBranch:VariantPath + selectedMove:Int` with:
```haxe
private var selectedLeaf:Null<PlyTreePlyNode> = null;
private var selectedDepth:Int = 0;
```

`getSelectedNode()`:
```haxe
public function getSelectedNode():PlyTreePath
{
    return selectedLeaf == null ? new PlyTreePath() : selectedLeaf.getPath().subpath(selectedDepth);
}
```

**HaxeUI node codes:** Keep using `path.toString()` as the HaxeUI `code` data field (the
TreeViewNode needs a string to find nodes by path). The difference is that internally the
Haxe-side state uses node references, not path strings.

**`addChildToSpecificNode(parentNode, ply, select)`:**
- `parentPath = PlyTreePath.fromString(parentNode.data.code)`
- `var parentPlyNode = PlyTreeNavigator.findNode(plyTree, parentPath)`
- `var ctx = parentPlyNode.positionAfter`   *(or root.positionAfter if parentPath.isRoot())*
- `var childNum = parentPlyNode.children.length`  *(before addChild)*
- `var newNode = parentPlyNode.addChild(ply)` → returns `PlyTreePlyNode` with computed positionAfter
- `var childPath = parentPath.getChild(childNum)`
- ply label: `Notation.plyToNotation(ply, ctx, false)` *(check actual notation API)*
- turn number: `newNode.depth` *(adjusted for starting color)*
- HaxeUI code on the new child node: `childPath.toString()`
- `nodeId` data: `'$childNum'`

**`addRec(parentTreeNode, node:PlyTreePlyNode)`:** iterate `node.children` (Array, not
keyValueIterator).

**`removeSpecificNode(treeNode)`:**
- `nodePath = PlyTreePath.fromString(treeNode.data.code)`
- `node = PlyTreeNavigator.findNode(plyTree, nodePath)` as `PlyTreePlyNode`
- Compute `newSelectedBranch` as before (using `extendLeftmost`)
- `treeNode.parentNode.removeNode(treeNode)`
- For sibling remap (updating HaxeUI `code` + `nodeId` fields): call
  `node.collectNodesToTheRight()` **before** calling `parent.removeChild(node)`. For each
  returned sibling/descendant, find its current TreeViewNode by `rootNode.findNodeByPath(n.getPath().toString())`, update `data.code` to `n.getPath().subpath(n.depth - 1).getChild(n.getPath().lastChildIndex() - 1).toString()` — actually: since the index of each right-sibling decreases by 1 at the removed node's depth, compute the new path as the original path with index at depth `(nodePath.depth - 1)` decremented by 1.
- `parent.removeChild(node)`
- Update `selectedLeaf` / `selectedDepth` if branch changed

**`selectBranchUnsafe(leaf:Null<PlyTreePlyNode>, depth:Int)`:** store leaf+depth, call
`refreshSelection()`.

**`refreshSelection()`:**
```haxe
if (selectedDepth == 0)
    rootNode.selected = true;
else
{
    var targetPath = selectedLeaf.getPath().subpath(selectedDepth);
    rootNode.findNodeByPath(targetPath.asArray().join('/')).selected = true;
}
```

**`handlePlyScrolling`:** Convert `Home/Prev/Next/End/Precise` to new depth arithmetic using
`selectedLeaf.depth` as the max.

**`clear(?newStartingPosition)`:**
```haxe
rootNode.clearNodes();
plyTree = new PlyTree(newStartingPosition ?? plyTree.root.positionAfter);
selectedLeaf = null;
selectedDepth = 0;
```

**Constructor:** `new(plyTree:PlyTree, ?selectedNodePath:PlyTreePath)`
- Holds `plyTree` reference directly (no clone)
- Calls `addRec` over `plyTree.root.children`
- Initial selection: if `selectedNodePath != null`, `selectBranchUnsafe` from the
  `extendLeftmost` of that path; else from `extendLeftmost(plyTree.root)`

### 1c. `PlyTreeGraph.hx` (replaces VariantTree)

#### Interaction model

- **Select node N:** `selectedLeaf = extendLeftmost(N)`, `selectedDepth = N.depth`. Fires `BranchSelected`.
- **Scroll prev/next/home/end:** change `selectedDepth` within `[0, selectedLeaf.depth]`.
- **Add child to selected:** extends `selectedLeaf` and increments `selectedDepth`.
- **Remove node N:** if selected node is N or a descendant, select `N.parent` (depth = `N.depth - 1`) with `extendLeftmost(N.parent)` as new leaf.

#### Grid layout

- **VCI** (vertical cell index) = `node.depth`
- **HCI** (horizontal cell index) is a derived value, never stored:
  - Root: HCI = 1
  - First child: same HCI as parent
  - Nth sibling (N > 0): HCI = 1 + max HCI in the previous sibling's entire subtree
- **Column width** = max label width across all nodes sharing that HCI column
- **Node X coordinate** = sum of widths of columns 1 through HCI−1 + spacing
- **Node Y coordinate** = VCI × row height constant

HCI is computed via the same `buildOptimalDisplacement()` algorithm as the old
`VariantTree` (using a `rowLengths` map), translated to work with node ids instead of path codes.

#### Maps

```haxe
private var nodes:Map<Int, Node> = [];        // keyed by PlyTreeNodeBase.id
private var arrows:Map<Int, Arrow> = [];      // keyed by PlyTreePlyNode.id (edge into node)
private var nodeRefs:Map<Int, PlyTreePlyNode> = [];  // id → tree node reference
private var columnWidths:Map<Int, Float> = [];
```

Root goes into `nodes` under `plyTree.root.id`; no arrow entry for root.

#### `drawFromScratch(plyTree, ?selectedNodePath)`

```haxe
var rootLabel = new Node(scale, plyTree.root.id, startingPositionText, false, onNodeSelectRequest, v->{});
nodes.set(plyTree.root.id, rootLabel);
addComponent(rootLabel);

for (plyNode in plyTree.collectPlyNodes())
{
    var label = Notation.plyToNotation(plyNode.ply, plyNode.parent.positionAfter, indicateColors);
    var node = new Node(scale, plyNode.id, label, false, onNodeSelectRequest, onNodeRemoveRequest);
    var arrow = new Arrow(scale);
    nodes.set(plyNode.id, node);
    arrows.set(plyNode.id, arrow);
    nodeRefs.set(plyNode.id, plyNode);
    addComponent(node); addComponent(arrow); arrow.moveComponentToBack();
}
```

Then select branch via `selectedNodePath` (or main line if null).

#### `buildOptimalDisplacement():DisplacementInfo`

Same algorithm as old `VariantTree.buildOptimalDisplacement()`, with:
- `info.cellularMapping` keyed by `Int` (node id) instead of `String` (path code)
- `recursive(node:PlyTreePlyNode)` instead of `recursive(path:VariantPath)`
- `node.depth` instead of `path.length`
- `node.children.length > 0` instead of `variantRef.pathExists(descendantPath)`
- `node.children.length` instead of `variantRef.childCount(path)`

#### `refreshLayout()`

Uses `buildOptimalDisplacement()`. Column widths from `nodes.get(id).textSize.width`.
For arrows: tail = `nodes.get(plyNode.parent.id).outputPos()`, head = `nodes.get(plyNode.id).inputPos()`.

#### Incremental update for `addChildNode(parentPath, ply, select)`

1. `parent = PlyTreeNavigator.findNode(plyTree, parentPath)`
2. `var wasLeaf = parent.children.length == 0`
3. `var newNode = parent.addChild(ply)` → `PlyTreePlyNode`
4. Create `Node` + `Arrow`, key by `newNode.id`; store in `nodeRefs`; add as components
5. Compute `newNode`'s HCI (via the buildOptimalDisplacement algorithm, or by traversal)
6. **If `!wasLeaf`** (parent was not a leaf): shift right-nodes by 1 column:
   ```haxe
   var toShift = newNode.collectNodesToTheRight();
   for (n in toShift)
   {
       var nNode = nodes.get(n.id);
       nNode.left += columnWidths.get(newNodeHCI) + NORMAL_BLOCK_INTERVAL_X * scale;
       repositionArrow(n.id);
   }
   ```
7. Place `newNode`'s label at `(columnX(newNodeHCI), rowY(newNode.depth))`; draw arrow
8. If `select`: `selectBranchUnsafe(newNode, newNode.depth)`

> Optimization: when `wasLeaf`, step 6 is skipped entirely — first child shares parent's HCI column, nothing shifts.

#### Incremental update for `removeNodeByPath(path)`

1. `node = PlyTreeNavigator.findNode(plyTree, path)` as `PlyTreePlyNode`
2. `var isOnlyChild = node.parent.children.length == 1`
3. Handle selected-branch reselection (same logic as old `VariantTree.removeNodeByPath`)
4. Collect family: iterate `node.children` recursively; remove each from `nodes`, `arrows`, `nodeRefs` maps and `removeComponent` each UI element
5. **If `!isOnlyChild`**: shift right-nodes left:
   ```haxe
   var toShift = node.collectNodesToTheRight();
   var shiftAmount = node.subtreeWidth();  // number of HCI columns to reclaim
   var shiftPx = ... ;  // sum of column widths for the reclaimed columns
   for (n in toShift)
   {
       nodes.get(n.id).left -= shiftPx;
       repositionArrow(n.id);
   }
   ```
6. `node.parent.removeChild(node)`
7. Also remove `node` itself from maps and `removeComponent`

> Optimization: when `isOnlyChild`, step 5 is skipped — the removed node shared parent's column, nothing shifts.

> **`shiftPx` computation:** sum the widths of the HCI columns that `node.subtreeWidth()` occupied. These are the columns from `node`'s HCI through `node`'s HCI + `subtreeWidth() - 1`. Use `columnWidths` map computed by the last `refreshLayout`.

> **Alternative:** fall back to `refreshLayout()` when computing `shiftPx` is complex (e.g., when `subtreeWidth() > 1`). This avoids micro-managing column arithmetic at the cost of a full redraw.

#### `deselectAll()`

Walk from `selectedLeaf` up to root via `parent` pointers; deselect each `nodes.get(n.id)` and unhighlight each `arrows.get(n.id)`.

#### `selectBranchUnsafe(leaf, depth)`

Walk leaf → root collecting chain, reverse, then select/highlight from root to `depth`.

### 1d. `PlyTreePlainText.hx` (replaces VariantPlainText)

**Key structural changes:**
```haxe
private var nodeById:Map<Int, NodeInfo> = [];       // keyed by PlyTreePlyNode.id
private var nodeRefById:Map<Int, PlyTreePlyNode> = [];  // id → node reference
// NodeInfo gains: node:PlyNode field (already has index, rbraceIndex)
```

**Selected-state tracking:** `selectedLeaf:Null<PlyTreePlyNode>` + `selectedDepth:Int`.

`getSelectedNode()`: same as PlyTreeOutline.

**`PlyNode` (private class):**
- `path:PlyTreePath` (computed via `node.getPath()` initially, updated on removal)
- `set_path`: `v.isMainLine()` → italic style; `path = v.copy()`
- Constructor: label via `Notation.plyToNotation(ply, parentPos, false)`; turn number from `node.depth`

**`addChildNode(parentPath, ply, select)`:**
1. `parent = PlyTreeNavigator.findNode(plyTree, parentPath)`
2. `newNode = parent.addChild(ply)` → `PlyTreePlyNode`
3. Create `PlyNode`, wrap in `NodeInfo`
4. `nodeById.set(newNode.id, nodeInfo)`; `nodeRefById.set(newNode.id, newNode)`
5. Insertion position logic unchanged (using `nodeInfo.index`/`rbraceIndex`) — look up left
   sibling info via `nodeById.get(leftSiblingPlyNode.id)` (which you find via `parent.children`)

**`removeNodeByPath(path)`:**
1. `node = PlyTreeNavigator.findNode(plyTree, path)` as `PlyTreePlyNode`
2. All visual removal logic from the old file is preserved (same pack/unpack, splice logic)
3. **Map remap eliminated for id-based entries.** Instead of changing map keys:
   - Call `node.collectNodesToTheRight()` to get affected nodes **before** removal
   - `parent.removeChild(node)` — this shifts indices in `parent.children`
   - For each right-sibling node `rs` returned by step above, update its `PlyNode.path` field
     by calling `rs.getPath()` (now returns the correct post-removal path since `removeChild`
     already shifted indices)
   - Map keys (`nodeById` keyed by stable int id) need no remapping
4. Remove `node` and all its descendant entries from `nodeById` + `nodeRefById`
5. If `selectedBranch` was rooted at a right-sibling, re-derive via `rs.getPath()`

**`addRec(parentPath, childNum, node:PlyTreePlyNode)`:** use `node.children` (Array).

**`clear(?newPosition)`:** `removeAllComponents()` + `plyTree = new PlyTree(...)` + reset state.

---

## Phase 2: Wiring files

### 2a. `src/gfx/analysis/ControlTabs.hx`

- `import struct.Variant` → `import lib.intellectorboard.plytree.PlyTree` + `import lib.intellectorboard.plytree.path.PlyTreePath`
- `variantView:IVariantView` → `plyTreeView:IPlyTreeView`
- `redrawBranchingTab(variant:Variant)` → `redrawBranchingTab(plyTree:PlyTree)`
- `drawBranchingTab(initialVariant:Variant, ?selectedNode:VariantPath)` → `drawBranchingTab(initialPlyTree:PlyTree, ?selectedNode:PlyTreePath)`
- `new VariantTree(...)` → `new PlyTreeGraph(...)`
- `new VariantOutline(...)` → `new PlyTreeOutline(...)`
- `new VariantPlainText(...)` → `new PlyTreePlainText(...)`
- Constructor: `new(initialVariant:Variant, ...)` → `new(initialPlyTree:PlyTree, ...)`

### 2b. `src/gfx/common/ComponentConstructor.hx`

```haxe
import lib.intellectorboard.plytree.PlyTree;
// remove: import struct.Variant
enum ComponentConstructor {
    Live(constr:LiveGameConstructor);
    Analysis(initialPlyTree:PlyTree);
}
```

### 2c. `src/gfx/ScreenType.hx`

- Remove `import struct.Variant.VariantPath` (unused in file body)
- `Analysis(initialVariantStr:Null<String>, ...)` → `Analysis(initialPlyTree:Null<PlyTree>, ...)`
- Add `import lib.intellectorboard.plytree.PlyTree`

### 2d. `src/gameboard/GameBoard.hx`

In the `Analysis(initialPlyTree)` switch case:
```haxe
case Analysis(initialPlyTree):
    this._startingPosition = initialPlyTree.root.positionAfter.copy();
    this._currentPosition = _startingPosition.copy();
    super(_startingPosition, Free, Free, _startingPosition.turnColor, Preferences.marking.get());
    for (plyNode in initialPlyTree.getMainLineBranch())
        makeMove(plyNode.ply);
```

- Remove `import struct.Variant`, add `import lib.intellectorboard.plytree.PlyTree`

### 2e. `src/gfx/screens/Analysis.hx`

- `private var variant:Variant` → `private var plyTree:PlyTree`
- Constructor signature: `new(?initialPlyTree:PlyTree, ?selectedMainlineMove:Int)`
  - `plyTree = initialPlyTree ?? new PlyTree(Position.defaultStarting())`
  - Remove all `Variant.deserialize` / `new Variant(...)` calls
- `new GameBoard(Analysis(plyTree))`
- `new ControlTabs(plyTree, handlePeripheralEvent)`
- `view.init(... Analysis(plyTree))`
- `controlTabs.redrawBranchingTab(plyTree)` (in `handleGlobalEvent`)
- `shareDialog.initInAnalysis(board.shownPosition, board.orientationColor, plyTree, ...)`
- Remove `import struct.Variant`, add `import lib.intellectorboard.plytree.PlyTree`

### 2f. `src/gfx/screens/LiveGame.hx`

`getSerializedVariant():String` → `buildPlyTree():PlyTree`:
```haxe
private function buildPlyTree():PlyTree
{
    var tree:PlyTree = new PlyTree(board.startingPosition);
    var node:PlyTreeNodeBase = tree.root;
    for (plyNode in board.plyHistory.getPlySequence())
    {
        node = node.addChild(plyNode);  // if addChild accepts RawPly and computes position internally
        // OR: pass ply + computed context, check the actual addChild signature
    }
    return tree;
}
```

Call site: `SceneManager.toScreen(Analysis(buildPlyTree(), board.plyHistory.pointer, null))`.

> **Note:** `addChild`'s exact signature (whether it takes `RawPly` and auto-computes
> `positionAfter`, or requires both `RawPly` + `Position`) depends on the existing module.
> If `addChild(ply:RawPly)` computes the position internally from `this.positionAfter`, the above
> works as written. If it requires `addChild(ply, position)`, compute:
> `var ctx = node.positionAfter.copy(); ctx.performPly(plyNode.toMaterialized(ctx));`

Remove `import struct.Variant`, add `import lib.intellectorboard.plytree.PlyTree`.

### 2g. `src/gfx/common/ShareDialog.hx`

- `initInAnalysis(..., variant:Variant, ...)` → `initInAnalysis(..., plyTree:PlyTree, ...)`
- `Create(variant)` → `Create(plyTree)`, `CreateOrOverwrite(variant, ...)` → `CreateOrOverwrite(plyTree, ...)`
- Remove `import struct.Variant`, add `import lib.intellectorboard.plytree.PlyTree`

### 2h. `src/gfx/popups/StudyParamsDialog.hx`

- Enum mode: `Create(variant:Variant)` → `Create(plyTree:PlyTree)`, same for `CreateOrOverwrite`
- `generateKeySIP(plyTree:PlyTree):String`:
  ```haxe
  if (!plyTree.root.positionAfter.isDefaultStarting())
      return plyTree.root.positionAfter.serialize();
  var leaf = PlyTreeNavigator.extendLeftmost(plyTree.root);
  return PlyTreeNavigator.findNode(plyTree, leaf).positionAfter.serialize();
  ```
- `serializedVariant` field: populate from the DTO flow instead of `variant.serialize()`.
  Until the DTO mapper is wired, leave `info.variantStr` as an empty string or skip assigning it
  (mark with `// TODO: wire StudyPlyTreeMapper`)
- Remove `import struct.Variant`, add `import lib.intellectorboard.plytree.PlyTree`

---

## Verification

```bash
grep -r "struct\.Variant" src/     # must return nothing
grep -r "VariantPath" src/         # must return nothing
grep -r "IVariantView" src/        # must return nothing
grep -r "VariantOutline\|VariantTree\|VariantPlainText" src/  # must return nothing
```

Build: `haxe html5.hxml` — errors must not reference any of the above symbols.
Manual smoke-test: Analysis screen loads, all three branching tab types render, nodes can be
added and removed, switching tab types redraws correctly, navigating from LiveGame → Analysis
arrives with the main line selected.
