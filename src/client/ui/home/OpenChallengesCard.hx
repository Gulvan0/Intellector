package client.ui.home;

import client.datatypes.challenge.OpenChallenge;
import client.ui.common.LoadStatus;
import client.ui.common.challenges.PositionPreviewPopover;
import client.ui.home.OpenChallengeRow.OpenChallengeRowHandlers;
import haxe.ui.Toolkit;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.LocaleUtils;
import haxefolio.structure.ScrollArea;
import js.Browser;
import js.html.DOMRect;
import js.html.Event;
import js.html.Node;

using client.ui.ComponentExtension;

typedef OpenChallengesHandlers =
{
    onAccept:OpenChallenge->Void,
    onCancel:OpenChallenge->Void,
    /** Asks for the challenges after the first `offset` ones **/
    onLoadMore:(offset:Int)->Void
}

/**
    The public challenges, newest first, in a panel of fixed height whose list scrolls, asking for
    the next ones as it nears the bottom. A custom starting position is previewed in a popover: on
    a mouse layout it opens on hover and a click pins it, on a phone a tap opens it; a click
    elsewhere or scrolling the list closes it.
**/
class OpenChallengesCard extends VBox
{
    public static inline final TIME_CONTROL_COLUMN_WIDTH:Float = 84;
    public static inline final TYPE_COLUMN_WIDTH:Float = 96;
    public static inline final COLOR_COLUMN_WIDTH:Float = 120;
    public static inline final START_COLUMN_WIDTH:Float = 84;
    public static inline final ACTION_COLUMN_WIDTH:Float = 84;

    private static inline final WIDE_HEIGHT:Float = 400;
    private static inline final NARROW_HEIGHT:Float = 380;
    private static inline final LOAD_MORE_MARGIN_ROWS:Int = 2;
    private static inline final POPOVER_GAP:Float = 8;
    private static inline final POPOVER_EDGE_MARGIN:Float = 6;
    private static inline final NARROW_POPOVER_INSET:Float = 14;
    private static inline final POPOVER_Z_INDEX:String = "10";

    private final handlers:OpenChallengesHandlers;
    private final rowHandlers:OpenChallengeRowHandlers;

    private final titleLabel:Label;
    private final columnHeader:HBox;
    private final scrollArea:ScrollArea;
    private final list:VBox;
    private final loadStatus:LoadStatus;
    private final emptyLabel:Label;
    private final moreStatus:LoadStatus;

    private var challenges:Array<OpenChallenge> = [];
    private var rows:Array<OpenChallengeRow> = [];
    private var busyIds:Array<Int> = [];
    private var viewerRef:Null<String> = null;
    private var narrow:Bool = false;
    private var loaded:Bool = false;
    private var hasMore:Bool = false;
    private var loadingMore:Bool = false;

    private var hoveredRow:Null<OpenChallengeRow> = null;
    private var pinnedRow:Null<OpenChallengeRow> = null;
    private var previewRow:Null<OpenChallengeRow> = null;
    private var preview:Null<PositionPreviewPopover> = null;

