package client.ui.profile;

import client.datatypes.player.GameStats;
import client.datatypes.player.KindStats;
import client.datatypes.player.RatingPoint;
import client.datatypes.timecontrol.TimeControlKind;
import client.formatters.GameFormatters;
import client.ui.common.LoadStatus;
import client.ui.common.TimeControlKindIcon;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;

using client.ui.ComponentExtension;

/**
    Games per time control kind, rated ones and the current rating, as a table whose rows pick the
    kind of the rating history chart under it. Only kinds with a rated game can be picked.
**/
class GameStatsCard extends AsideCard
{
    private final onKindPicked:TimeControlKind->Void;

    private final loadStatus:LoadStatus;
    private final table:VBox;
    private final rows:Array<HBox> = [];
    private final noGamesLabel:Label;
    private final chartBox:VBox;
    private final chartTitleLabel:Label;
    private final peakLabel:Label;
    private final chartStatus:LoadStatus;
    private final chart:RatingChart;
    private final noRatedNote:Label;

    private var stats:Null<GameStats> = null;
    private var selectedKind:Null<TimeControlKind> = null;

    /** `onKindPicked` is called for the initially shown kind too, to load its history **/
    public function new(onKindPicked:TimeControlKind->Void)
    {
        super(LocaleUtils.localeBinding("intellector.profile.stats.title"));
        this.onKindPicked = onKindPicked;
        body.addClass(StyleClass.PROFILE_STATS_BODY);

        loadStatus = new LoadStatus();
        body.addComponent(loadStatus);

        table = new VBox();
        table.percentWidth = 100;
        table.addClass(StyleClass.PROFILE_STATS_TABLE);
        table.hidden = true;
        body.addComponent(table);
        table.addComponent(createHeader());

        noGamesLabel = new Label();
        noGamesLabel.text = LocaleUtils.localeBinding("intellector.profile.stats.no_finished");
        noGamesLabel.addClass(StyleClass.PROFILE_MUTED);
        noGamesLabel.addClass(StyleClass.PROFILE_STATS_NO_GAMES);
        noGamesLabel.hidden = true;
        body.addComponent(noGamesLabel);

        chartBox = new VBox();
        chartBox.percentWidth = 100;
        chartBox.addClass(StyleClass.PROFILE_STATS_CHART);
        chartBox.hidden = true;
        body.addComponent(chartBox);

        var chartHead:HBox = new HBox();
        chartHead.percentWidth = 100;
        chartHead.addClass(StyleClass.PROFILE_STATS_CHART_HEAD);
        chartBox.addComponent(chartHead);

        chartTitleLabel = new Label();
        chartTitleLabel.percentWidth = 100;
        chartTitleLabel.addClass(StyleClass.PROFILE_SMALL_TEXT);
        chartTitleLabel.verticalAlign = "center";
        chartHead.addComponent(chartTitleLabel);

        var peakCaption:Label = new Label();
        peakCaption.text = LocaleUtils.localeBinding("intellector.profile.stats.peak");
        peakCaption.addClass(StyleClass.PROFILE_SMALL_TEXT);
        peakCaption.verticalAlign = "center";
        chartHead.addComponent(peakCaption);

        peakLabel = new Label();
        peakLabel.addClass(StyleClass.PROFILE_MONO);
        peakLabel.verticalAlign = "center";
        chartHead.addComponent(peakLabel);

        chartStatus = new LoadStatus();
        chartStatus.addClass(StyleClass.PROFILE_STATS_CHART_STATUS);
        chartBox.addComponent(chartStatus);

        chart = new RatingChart();
        chart.hidden = true;
        chartBox.addComponent(chart);

        noRatedNote = new Label();
        noRatedNote.text = LocaleUtils.localeBinding("intellector.profile.stats.no_rated_note");
        noRatedNote.percentWidth = 100;
        noRatedNote.addClass(StyleClass.PROFILE_STATS_NOTE);
        noRatedNote.hidden = true;
        body.addComponent(noRatedNote);
    }

