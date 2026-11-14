package client.ui.games;

import client.auth.IdentityKeeper;
import client.datatypes.games.ArchivePage;
import client.datatypes.games.ConditionGroup;
import client.datatypes.games.ResultColumn;
import client.datatypes.games.SavedFilter;
import client.datatypes.games.SortLevel;
import client.logic.games.FormulaCodec;
import client.logic.games.FormulaCodec.FormulaDecodingException;
import client.logic.games.FormulaFinalizer;
import client.storage.GamesViewStorage;
import client.ui.common.WidthObserver;
import client.ui.common.notifications.RequestFailureNotice;
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
import http.HttpError;
import morestd.Detachable;
import net.models.common.RestErrorCode;
import net.models.game.archive.ArchiveSearchPayload;
import net.models.game.archive.mappers.ArchiveMapper;
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

    private final formula:ConditionGroup = ConditionGroup.emptyRoot();

    private var frame:VBox;
    private var filterTitle:HBox;
    private var filterNameLabel:Label;
    private var filterAuthorLabel:Label;
    private var formulaBox:FormulaBox;
    private var resultsCard:ResultsCard;

    private var searchedRoot:ConditionGroup = ConditionGroup.emptyRoot();
    private var searchedJson:String;
    /** The saved filter the last search ran, unchanged **/
    private var savedFilter:Null<SavedFilter> = null;

    private var sort:Array<SortLevel>;
    private var columns:Array<ResultColumn>;
    private var pageNumber:Int = 1;
    /** Responses to all but the latest search request are dropped **/
    private var requestCounter:Int = 0;

    private var widthHandle:Null<Detachable> = null;
    private var tierHandle:Null<Detachable> = null;

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
        tierHandle = GamesLayoutTier.bind(tier -> frame.setClass(StyleClass.GAMES_NARROW, tier == Narrow));

        openFragment(HaxeFolioApp.fragment);
    }

    private override function onClose():Void
    {
        requestCounter++;
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

        filterTitle = new HBox();
        filterTitle.addClass(StyleClass.GAMES_FILTER_TITLE);
        filterTitle.hidden = true;
        filterNameLabel = new Label();
        filterNameLabel.addClass(StyleClass.GAMES_FILTER_NAME);
        filterTitle.addComponent(filterNameLabel);
        filterAuthorLabel = new Label();
        filterAuthorLabel.addClass(StyleClass.GAMES_FILTER_AUTHOR);
        filterTitle.addComponent(filterAuthorLabel);
        filterSection.addComponent(filterTitle);

        formulaBox = new FormulaBox();
        formulaBox.setFormula(formula);
        formulaBox.onChanged = refreshStale;
        filterSection.addComponent(formulaBox);

        var searchRow:HBox = new HBox();
        searchRow.percentWidth = 100;
        filterSection.addComponent(searchRow);
        var spacer:Box = new Box();
        spacer.percentWidth = 100;
        searchRow.addComponent(spacer);
        searchRow.addComponent(createSearchButton());

        resultsCard = new ResultsCard(PAGE_SIZE, onSortChanged, onColumnsChanged, onPageRequested);
        frame.addComponent(resultsCard);
    }

    private function createSearchButton():HBox
    {
        var button:HBox = new HBox();
        button.addClass(StyleClass.GAMES_SEARCH_BUTTON);
        button.horizontalAlign = "right";
        button.trackHover();
        button.trackPress();
        button.registerEvent(MouseEvent.CLICK, _ -> search());

        var icon:Image = new Image();
        icon.resource = Assets.gamesIcon("search");
        icon.verticalAlign = "center";
        button.addComponent(icon);

        var label:Label = new Label();
        label.text = LocaleUtils.localeBinding("intellector.games.search");
        label.addClass(StyleClass.GAMES_SEARCH_BUTTON_TEXT);
        label.verticalAlign = "center";
        button.addComponent(label);
        return button;
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
        refreshFilterTitle();
        refreshStale();
        pageNumber = 1;
        requestPage();
    }

    private function replaceFormula(root:ConditionGroup):Void
    {
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
        var filter:Null<SavedFilter> = savedFilter;
        filterTitle.hidden = filter == null;
        if (filter == null)
            return;

        if (filter.key != null)
            filterNameLabel.text = LocaleUtils.localeBinding('intellector.games.filter.${filter.key}');
        else
            filterNameLabel.text = filter.name;

        var authorLogin:Null<String> = filter.authorLogin;
        if (authorLogin == null)
            filterAuthorLabel.hidden = true;
        else
        {
            filterAuthorLabel.hidden = false;
            var own:Bool = switch IdentityKeeper.currentIdentity {
                case Player(login, _): login == authorLogin;
                default: false;
            }
            if (own)
                filterAuthorLabel.text = LocaleUtils.localeBinding("intellector.games.filter.by_you");
            else
                LocaleManager.instance.registerComponent(filterAuthorLabel, "text", () -> LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.games.filter.by"), LocaleUtils.resolveText(filter.authorNickname ?? authorLogin)));
        }
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
            if (requestId == requestCounter)
                resultsCard.showPage(ArchiveMapper.resultToDatatype(dto), requestedPage);
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