    public function new(handlers:OpenChallengesHandlers)
    {
        super();
        this.handlers = handlers;
        rowHandlers = {
            onAction: onRowAction,
            onCustomPressed: onCustomPressed,
            onCustomHovered: onCustomHovered
        };
        percentWidth = 100;
        addClass(StyleClass.HOME_CARD);
        addClass(StyleClass.HOME_CHALLENGES_CARD);

        titleLabel = new Label();
        titleLabel.percentWidth = 100;
        titleLabel.text = LocaleUtils.localeBinding("intellector.home.challenges.title");
        titleLabel.addClass(StyleClass.HOME_CHALLENGES_TITLE);
        addComponent(titleLabel);

        columnHeader = new HBox();
        columnHeader.percentWidth = 100;
        columnHeader.addClass(StyleClass.HOME_CHALLENGES_COLUMNS);
        columnHeader.addComponent(createColumnLabel("player", null));
        columnHeader.addComponent(createColumnLabel("time_control", TIME_CONTROL_COLUMN_WIDTH));
        columnHeader.addComponent(createColumnLabel("type", TYPE_COLUMN_WIDTH));
        columnHeader.addComponent(createColumnLabel("color", COLOR_COLUMN_WIDTH));
        columnHeader.addComponent(createColumnLabel("start", START_COLUMN_WIDTH));
        var actionSpacer:Box = new Box();
        actionSpacer.width = ACTION_COLUMN_WIDTH;
        columnHeader.addComponent(actionSpacer);
        addComponent(columnHeader);

        var body:Box = new Box();
        body.percentWidth = 100;
        body.percentHeight = 100;
        addComponent(body);

        var listColumn:VBox = new VBox();
        listColumn.percentWidth = 100;
        listColumn.addClass(StyleClass.HOME_CHALLENGE_LIST_COLUMN);

        list = new VBox();
        list.percentWidth = 100;
        list.addClass(StyleClass.HOME_CHALLENGE_LIST);
        listColumn.addComponent(list);

        moreStatus = new LoadStatus();
        moreStatus.hidden = true;
        listColumn.addComponent(moreStatus);

        scrollArea = new ScrollArea(listColumn);
        scrollArea.percentHeight = 100;
        scrollArea.element.addEventListener("scroll", onListScrolled);
        body.addComponent(scrollArea);

        loadStatus = new LoadStatus();
        loadStatus.verticalAlign = "center";
        body.addComponent(loadStatus);

        emptyLabel = new Label();
        emptyLabel.text = LocaleUtils.localeBinding("intellector.home.challenges.empty");
        emptyLabel.addClass(StyleClass.GAME_RECORD_MUTED);
        emptyLabel.horizontalAlign = "center";
        emptyLabel.verticalAlign = "center";
        emptyLabel.hidden = true;
        body.addComponent(emptyLabel);

        applyNarrow();
        showLoading();
    }

    /** The current user, whose own challenges read Cancel instead of Accept **/
    public function setViewer(ref:String):Void
    {
        if (ref == viewerRef)
            return;
        viewerRef = ref;
        renderRows();
    }

    public function setNarrow(narrow:Bool):Void
    {
        if (narrow == this.narrow)
            return;
        this.narrow = narrow;
        applyNarrow();
        renderRows();
    }

    public function showLoading():Void
    {
        closePreview();
        loaded = false;
        scrollArea.hidden = true;
        emptyLabel.hidden = true;
        loadStatus.showLoading();
        loadStatus.hidden = false;
    }

    public function showFailure(timedOut:Bool, onRetry:Void->Void):Void
    {
        closePreview();
        loaded = false;
        scrollArea.hidden = true;
        emptyLabel.hidden = true;
        loadStatus.showFailure(timedOut, onRetry);
        loadStatus.hidden = false;
    }

    /** Replaces the list with its first challenges; `hasMore` when the server holds further ones **/
    public function setChallenges(challenges:Array<OpenChallenge>, hasMore:Bool):Void
    {
        this.challenges = dedupe(challenges);
        this.hasMore = hasMore;
        loadingMore = false;
        loaded = true;
        loadStatus.hidden = true;
        moreStatus.hidden = true;
        renderRows();
        scrollArea.element.scrollTop = 0;
    }

    /** The challenges after the ones listed **/
    public function appendChallenges(further:Array<OpenChallenge>, hasMore:Bool):Void
    {
        var listedIds:Array<Int> = [for (challenge in challenges) challenge.id];
        var fresh:Array<OpenChallenge> = dedupe(further.filter(challenge -> !listedIds.contains(challenge.id)));
        this.hasMore = hasMore;
        loadingMore = false;
        moreStatus.hidden = true;
        for (challenge in fresh)
        {
            challenges.push(challenge);
            var row:OpenChallengeRow = createRow(challenge);
            rows.push(row);
            list.addComponent(row);
        }
    }

    public function showMoreFailure(timedOut:Bool):Void
    {
        loadingMore = false;
        moreStatus.showFailure(timedOut, requestMore);
        moreStatus.hidden = false;
    }

