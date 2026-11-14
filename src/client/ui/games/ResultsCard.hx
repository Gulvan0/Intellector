package client.ui.games;

import client.datatypes.games.ArchivePage;
import client.datatypes.games.ResultColumn;
import client.datatypes.games.SortLevel;
import client.logic.games.SortRules;
import client.ui.common.Pager;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;

/**
    The results of the last search: the sorting and the column choice above, a notice while the
    formula box differs from that search, the table or its loading / empty state, and the pager.
**/
class ResultsCard extends VBox
{
    private final sortChips:SortChips;
    private final columnsDropdown:ColumnsDropdown;
    private final staleNotice:HBox;
    private final table:ResultsTable;
    private final stateLabel:Label;
    private final pager:Pager;
    private final pageSize:Int;

    private var sort:Array<SortLevel> = [];
    private var columns:Array<ResultColumn> = [];
    private var shownPage:Null<ArchivePage> = null;

    /** `pageSize`: the games per page **/
    public function new(pageSize:Int, onSortChanged:Array<SortLevel>->Void, onColumnsChanged:Array<ResultColumn>->Void, onPageRequested:Int->Void)
    {
        super();
        this.pageSize = pageSize;
        percentWidth = 100;
        addClass(StyleClass.GAMES_RESULTS_CARD);

        var bar:HBox = new HBox();
        bar.percentWidth = 100;
        bar.addClass(StyleClass.GAMES_RESULTS_BAR);
        addComponent(bar);

        sortChips = new SortChips();
        sortChips.percentWidth = 100;
        sortChips.verticalAlign = "center";
        sortChips.onChanged = onSortChanged;
        bar.addComponent(sortChips);

        columnsDropdown = new ColumnsDropdown();
        columnsDropdown.verticalAlign = "center";
        columnsDropdown.onChanged = onColumnsChanged;
        bar.addComponent(columnsDropdown);

        staleNotice = new HBox();
        staleNotice.addClass(StyleClass.GAMES_STALE_NOTICE);
        staleNotice.hidden = true;
        var staleIcon:Image = new Image();
        staleIcon.resource = Assets.gamesIcon("info");
        staleIcon.verticalAlign = "center";
        staleNotice.addComponent(staleIcon);
        var staleLabel:Label = new Label();
        staleLabel.text = LocaleUtils.localeBinding("intellector.games.results.stale");
        staleLabel.addClass(StyleClass.GAMES_STALE_NOTICE_TEXT);
        staleLabel.verticalAlign = "center";
        staleNotice.addComponent(staleLabel);
        addComponent(staleNotice);

        table = new ResultsTable();
        table.onHeaderClicked = column -> onSortChanged(SortRules.byHeader(sort, column));
        addComponent(table);

        var stateBox:Box = new Box();
        stateBox.percentWidth = 100;
        stateBox.addClass(StyleClass.GAMES_RESULTS_STATE);
        stateLabel = new Label();
        stateLabel.addClass(StyleClass.GAMES_RESULTS_STATE_TEXT);
        stateLabel.horizontalAlign = "center";
        stateLabel.verticalAlign = "center";
        stateBox.addComponent(stateLabel);
        addComponent(stateBox);

        pager = new Pager(onPageRequested);
        addComponent(pager);

        showLoading();
    }

    public function setSort(sort:Array<SortLevel>):Void
    {
        this.sort = sort;
        sortChips.render(sort, columns);
        renderTable();
    }

    public function setColumns(columns:Array<ResultColumn>):Void
    {
        this.columns = columns;
        columnsDropdown.setVisible(columns);
        sortChips.render(sort, columns);
        renderTable();
    }

    public function setStale(stale:Bool):Void
    {
        staleNotice.hidden = !stale;
    }

    public function showLoading():Void
    {
        shownPage = null;
        showState("intellector.games.results.loading");
        pager.hidden = true;
    }

    public function showFailure():Void
    {
        shownPage = null;
        showState("intellector.games.results.failed");
        pager.hidden = true;
    }

    /** `page` is the `pageNumber`-th (1-based) of the results **/
    public function showPage(page:ArchivePage, pageNumber:Int):Void
    {
        shownPage = page;
        if (page.games.length == 0)
        {
            showState("intellector.games.results.empty");
            pager.hidden = true;
            return;
        }

        stateLabel.parentComponent.hidden = true;
        table.hidden = false;
        renderTable();

        var pageCount:Int = Std.int(Math.max(1, Math.ceil(page.total / pageSize)));
        var first:Int = (pageNumber - 1) * pageSize + 1;
        pager.setState(pageNumber, pageCount, first, first + page.games.length - 1, page.total);
        pager.hidden = false;
    }

    private function showState(key:String):Void
    {
        stateLabel.text = LocaleUtils.localeBinding(key);
        stateLabel.parentComponent.hidden = false;
        table.hidden = true;
    }

    private function renderTable():Void
    {
        if (shownPage != null && shownPage.games.length > 0)
            table.render(shownPage.games, columns, sort);
    }
}