    public function showLoading():Void
    {
        loadStatus.showLoading();
        loadStatus.hidden = false;
        table.hidden = true;
        noGamesLabel.hidden = true;
        chartBox.hidden = true;
        noRatedNote.hidden = true;
    }

    public function showFailure(timedOut:Bool, onRetry:Void->Void):Void
    {
        loadStatus.showFailure(timedOut, onRetry);
        loadStatus.hidden = false;
        table.hidden = true;
        noGamesLabel.hidden = true;
        chartBox.hidden = true;
        noRatedNote.hidden = true;
    }

    public function setStats(stats:GameStats):Void
    {
        this.stats = stats;
        loadStatus.hidden = true;

        for (row in rows)
            table.removeComponent(row);
        rows.resize(0);
        for (kindStats in stats.kinds)
        {
            var row:HBox = createRow(kindStats);
            rows.push(row);
            table.addComponent(row);
        }

        var hasGames:Bool = stats.hasGames();
        var ratedKinds:Array<KindStats> = stats.ratedKinds();
        table.hidden = !hasGames;
        noGamesLabel.hidden = hasGames;
        noRatedNote.hidden = !hasGames || ratedKinds.length > 0;
        chartBox.hidden = ratedKinds.length == 0;

        if (ratedKinds.length > 0)
        {
            var initialKind:TimeControlKind = stats.mainRating != null ? stats.mainRating.kind : ratedKinds[0].kind;
            selectKind(initialKind);
        }
    }

    /** The history of `kind`, if it is still the shown one **/
    public function setHistory(kind:TimeControlKind, points:Array<RatingPoint>):Void
    {
        if (kind != selectedKind)
            return;

        chartStatus.hidden = true;
        if (points.length == 0)
        {
            chart.hidden = true;
            peakLabel.text = "";
            return;
        }

        var peak:Int = points[0].elo;
        for (point in points)
            peak = Std.int(Math.max(peak, point.elo));
        peakLabel.text = Std.string(peak);

        var daily:Array<RatingPoint> = RatingChart.dailyPoints(points);
        chart.hidden = daily.length < 2;
        if (daily.length >= 2)
            chart.setPoints(daily);
    }

    public function showHistoryFailure(kind:TimeControlKind, timedOut:Bool, onRetry:Void->Void):Void
    {
        if (kind != selectedKind)
            return;

        chart.hidden = true;
        chartStatus.showFailure(timedOut, onRetry);
        chartStatus.hidden = false;
    }

    public function dispose():Void
    {
        chart.dispose();
    }