    /** A new challenge, on top; the rows in view stay where they are **/
    public function addChallenge(challenge:OpenChallenge):Void
    {
        if (!loaded || Lambda.exists(challenges, listed -> listed.id == challenge.id))
            return;

        challenges.unshift(challenge);
        var row:OpenChallengeRow = createRow(challenge);
        rows.unshift(row);
        list.addComponentAt(row, 0);
        if (scrollArea.element.scrollTop > 0)
            scrollArea.element.scrollTop += Math.round(rowHeight() * Toolkit.scaleY);
        refreshEmpty();
    }

    public function removeChallenge(id:Int):Void
    {
        var index:Int = indexOf(id);
        if (index < 0)
            return;

        var row:OpenChallengeRow = rows[index];
        if (row == previewRow || row == pinnedRow || row == hoveredRow)
            closePreview();
        challenges.splice(index, 1);
        rows.splice(index, 1);
        busyIds.remove(id);
        list.removeComponent(row);
        refreshEmpty();
    }

    /** Disables challenge `id`'s Accept or Cancel while its request is out **/
    public function setBusy(id:Int, busy:Bool):Void
    {
        busyIds.remove(id);
        if (busy)
            busyIds.push(id);
        var index:Int = indexOf(id);
        if (index >= 0)
            rows[index].setBusy(busy);
    }

    public function dispose():Void
    {
        closePreview();
        scrollArea.element.removeEventListener("scroll", onListScrolled);
    }

    private function applyNarrow():Void
    {
        height = narrow ? NARROW_HEIGHT : WIDE_HEIGHT;
        this.setClass(StyleClass.HOME_NARROW, narrow);
        titleLabel.setClass(StyleClass.HOME_NARROW, narrow);
        columnHeader.hidden = narrow;
    }

    private function createColumnLabel(key:String, width:Null<Float>):Label
    {
        var label:Label = new Label();
        label.text = LocaleUtils.localeBinding('intellector.home.challenges.column.$key');
        label.addClass(StyleClass.HOME_CHALLENGES_COLUMN_LABEL);
        label.verticalAlign = "center";
        if (width != null)
            label.width = width;
        else
            label.percentWidth = 100;
        return label;
    }

    private function renderRows():Void
    {
        closePreview();
        list.removeAllComponents();
        rows = [for (challenge in challenges) createRow(challenge)];
        for (row in rows)
            list.addComponent(row);
        refreshEmpty();
    }

    private function createRow(challenge:OpenChallenge):OpenChallengeRow
    {
        var row:OpenChallengeRow = new OpenChallengeRow(challenge, challenge.callerRef == viewerRef, narrow, rowHandlers);
        row.setBusy(busyIds.contains(challenge.id));
        return row;
    }

    private function refreshEmpty():Void
    {
        if (!loaded)
            return;
        scrollArea.hidden = challenges.length == 0;
        emptyLabel.hidden = challenges.length > 0;
    }

    private function rowHeight():Float
    {
        return narrow ? OpenChallengeRow.NARROW_HEIGHT : OpenChallengeRow.WIDE_HEIGHT;
    }

    private function indexOf(id:Int):Int
    {
        for (i in 0...challenges.length)
            if (challenges[i].id == id)
                return i;
        return -1;
    }

    private static function dedupe(challenges:Array<OpenChallenge>):Array<OpenChallenge>
    {
        var seen:Array<Int> = [];
        var result:Array<OpenChallenge> = [];
        for (challenge in challenges)
            if (!seen.contains(challenge.id))
            {
                seen.push(challenge.id);
                result.push(challenge);
            }
        return result;
    }

    private function onRowAction(challenge:OpenChallenge):Void
    {
        if (busyIds.contains(challenge.id))
            return;
        if (challenge.callerRef == viewerRef)
            handlers.onCancel(challenge);
        else
            handlers.onAccept(challenge);
    }

    private function onListScrolled(_:Event):Void
    {
        if (hoveredRow != null || pinnedRow != null)
        {
            hoveredRow = null;
            pinnedRow = null;
            renderPreview();
        }

        var scroller:js.html.Element = scrollArea.element;
        var remaining:Float = (scroller.scrollHeight - scroller.scrollTop - scroller.clientHeight) / Toolkit.scaleY;
        if (remaining <= LOAD_MORE_MARGIN_ROWS * rowHeight())
            requestMore();
    }

