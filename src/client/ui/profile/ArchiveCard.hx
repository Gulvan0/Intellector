package client.ui.profile;

import client.datatypes.game.GameCounts;
import client.datatypes.game.GameRecord;
import client.datatypes.study.StudySummary;
import client.datatypes.timecontrol.TimeControlKind;
import client.ui.common.FilterDropdown;
import client.ui.common.LoadStatus;
import client.ui.common.Pager;
import client.ui.common.UnderlineTabs;
import client.ui.common.WidthObserver;
import client.ui.profile.ProfileState.ArchiveState;
import haxe.ui.components.Button;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.components.TextField;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.events.KeyboardEvent;
import haxe.ui.events.MouseEvent;
import haxefolio.LocaleUtils;
import haxefolio.structure.ScrollArea;
import morestd.Detachable;

using StringTools;
using client.ui.ComponentExtension;

typedef ArchiveCallbacks =
{
    /** Asks for a page of past games; `withCounts` when the filter changed, so the options' counts are stale **/
    onPastGamesQuery:(kinds:Array<TimeControlKind>, rated:Null<Bool>, page:Int, pageSize:Int, withCounts:Bool)->Void,
    onStudiesQuery:(tags:Array<String>, page:Int, pageSize:Int)->Void,
    onStateChanged:ArchiveState->Void
}

/** The player's past games and studies, as two tabs with a filter row each and one pager **/
class ArchiveCard extends VBox
{
    private static final KINDS:Array<TimeControlKind> = TimeControlKind.createAll();
    private static final TYPE_RATED:Array<Null<Bool>> = [null, true, false];

    private static inline final ENTER_KEY_CODE:Int = 13;
    private static inline final PAST_PAGE_SIZE:Int = 5;
    private static inline final CARD_BORDERS_WIDTH:Float = 2;
    private static inline final WIDE_LIST_MIN_WIDTH:Float = 600;
    private static inline final STUDY_CARD_HEIGHT:Float = 138;
    private static inline final STUDY_CARD_GAP:Float = 14;
    private static inline final STUDY_PANEL_PADDING:Float = 28;
    private static inline final TWO_STUDY_COLUMNS_MIN_WIDTH:Float = 614;

    private final callbacks:ArchiveCallbacks;
    private final login:String;

    private final tabs:UnderlineTabs;
    private final pastFilterRow:HBox;
    private final kindFilter:FilterDropdown;
    private final typeFilter:FilterDropdown;
    private final resetButton:Button;
    private final pastArea:Box;
    private final pastList:PastGamesList;
    private final pastStatus:LoadStatus;
    private final pastEmptyLabel:Label;

    private final studyFilterRow:HBox;
    private final tagField:TextField;
    private final addTagButton:Button;
    private final tagHintLabel:Label;
    private var tagFilterParts:Array<Component> = [];
    private final studyArea:Box;
    private final studyGrid:VBox;
    private final studyStatus:LoadStatus;
    private final studyEmptyLabel:Label;
    private final pager:Pager;
    private final widthHandle:Detachable;

    private var onStudies:Bool = false;
    private var selectedKinds:Array<TimeControlKind> = [];
    private var rated:Null<Bool> = null;
    private var pastPage:Int = 1;
    private var pastTotal:Null<Int> = null;
    private var anyPastGames:Bool = false;
    private var tags:Array<String> = [];
    private var studyPage:Int = 1;
    private var studyTotal:Null<Int> = null;
    private var studiesRequested:Bool = false;
    private var studies:Array<StudySummary> = [];
    private var studyColumns:Int = 1;
    private var studyPageSize:Int = 0;
    private var started:Bool = false;

