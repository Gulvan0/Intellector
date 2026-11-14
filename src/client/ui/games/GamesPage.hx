package client.ui.games;

import client.auth.Identity;
import client.auth.IdentityKeeper;
import client.datatypes.games.ArchivePage;
import client.datatypes.games.ConditionGroup;
import client.datatypes.games.ResultColumn;
import client.datatypes.games.SavedFilter;
import client.datatypes.games.SavedFilterSummary;
import client.datatypes.games.SortLevel;
import client.logic.games.FormulaCodec.FormulaDecodingException;
import client.logic.games.FormulaCodec;
import client.logic.games.FormulaFinalizer;
import client.logic.games.ResultColumns;
import client.storage.GamesViewStorage;
import client.ui.common.WidthObserver;
import client.ui.common.notifications.InfoNotice;
import client.ui.common.notifications.RequestFailureNotice;
import client.ui.common.overlays.login.LoginOverlay;
import client.ui.games.flow.ConditionFlow;
import client.utils.PagePaths;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import haxe.ui.locale.LocaleManager;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.PageBase;
import haxefolio.browser.Clipboard;
import haxefolio.browser.FileDownload;
import http.HttpError;
import morestd.Detachable;
import net.models.common.RestErrorCode;
import net.models.game.archive.ArchiveExportPayload;
import net.models.game.archive.ArchiveSearchPayload;
import net.models.game.archive.SaveFilterPayload;
import net.models.game.archive.mappers.ArchiveMapper;
import net.rest.FileRequests;
import net.rest.Rest;
import net.rest.RestErrors;
import net.rest.RestOperationRegistry;

using StringTools;
using client.ui.ComponentExtension;

/**
    The game database (`?p=games`): a formula of conditions, the search running it and the paged,
    sortable results. The URL fragment names the last search: `#/<id>` or `#/<key>` a saved filter,
    `#<base64url>` an unsaved formula, none the empty one.
**/
class GamesPage extends PageBase
{
    private static inline final PAGE_SIZE:Int = 20;
    private static inline final MAX_WIDTH:Float = 1180;
    private static inline final SAVED_FILTER_PREFIX:String = "/";
    private static inline final LINK_COPIED_MS:Int = 3000;
    private static inline final EXPORT_FALLBACK_NAME:String = "intellector_games.xlsx";
    private static inline final GAME_ID_PLACEHOLDER:String = "{game_id}";

    private final formula:ConditionGroup = ConditionGroup.emptyRoot();

    private var frame:VBox;
    private var filterBar:FilterBar;
    private var searchButton:Box;
    private var searchSpacer:Box;
    private var formulaBox:FormulaBox;
    private var resultsCard:ResultsCard;

    private var searchedRoot:ConditionGroup = ConditionGroup.emptyRoot();
    private var searchedJson:String;
    /** The saved filter the last search ran, unchanged **/
    private var savedFilter:Null<SavedFilter> = null;

    private var sort:Array<SortLevel>;
    private var columns:Array<ResultColumn>;
    private var pageNumber:Int = 1;
    /** The games the last search found, once its first response came **/
    private var searchedTotal:Null<Int> = null;
    /** Responses to all but the latest search request are dropped **/
    private var requestCounter:Int = 0;

    private var widthHandle:Null<Detachable> = null;
    private var tierHandle:Null<Detachable> = null;
    private var tier:GamesLayoutTier = Wide;
    private var flow:Null<ConditionFlow> = null;

    public function new()
    {
        super();
        searchedJson = FormulaCodec.encode(searchedRoot);
    }

    private override function init():Void
    {
        setTitle(LocaleUtils.localeBinding("intellector.games.title"));
        sort = GamesViewStorage.readSort();
        columns = GamesViewStorage.readColumns();

        buildLayout();
        resultsCard.setSort(sort);
        resultsCard.setColumns(columns);

        widthHandle = WidthObserver.observe(this, width -> frame.width = Math.min(width, MAX_WIDTH));
        tierHandle = GamesLayoutTier.bind(applyTier);

        IdentityKeeper.addChangeListener(onIdentityChanged);
        openFragment(HaxeFolioApp.fragment);
    }