    private function selectKind(kind:TimeControlKind):Void
    {
        selectedKind = kind;
        for (i in 0...rows.length)
            rows[i].setClass(StyleClass.PROFILE_STATS_ROW_SELECTED, stats.kinds[i].kind == kind);

        var kindName:String = LocaleUtils.localeBinding('intellector.common.time_control_kind.${kind.getName().toLowerCase()}');
        LocaleManager.instance.registerComponent(chartTitleLabel, "text", () -> LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.profile.stats.history"), LocaleUtils.resolveText(kindName)));
        peakLabel.text = "";
        chart.hidden = true;
        chartStatus.showLoading();
        chartStatus.hidden = false;
        onKindPicked(kind);
    }

    private function createHeader():HBox
    {
        var header:HBox = new HBox();
        header.percentWidth = 100;
        header.addClass(StyleClass.PROFILE_STATS_HEADER);

        var spacer:Box = new Box();
        spacer.percentWidth = 100;
        header.addComponent(spacer);

        var gamesGroup:VBox = new VBox();
        gamesGroup.addClass(StyleClass.PROFILE_STATS_GAMES_GROUP);
        gamesGroup.verticalAlign = "bottom";
        header.addComponent(gamesGroup);

        var gamesLabel:Label = new Label();
        gamesLabel.text = LocaleUtils.localeBinding("intellector.profile.stats.games");
        gamesLabel.percentWidth = 100;
        gamesLabel.addClass(StyleClass.PROFILE_STATS_HEADING);
        gamesLabel.addClass(StyleClass.PROFILE_STATS_GAMES_HEADING);
        gamesGroup.addComponent(gamesLabel);

        var subheadings:HBox = new HBox();
        subheadings.addClass(StyleClass.PROFILE_STATS_COLUMNS);
        gamesGroup.addComponent(subheadings);
        subheadings.addComponent(createHeading("intellector.profile.stats.total", StyleClass.PROFILE_STATS_TOTAL_CELL));
        subheadings.addComponent(createHeading("intellector.profile.stats.rated", StyleClass.PROFILE_STATS_RATED_CELL));

        var ratingHeading:Label = createHeading("intellector.profile.stats.elo", StyleClass.PROFILE_STATS_RATING_CELL);
        ratingHeading.verticalAlign = "bottom";
        header.addComponent(ratingHeading);

        return header;
    }

    private function createHeading(key:String, cellClass:StyleClass):Label
    {
        var heading:Label = new Label();
        heading.text = LocaleUtils.localeBinding(key);
        heading.addClass(StyleClass.PROFILE_STATS_HEADING);
        heading.addClass(cellClass);
        return heading;
    }

    private function createRow(kindStats:KindStats):HBox
    {
        var selectable:Bool = kindStats.hasRating();

        var row:HBox = new HBox();
        row.percentWidth = 100;
        row.addClass(StyleClass.PROFILE_STATS_ROW);
        row.setClass(StyleClass.PROFILE_STATS_ROW_DISABLED, !selectable);
        if (selectable)
        {
            row.trackHover();
            row.registerEvent(MouseEvent.CLICK, _ -> {
                if (selectedKind != kindStats.kind)
                    selectKind(kindStats.kind);
            });
        }
        else
            row.tooltip = LocaleUtils.localeBinding(kindStats.totalGames > 0 ? "intellector.profile.stats.tip_no_rated" : "intellector.profile.stats.tip_no_games");

        var nameCell:HBox = new HBox();
        nameCell.percentWidth = 100;
        nameCell.addClass(StyleClass.PROFILE_STATS_NAME_CELL);
        nameCell.verticalAlign = "center";
        row.addComponent(nameCell);

        nameCell.addComponent(new TimeControlKindIcon(kindStats.kind));

        var nameLabel:Label = new Label();
        nameLabel.text = LocaleUtils.localeBinding('intellector.common.time_control_kind.${kindStats.kind.getName().toLowerCase()}');
        nameLabel.addClass(StyleClass.PROFILE_STATS_NAME);
        nameLabel.verticalAlign = "center";
        nameCell.addComponent(nameLabel);

        row.addComponent(createNumberCell(Std.string(kindStats.totalGames), StyleClass.PROFILE_STATS_TOTAL_CELL, StyleClass.PROFILE_STATS_COUNT));
        row.addComponent(createNumberCell(Std.string(kindStats.ratedGames), StyleClass.PROFILE_STATS_RATED_CELL, StyleClass.PROFILE_STATS_COUNT));
        var ratingText:String = kindStats.rating != null ? GameFormatters.bareRating(kindStats.rating) : "—";
        row.addComponent(createNumberCell(ratingText, StyleClass.PROFILE_STATS_RATING_CELL, StyleClass.PROFILE_STATS_RATING));

        return row;
    }

    private function createNumberCell(text:String, cellClass:StyleClass, textClass:StyleClass):Label
    {
        var cell:Label = new Label();
        cell.text = text;
        cell.addClass(cellClass);
        cell.addClass(textClass);
        cell.verticalAlign = "center";
        return cell;
    }
}