    /** `login`: the profile's player; `restored`: the tab, filters and pages to start with, if any **/
    public function new(login:String, callbacks:ArchiveCallbacks, restored:Null<ArchiveState>)
    {
        super();
        this.login = login;
        this.callbacks = callbacks;
        percentWidth = 100;
        addClass(StyleClass.PROFILE_CARD);
        addClass(StyleClass.PROFILE_SECTION);

        tabs = new UnderlineTabs([
            LocaleUtils.localeBinding("intellector.profile.past.title"),
            LocaleUtils.localeBinding("intellector.profile.studies.title")
        ], true, index -> {
            onStudies = index == 1;
            renderTab();
            notifyStateChanged();
        });
        tabs.addClass(StyleClass.PROFILE_SECTION_TABS);
        addComponent(tabs);

        pastFilterRow = new HBox();
        pastFilterRow.percentWidth = 100;
        pastFilterRow.continuous = true;
        pastFilterRow.addClass(StyleClass.PROFILE_FILTER_ROW);
        addComponent(pastFilterRow);

        kindFilter = new FilterDropdown(
            LocaleUtils.localeBinding("intellector.common.filter.time_control"),
            [for (kind in KINDS) {caption: LocaleUtils.localeBinding('intellector.common.time_control_kind.${kind.getName().toLowerCase()}'), kind: kind}],
            true,
            250,
            selection -> {
                selectedKinds = [for (i in selection) KINDS[i]];
                queryPastGames(1, true);
            },
            LocaleUtils.localeBinding("intellector.common.filter.any_hint")
        );
        pastFilterRow.addComponent(kindFilter);

        typeFilter = new FilterDropdown(
            LocaleUtils.localeBinding("intellector.common.filter.type"),
            [
                {caption: LocaleUtils.localeBinding("intellector.common.filter.any")},
                {caption: LocaleUtils.localeBinding("intellector.common.game_type.rated")},
                {caption: LocaleUtils.localeBinding("intellector.common.game_type.casual")}
            ],
            false,
            200,
            selection -> {
                rated = TYPE_RATED[selection[0]];
                queryPastGames(1, true);
            }
        );
        pastFilterRow.addComponent(typeFilter);

        resetButton = new Button();
        resetButton.text = LocaleUtils.localeBinding("intellector.common.filter.reset");
        resetButton.addClass(StyleClass.FILTER_RESET);
        resetButton.onClick = _ -> {
            selectedKinds = [];
            rated = null;
            queryPastGames(1, true);
        };
        pastFilterRow.addComponent(resetButton);

        pastArea = new Box();
        pastArea.percentWidth = 100;
        addComponent(pastArea);

        pastList = new PastGamesList(login);
        pastArea.addComponent(pastList);

        pastStatus = new LoadStatus();
        pastStatus.addClass(StyleClass.PROFILE_ARCHIVE_STATUS);
        pastArea.addComponent(pastStatus);

        pastEmptyLabel = createEmptyLabel();
        pastArea.addComponent(pastEmptyLabel);

        studyFilterRow = new HBox();
        studyFilterRow.percentWidth = 100;
        studyFilterRow.continuous = true;
        studyFilterRow.addClass(StyleClass.PROFILE_FILTER_ROW);
        addComponent(studyFilterRow);

        tagField = new TextField();
        tagField.placeholder = LocaleUtils.localeBinding("intellector.profile.studies.add_tag");
        tagField.addClass(StyleClass.STUDY_TAG_FIELD);
        tagField.onChange = _ -> refreshAddButton();
        tagField.registerEvent(KeyboardEvent.KEY_DOWN, event -> {
            if (event.keyCode == ENTER_KEY_CODE)
                addTypedTag();
        });
        studyFilterRow.addComponent(tagField);

        addTagButton = new Button();
        addTagButton.text = LocaleUtils.localeBinding("intellector.profile.studies.add");
        addTagButton.addClass(StyleClass.FILTER_RESET);
        addTagButton.onClick = _ -> addTypedTag();
        studyFilterRow.addComponent(addTagButton);

        tagHintLabel = new Label();
        tagHintLabel.text = LocaleUtils.localeBinding("intellector.profile.studies.tag_filter_hint");
        tagHintLabel.addClass(StyleClass.PROFILE_SMALL_TEXT);
        tagHintLabel.verticalAlign = "center";
        studyFilterRow.addComponent(tagHintLabel);


        studyArea = new Box();
        studyArea.percentWidth = 100;
        studyArea.addClass(StyleClass.PROFILE_STUDY_PANEL);
        addComponent(studyArea);

        studyGrid = new VBox();
        studyGrid.percentWidth = 100;
        studyGrid.addClass(StyleClass.PROFILE_CARD_GRID);
        var scrollArea:ScrollArea = new ScrollArea(studyGrid);
        scrollArea.percentHeight = 100;
        studyArea.addComponent(scrollArea);

        studyStatus = new LoadStatus();
        studyStatus.addClass(StyleClass.PROFILE_ARCHIVE_STATUS);
        studyArea.addComponent(studyStatus);

        studyEmptyLabel = createEmptyLabel();
        studyArea.addComponent(studyEmptyLabel);

        pager = new Pager(page -> {
            if (onStudies)
                queryStudies(page);
            else
                queryPastGames(page, false);
        });
        addComponent(pager);

        widthHandle = WidthObserver.observe(this, width -> applyListWidth(width - CARD_BORDERS_WIDTH));

        applyListWidth(0);
        if (restored != null)
        {
            onStudies = restored.studies;
            selectedKinds = [for (kind in KINDS) if (restored.kinds.contains(kind.getName())) kind];
            rated = restored.rated;
            pastPage = restored.pastPage;
            tags = restored.tags.copy();
            studyPage = Std.int(restored.studyOffset / studyPageSize) + 1;
        }
        renderTab();
        renderTags();
    }