    // the login is restored after the page opens: who owns the filter may change
    private function onIdentityChanged(_:Identity):Void
    {
        refreshFilterTitle();
    }

    private override function onClose():Void
    {
        requestCounter++;
        endFlow();
        formulaBox.closeKeywordSwitch();
        filterBar.closeOpenList();
        IdentityKeeper.removeChangeListener(onIdentityChanged);
        if (widthHandle != null)
            widthHandle.detach();
        if (tierHandle != null)
            tierHandle.detach();
    }

    private function buildLayout():Void
    {
        frame = new VBox();
        frame.horizontalAlign = "center";
        frame.addClass(StyleClass.GAMES_FRAME);
        addComponent(frame);

        var heading:Label = new Label();
        heading.text = LocaleUtils.localeBinding("intellector.games.title");
        heading.addClass(StyleClass.GAMES_HEADING);
        frame.addComponent(heading);

        var filterSection:VBox = new VBox();
        filterSection.percentWidth = 100;
        filterSection.addClass(StyleClass.GAMES_FILTER_SECTION);
        frame.addComponent(filterSection);

        filterBar = new FilterBar();
        filterBar.onShare = share;
        filterBar.onSave = save;
        filterBar.onDelete = delete;
        filterBar.onOpenPressed = onOpenPressed;
        filterBar.onFilterPicked = openPicked;
        filterSection.addComponent(filterBar);

        formulaBox = new FormulaBox();
        formulaBox.setFormula(formula);
        formulaBox.onChanged = refreshStale;
        formulaBox.onAddRequested = (group, button) -> {
            endFlow();
            flow = ConditionFlow.add(formulaBox, formula, group, button, this, tier == Narrow, onFlowFinished);
        };
        formulaBox.onEditRequested = (condition, pill) -> {
            endFlow();
            flow = ConditionFlow.edit(formulaBox, formula, condition, pill, this, tier == Narrow, onFlowFinished);
        };
        filterSection.addComponent(formulaBox);

        var searchRow:HBox = new HBox();
        searchRow.percentWidth = 100;
        filterSection.addComponent(searchRow);
        searchSpacer = new Box();
        searchSpacer.percentWidth = 100;
        searchRow.addComponent(searchSpacer);
        searchButton = createSearchButton();
        searchRow.addComponent(searchButton);

        resultsCard = new ResultsCard(PAGE_SIZE, onSortChanged, onColumnsChanged, onPageRequested);
        resultsCard.onExportPressed = presentExport;
        frame.addComponent(resultsCard);
    }

    private function createSearchButton():Box
    {
        var button:Box = new Box();
        button.addClass(StyleClass.GAMES_SEARCH_BUTTON);
        button.horizontalAlign = "right";
        button.trackHover();
        button.trackPress();
        button.registerEvent(MouseEvent.CLICK, _ -> search());

        var content:HBox = new HBox();
        content.addClass(StyleClass.GAMES_BUTTON_CONTENT);
        content.horizontalAlign = "center";
        content.verticalAlign = "center";
        button.addComponent(content);

        var icon:Image = new Image();
        icon.resource = Assets.gamesIcon("search");
        icon.verticalAlign = "center";
        content.addComponent(icon);

        var label:Label = new Label();
        label.text = LocaleUtils.localeBinding("intellector.games.search");
        label.addClass(StyleClass.GAMES_SEARCH_BUTTON_TEXT);
        label.verticalAlign = "center";
        content.addComponent(label);
        return button;
    }

    private function applyTier(newTier:GamesLayoutTier):Void
    {
        tier = newTier;
        var narrow:Bool = newTier == Narrow;
        frame.setClass(StyleClass.GAMES_NARROW, narrow);
        filterBar.setNarrow(narrow);
        resultsCard.setNarrow(narrow);
        searchButton.setFillsWidth(narrow);
        searchSpacer.hidden = narrow;
    }

    private function onFlowFinished():Void
    {
        flow = null;
        refreshStale();
    }

    /** Cancels the condition being added or edited, if any **/
    private function endFlow():Void
    {
        if (flow != null)
            flow.abort();
        flow = null;
    }