    private function requestMore():Void
    {
        if (!loaded || !hasMore || loadingMore)
            return;
        loadingMore = true;
        moreStatus.showLoading();
        moreStatus.hidden = false;
        handlers.onLoadMore(challenges.length);
    }

    private function onCustomPressed(row:OpenChallengeRow):Void
    {
        pinnedRow = pinnedRow == row ? null : row;
        hoveredRow = null;
        renderPreview();
    }

    private function onCustomHovered(row:OpenChallengeRow, entered:Bool):Void
    {
        if (entered)
            hoveredRow = row;
        else if (hoveredRow == row)
            hoveredRow = null;
        renderPreview();
    }

    private function closePreview():Void
    {
        hoveredRow = null;
        pinnedRow = null;
        renderPreview();
    }

    private function renderPreview():Void
    {
        var shown:Null<OpenChallengeRow> = pinnedRow ?? hoveredRow;
        if (shown == previewRow)
            return;

        if (previewRow != null)
            previewRow.setPreviewOpen(false);
        if (preview != null)
            removeComponent(preview);
        preview = null;
        previewRow = shown;
        Browser.document.removeEventListener("pointerdown", onDocumentPointerDown, true);

        if (shown == null || shown.challenge.customStartingPosition == null)
            return;

        shown.setPreviewOpen(true);
        preview = new PositionPreviewPopover(shown.challenge.customStartingPosition, shown.challenge.acceptorColor.getColor() ?? White);
        preview.includeInLayout = false;
        preview.element.style.zIndex = POPOVER_Z_INDEX;
        preview.element.style.visibility = "hidden";
        addComponent(preview);
        Browser.document.addEventListener("pointerdown", onDocumentPointerDown, true);

        var placed:PositionPreviewPopover = preview;
        Toolkit.callLater(() -> placePreview(placed, shown));
    }

    /**
        Wide: left of the Start column, centred on its row. Narrow: below the row, or above it when
        there is no room. Kept inside the panel.
    **/
    private function placePreview(placed:PositionPreviewPopover, row:OpenChallengeRow):Void
    {
        if (placed != preview)
            return;
        var anchor:Null<Component> = row.customAnchor();
        if (anchor == null)
            return;

        var cardRect:DOMRect = element.getBoundingClientRect();
        var rowRect:DOMRect = row.element.getBoundingClientRect();
        var anchorRect:DOMRect = anchor.element.getBoundingClientRect();
        var scale:Float = Toolkit.scaleX;
        var cardWidth:Float = cardRect.width / scale;
        var cardHeight:Float = cardRect.height / scale;
        var popoverWidth:Float = placed.element.offsetWidth / scale;
        var popoverHeight:Float = placed.element.offsetHeight / scale;
        var rowTop:Float = (rowRect.top - cardRect.top) / scale;
        var rowHeight:Float = rowRect.height / scale;

        var left:Float;
        var top:Float;
        if (narrow)
        {
            left = cardWidth - NARROW_POPOVER_INSET - popoverWidth;
            top = rowTop + rowHeight + POPOVER_GAP / 2;
            if (top + popoverHeight > cardHeight - POPOVER_EDGE_MARGIN)
                top = rowTop - popoverHeight - POPOVER_GAP / 2;
        }
        else
        {
            left = (anchorRect.left - cardRect.left) / scale - POPOVER_GAP - popoverWidth;
            top = rowTop + rowHeight / 2 - popoverHeight / 2;
        }
        top = Math.max(POPOVER_EDGE_MARGIN, Math.min(top, cardHeight - popoverHeight - POPOVER_EDGE_MARGIN));

        placed.left = left;
        placed.top = top;
        placed.element.style.visibility = "";
    }

    private function onDocumentPointerDown(event:Event):Void
    {
        if (pinnedRow == null)
            return;
        var target:Node = cast event.target;
        var anchor:Null<Component> = pinnedRow.customAnchor();
        var onAnchor:Bool = anchor != null && anchor.parentComponent != null && anchor.parentComponent.element.contains(target);
        if (onAnchor || (preview != null && preview.element.contains(target)))
            return;
        closePreview();
    }
}