    /** Asks for the first pages of both tabs **/
    public function start():Void
    {
        queryPastGames(pastPage, true);
        queryStudies(studyPage);
        started = true;
    }

    /** `counts` is null when they weren't asked for **/
    public function setPastGames(games:Array<GameRecord>, total:Int, counts:Null<GameCounts>):Void
    {
        pastTotal = total;
        if (games.length == 0 && total > 0)
        {
            queryPastGames(Math.ceil(total / PAST_PAGE_SIZE), false);
            return;
        }
        if (counts != null)
        {
            kindFilter.setCounts([for (kind in KINDS) counts.ofKind(kind)]);
            typeFilter.setCounts([counts.rated + counts.casual, counts.rated, counts.casual]);
            if (selectedKinds.length == 0 && rated == null)
                anyPastGames = total > 0;
        }

        pastStatus.hidden = true;
        pastList.hidden = games.length == 0;
        pastList.setGames(games);
        pastEmptyLabel.hidden = games.length > 0;
        pastEmptyLabel.text = LocaleUtils.localeBinding(anyPastGames ? "intellector.profile.past.no_match" : "intellector.profile.past.no_finished");
        tabs.setCount(0, total);
        renderPager();
    }

    public function showPastGamesFailure(timedOut:Bool):Void
    {
        pastList.hidden = true;
        pastEmptyLabel.hidden = true;
        pastStatus.showFailure(timedOut, () -> queryPastGames(pastPage, true));
        pastStatus.hidden = false;
    }

    public function setStudies(studies:Array<StudySummary>, total:Int):Void
    {
        if (studies.length == 0 && total > 0)
        {
            studyTotal = total;
            queryStudies(Math.ceil(total / studyPageSize));
            return;
        }
        this.studies = studies;
        studyTotal = total;
        studyStatus.hidden = true;
        renderStudies();
        studyEmptyLabel.hidden = studies.length > 0;
        studyEmptyLabel.text = LocaleUtils.localeBinding(tags.length > 0 ? "intellector.profile.studies.no_match" : "intellector.profile.studies.none");
        tabs.setCount(1, total);
        renderPager();
    }

    public function showStudiesFailure(timedOut:Bool):Void
    {
        studyGrid.removeAllComponents();
        studyEmptyLabel.hidden = true;
        studyStatus.showFailure(timedOut, () -> queryStudies(studyPage));
        studyStatus.hidden = false;
    }