    /** Fills the formula from `fragment` and runs the search, keeping the URL **/
    private function openFragment(fragment:Null<String>):Void
    {
        if (fragment == null || fragment == "")
        {
            runOpened(ConditionGroup.emptyRoot(), null);
            return;
        }

        if (!fragment.startsWith(SAVED_FILTER_PREFIX))
        {
            var root:Null<ConditionGroup> = decodeOrNull(() -> FormulaCodec.fromFragment(fragment));
            if (root != null)
                runOpened(root, null);
            else
                openUnreadable();
            return;
        }

        resultsCard.showLoading();
        var idOrKey:String = fragment.substr(SAVED_FILTER_PREFIX.length);
        Rest.client().execute(RestOperationRegistry.GET_SAVED_FILTER, dto -> {
            var filter:SavedFilter = ArchiveMapper.savedFilterToDatatype(dto);
            var root:Null<ConditionGroup> = decodeOrNull(() -> FormulaCodec.decode(filter.formulaJson));
            if (root != null)
                runOpened(root, filter);
            else
                openUnreadable();
        }, error -> onFilterRequestFailed(error, fragment), ["id_or_key" => idOrKey]);
    }

    private function onFilterRequestFailed(error:HttpError, fragment:String):Void
    {
        if (RestErrors.codeOf(error) == FILTER_NOT_FOUND)
            openUnreadable();
        else
        {
            resultsCard.showFailure();
            RequestFailureNotice.showHttpError(OPEN_FILTER, error, () -> openFragment(fragment));
        }
    }

    /** A missing filter or a damaged link: tells so and opens the empty formula instead **/
    private function openUnreadable():Void
    {
        RequestFailureNotice.show(OPEN_FILTER, FilterUnavailable);
        HaxeFolioApp.setFragment(null);
        runOpened(ConditionGroup.emptyRoot(), null);
    }

    private function runOpened(root:ConditionGroup, filter:Null<SavedFilter>):Void
    {
        replaceFormula(root);
        savedFilter = filter;
        commitSearch();
    }

    /** The Search button: finalizes the formula and runs it **/
    private function search():Void
    {
        endFlow();
        FormulaFinalizer.finalize(formula);
        formulaBox.render();

        var json:String = FormulaCodec.encode(formula);
        if (savedFilter != null && json != FormulaCodec.encode(FormulaCodec.decode(savedFilter.formulaJson)))
            savedFilter = null;

        commitSearch();

        var fragment:Null<String> = searchedFragment();
        if (fragment != currentFragment())
            HaxeFolioApp.setFragment(fragment, true);
    }

    /** Makes the formula box's (finalized) formula the searched one and requests its first page **/
    private function commitSearch():Void
    {
        searchedRoot = formula.copy();
        searchedJson = FormulaCodec.encode(searchedRoot);
        searchedTotal = null;
        refreshFilterTitle();
        refreshStale();
        pageNumber = 1;
        requestPage();
    }

    private function replaceFormula(root:ConditionGroup):Void
    {
        endFlow();
        formula.children.resize(0);
        for (child in root.children)
            formula.children.push(child);
        formulaBox.render();
    }

    private function searchedFragment():Null<String>
    {
        if (savedFilter != null)
            return SAVED_FILTER_PREFIX + (savedFilter.key ?? Std.string(savedFilter.id));
        return searchedRoot.children.length > 0 ? FormulaCodec.toFragment(searchedRoot) : null;
    }

    private function currentFragment():Null<String>
    {
        var fragment:Null<String> = HaxeFolioApp.fragment;
        return fragment == "" ? null : fragment;
    }

    private function refreshStale():Void
    {
        var finalized:ConditionGroup = formula.copy();
        FormulaFinalizer.finalize(finalized);
        resultsCard.setStale(FormulaCodec.encode(finalized) != searchedJson);
    }

    private function refreshFilterTitle():Void
    {
        filterBar.setFilter(savedFilter, ownsSavedFilter());
    }

    private function ownsSavedFilter():Bool
    {
        var filter:Null<SavedFilter> = savedFilter;
        if (filter == null || filter.authorLogin == null)
            return false;
        return switch IdentityKeeper.currentIdentity {
            case Player(login, _): login == filter.authorLogin;
            default: false;
        }
    }