    public function dispose():Void
    {
        widthHandle.detach();
        kindFilter.close();
        typeFilter.close();
    }

    /**
        Both tabs share a frame five past game rows tall, so switching tabs never moves the page.
        Studies fill it with as many rows of cards as fit, two cards per row when the list allows.
    **/
    private function applyListWidth(listWidth:Float):Void
    {
        var narrow:Bool = listWidth > 0 && listWidth < WIDE_LIST_MIN_WIDTH;
        var frameHeight:Float = PAST_PAGE_SIZE * (narrow ? PastGamesList.NARROW_ROW_HEIGHT : PastGamesList.WIDE_ROW_HEIGHT);
        pastList.setNarrow(narrow);
        pastArea.height = frameHeight;
        studyArea.height = frameHeight;

        var columns:Int = listWidth - STUDY_PANEL_PADDING >= TWO_STUDY_COLUMNS_MIN_WIDTH ? 2 : 1;
        var rows:Int = Math.floor((frameHeight - STUDY_PANEL_PADDING + STUDY_CARD_GAP) / (STUDY_CARD_HEIGHT + STUDY_CARD_GAP));
        var pageSize:Int = rows * columns;
        if (columns != studyColumns)
        {
            studyColumns = columns;
            renderStudies();
        }
        if (pageSize != studyPageSize)
        {
            var firstStudyOffset:Int = (studyPage - 1) * studyPageSize;
            studyPageSize = pageSize;
            if (studiesRequested)
                queryStudies(Std.int(firstStudyOffset / pageSize) + 1);
        }
    }

    private function queryPastGames(page:Int, withCounts:Bool):Void
    {
        pastPage = page;
        kindFilter.setSelection([for (i in 0...KINDS.length) if (selectedKinds.contains(KINDS[i])) i]);
        typeFilter.setSelection([TYPE_RATED.indexOf(rated)]);
        resetButton.disabled = selectedKinds.length == 0 && rated == null;

        pastList.hidden = true;
        pastEmptyLabel.hidden = true;
        pastStatus.showLoading();
        pastStatus.hidden = false;
        callbacks.onPastGamesQuery(selectedKinds.copy(), rated, page, PAST_PAGE_SIZE, withCounts);
        notifyStateChanged();
    }

    private function queryStudies(page:Int):Void
    {
        studyPage = page;
        studiesRequested = true;
        studyGrid.removeAllComponents();
        studyEmptyLabel.hidden = true;
        studyStatus.showLoading();
        studyStatus.hidden = false;
        callbacks.onStudiesQuery(tags.copy(), page, studyPageSize);
        notifyStateChanged();
    }

    private function notifyStateChanged():Void
    {
        if (started)
            callbacks.onStateChanged({
                studies: onStudies,
                kinds: selectedKinds.map(kind -> kind.getName()),
                rated: rated,
                pastPage: pastPage,
                tags: tags.copy(),
                studyOffset: (studyPage - 1) * studyPageSize
            });
    }

    private function renderTab():Void
    {
        tabs.selectedIndex = onStudies ? 1 : 0;
        pastFilterRow.hidden = onStudies;
        pastArea.hidden = onStudies;
        studyFilterRow.hidden = !onStudies;
        studyArea.hidden = !onStudies;
        if (onStudies)
        {
            kindFilter.close();
            typeFilter.close();
        }
        renderPager();
    }

    private function renderPager():Void
    {
        var total:Int = (onStudies ? studyTotal : pastTotal) ?? 0;
        var page:Int = onStudies ? studyPage : pastPage;
        var pageSize:Int = onStudies ? studyPageSize : PAST_PAGE_SIZE;
        var pageCount:Int = Std.int(Math.max(1, Math.ceil(total / pageSize)));
        var first:Int = (page - 1) * pageSize + 1;
        pager.setState(page, pageCount, first, Std.int(Math.min(page * pageSize, total)), total);
    }