    /** Whether the formula box, finalized, differs from the last search **/
    private function diverged():Bool
    {
        var finalized:ConditionGroup = formula.copy();
        FormulaFinalizer.finalize(finalized);
        return FormulaCodec.encode(finalized) != searchedJson;
    }

    /** Share and Save act on what the formula box shows: a diverged one is searched first **/
    private function searchIfDiverged():Void
    {
        if (diverged())
            search();
    }

    private function share():Void
    {
        searchIfDiverged();
        var url:String = HaxeFolioApp.pageUrl("games", searchedFragment());
        var textKey:String = savedFilter != null ? "intellector.games.share.saved" : "intellector.games.share.snapshot";
        // without a secure origin there is no `navigator.clipboard` at all
        try
        {
            Clipboard.copy(url, () -> InfoNotice.show("intellector.games.share.copied", textKey, LINK_COPIED_MS), _ -> onCopyFailed());
        }
        catch (_)
        {
            onCopyFailed();
        }
    }

    private function onCopyFailed():Void
    {
        InfoNotice.show("intellector.common.copy.error_title", "intellector.games.share.copy_failed", LINK_COPIED_MS);
    }

    private function save():Void
    {
        if (IdentityKeeper.currentIdentity.isGuest())
        {
            LoginOverlay.present();
            return;
        }
        searchIfDiverged();
        FilterDialogs.askName(ownsSavedFilter() ? savedFilter.name : "", name -> saveAs(name, false));
    }

    /** Saves the searched formula as the user's filter `name`; a taken name asks to overwrite first **/
    private function saveAs(name:String, overwrite:Bool):Void
    {
        var root:ConditionGroup = searchedRoot.copy();
        var payload:SaveFilterPayload = {name: name, formula: FormulaCodec.encode(root), overwrite: overwrite};
        Rest.client().execute(RestOperationRegistry.SAVE_FILTER, dto -> {
            if (FormulaCodec.encode(searchedRoot) != FormulaCodec.encode(root))
                return;
            savedFilter = ArchiveMapper.savedFilterToDatatype(dto);
            HaxeFolioApp.setFragment(searchedFragment());
            refreshFilterTitle();
        }, error -> {
            if (RestErrors.codeOf(error) == FILTER_NAME_TAKEN)
                FilterDialogs.confirmOverwrite(name, () -> saveAs(name, true));
            else
                RequestFailureNotice.showHttpError(SAVE_FILTER, error, () -> saveAs(name, overwrite));
        }, null, null, payload);
    }

    private function delete():Void
    {
        var filter:Null<SavedFilter> = savedFilter;
        if (filter == null || !ownsSavedFilter())
            return;
        FilterDialogs.confirmDeletion(filter.name, () -> deleteFilter(filter));
    }

    private function deleteFilter(filter:SavedFilter):Void
    {
        var onDeleted:Void->Void = () -> {
            if (savedFilter != filter)
                return;
            savedFilter = null;
            HaxeFolioApp.setFragment(searchedFragment());
            refreshFilterTitle();
        };
        Rest.client().execute(RestOperationRegistry.DELETE_SAVED_FILTER, _ -> onDeleted(), error -> {
            if (RestErrors.codeOf(error) == FILTER_NOT_FOUND)
                onDeleted();
            else
                RequestFailureNotice.showHttpError(DELETE_FILTER, error, () -> deleteFilter(filter));
        }, ["filter_id" => Std.string(filter.id)]);
    }

    /** Guests are asked to log in instead; the user's filters are requested for the dropdown **/
    private function onOpenPressed():Bool
    {
        if (IdentityKeeper.currentIdentity.isGuest())
        {
            LoginOverlay.present();
            return false;
        }
        Rest.client().execute(RestOperationRegistry.GET_MY_SAVED_FILTERS, dtos -> {
            var filters:Array<SavedFilterSummary> = dtos.parsed.map(ArchiveMapper.summaryToDatatype);
            filterBar.setOpenList(Filters(filters));
        }, _ -> filterBar.setOpenList(Failed));
        return true;
    }

    /** Opens a filter from the dropdown; one that is gone or unreadable leaves the page as it is **/
    private function openPicked(summary:SavedFilterSummary):Void
    {
        Rest.client().execute(RestOperationRegistry.GET_SAVED_FILTER, dto -> {
            var filter:SavedFilter = ArchiveMapper.savedFilterToDatatype(dto);
            var root:Null<ConditionGroup> = decodeOrNull(() -> FormulaCodec.decode(filter.formulaJson));
            if (root == null)
            {
                RequestFailureNotice.show(OPEN_FILTER, FilterUnavailable);
                return;
            }
            runOpened(root, filter);
            var fragment:Null<String> = searchedFragment();
            if (fragment != currentFragment())
                HaxeFolioApp.setFragment(fragment, true);
        }, error -> {
            if (RestErrors.codeOf(error) == FILTER_NOT_FOUND)
                RequestFailureNotice.show(OPEN_FILTER, FilterUnavailable);
            else
                RequestFailureNotice.showHttpError(OPEN_FILTER, error, () -> openPicked(summary));
        }, ["id_or_key" => Std.string(summary.id)]);
    }

    private function presentExport():Void
    {
        ExportOverlay.present(searchedTotal ?? 0, columns.length, sort, exportGames);
    }

    /** Downloads the last search's whole result set, sorted and with the columns shown **/
    private function exportGames(includeMoves:Bool):Void
    {
        var payload:ArchiveExportPayload = {
            formula: FormulaCodec.encodeForRequest(searchedRoot),
            sort: ArchiveMapper.sortToDto(sort),
            columns: [for (column in ResultColumns.ordered(columns)) (column : String)],
            include_moves: includeMoves,
            game_url_template: HaxeFolioApp.pageUrl(PagePaths.liveGameTemplate(GAME_ID_PLACEHOLDER)),
            locale: LocaleManager.instance.language,
            timezone: js.Syntax.code("Intl.DateTimeFormat().resolvedOptions().timeZone")
        };
        resultsCard.setExporting(true);
        FileRequests.post(RestOperationRegistry.EXPORT_GAME_ARCHIVE_PATH, payload, EXPORT_FALLBACK_NAME, (blob, fileName) -> {
            resultsCard.setExporting(false);
            FileDownload.save(blob, fileName);
        }, error -> {
            resultsCard.setExporting(false);
            RequestFailureNotice.showHttpError(EXPORT_GAMES, error, () -> exportGames(includeMoves));
        });
    }

    private function onSortChanged(levels:Array<SortLevel>):Void
    {
        sort = levels;
        GamesViewStorage.saveSort(levels);
        resultsCard.setSort(levels);
        pageNumber = 1;
        requestPage();
    }

    private function onColumnsChanged(visible:Array<ResultColumn>):Void
    {
        columns = visible;
        GamesViewStorage.saveColumns(visible);
        resultsCard.setColumns(visible);
    }

    private function onPageRequested(page:Int):Void
    {
        pageNumber = page;
        requestPage();
    }

    private function requestPage():Void
    {
        requestCounter++;
        var requestId:Int = requestCounter;
        var requestedPage:Int = pageNumber;
        resultsCard.showLoading();

        var payload:ArchiveSearchPayload = {
            formula: FormulaCodec.encodeForRequest(searchedRoot),
            sort: ArchiveMapper.sortToDto(sort),
            offset: (requestedPage - 1) * PAGE_SIZE,
            limit: PAGE_SIZE
        };
        Rest.client().execute(RestOperationRegistry.SEARCH_GAME_ARCHIVE, dto -> {
            if (requestId != requestCounter)
                return;
            var page:ArchivePage = ArchiveMapper.resultToDatatype(dto);
            searchedTotal = page.total;
            resultsCard.showPage(page, requestedPage);
        }, error -> {
            if (requestId != requestCounter)
                return;
            resultsCard.showFailure();
            RequestFailureNotice.showHttpError(SEARCH_GAMES, error, requestPage);
        }, null, null, payload);
    }

    private static function decodeOrNull(decode:Void->ConditionGroup):Null<ConditionGroup>
    {
        try
            return decode()
        catch (e:FormulaDecodingException)
            return null;
    }
}