    private function renderStudies():Void
    {
        studyGrid.removeAllComponents();
        var row:Null<HBox> = null;
        for (i in 0...studies.length)
        {
            if (i % studyColumns == 0)
            {
                row = new HBox();
                row.percentWidth = 100;
                row.addClass(StyleClass.PROFILE_CARD_ROW);
                studyGrid.addComponent(row);
            }
            row.addComponent(new StudyCard(studies[i], tags, addTag));
        }

        if (row != null && studies.length % studyColumns != 0)
            for (_ in 0...studyColumns - studies.length % studyColumns)
            {
                var filler:Box = new Box();
                filler.percentWidth = 100;
                row.addComponent(filler);
            }
    }

    private function addTypedTag():Void
    {
        var typed:String = (tagField.text ?? "").trim();
        if (typed.length == 0)
            return;
        tagField.text = "";
        refreshAddButton();
        addTag(typed);
    }

    private function addTag(tag:String):Void
    {
        var normalized:String = StudyCard.normalize(tag);
        if (Lambda.exists(tags, existing -> StudyCard.normalize(existing) == normalized))
            return;

        tags.push(tag.trim());
        renderTags();
        queryStudies(1);
    }

    private function removeTag(tag:String):Void
    {
        tags.remove(tag);
        renderTags();
        queryStudies(1);
    }

    private function refreshAddButton():Void
    {
        addTagButton.disabled = (tagField.text ?? "").trim().length == 0;
    }

    private function renderTags():Void
    {
        refreshAddButton();
        tagHintLabel.hidden = tags.length > 0;
        for (part in tagFilterParts)
            studyFilterRow.removeComponent(part);
        tagFilterParts = [];
        if (tags.length == 0)
            return;

        var caption:Label = new Label();
        caption.text = LocaleUtils.localeBinding("intellector.profile.studies.tags_all");
        caption.addClass(StyleClass.PROFILE_SMALL_TEXT);
        caption.verticalAlign = "center";
        addTagFilterPart(caption);

        for (tag in tags)
        {
            var token:HBox = new HBox();
            token.addClass(StyleClass.STUDY_TOKEN);
            token.verticalAlign = "center";

            var tokenLabel:Label = new Label();
            tokenLabel.text = tag;
            tokenLabel.addClass(StyleClass.STUDY_TOKEN_TEXT);
            tokenLabel.verticalAlign = "center";
            token.addComponent(tokenLabel);

            var removeButton:Box = new Box();
            removeButton.addClass(StyleClass.STUDY_TOKEN_REMOVE);
            removeButton.tooltip = LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.profile.studies.remove_tag"), tag);
            removeButton.trackHover();
            removeButton.registerEvent(MouseEvent.CLICK, _ -> removeTag(tag));
            var cross:Image = new Image();
            cross.resource = Assets.profileIcon("remove_tag");
            cross.width = 10;
            cross.height = 10;
            cross.horizontalAlign = "center";
            cross.verticalAlign = "center";
            removeButton.addComponent(cross);
            token.addComponent(removeButton);

            addTagFilterPart(token);
        }

        var clearButton:Button = new Button();
        clearButton.text = LocaleUtils.localeBinding("intellector.profile.studies.clear");
        clearButton.addClass(StyleClass.FILTER_RESET);
        clearButton.verticalAlign = "center";
        clearButton.onClick = _ -> {
            tags = [];
            renderTags();
            queryStudies(1);
        };
        addTagFilterPart(clearButton);
    }

    private function addTagFilterPart(part:Component):Void
    {
        tagFilterParts.push(part);
        studyFilterRow.addComponent(part);
    }

    private function createEmptyLabel():Label
    {
        var label:Label = new Label();
        label.addClass(StyleClass.PROFILE_MUTED);
        label.horizontalAlign = "center";
        label.verticalAlign = "center";
        label.hidden = true;
        return label;
    }
}
