package client.ui.profile;

import client.ServerTime;
import client.datatypes.game.GameEnding;
import client.datatypes.game.GameParticipant;
import client.datatypes.game.GameRecord;
import client.formatters.GameFormatters;
import client.formatters.ProfileFormatters;
import client.formatters.TimeControlFormatters;
import client.ui.common.TimeControlKindIcon;
import client.ui.common.WidthObserver;
import client.ui.common.board.BoardPreview;
import client.utils.PagePaths;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;
import haxefolio.PageLink;
import intellectorboard.primitives.piece.PieceColor;
import morestd.Detachable;

using client.ui.ComponentExtension;

private enum TableTier
{
    SixColumns;
    FourColumns; // the start, time control and type stacked into one column
    Stacked; // a summary line, the players and the result beside the board
}

/**
    A page of the player's past games, each row with its final position, laid out by the table's
    own width. Rows open the game.
**/
class PastGamesTable extends VBox
{
    private static inline final SIX_COLUMNS_MIN_WIDTH:Float = 760;
    private static inline final FOUR_COLUMNS_MIN_WIDTH:Float = 540;
    private static inline final BOARD_WIDTH:Float = 104;

    private final login:String;

    private final header:HBox;
    private final rowList:VBox;
    private final widthHandle:Detachable;

    private var games:Array<GameRecord> = [];
    private var tier:TableTier = SixColumns;

    /** `login`: the profile's player, whose results the rows tell **/
    public function new(login:String)
    {
        super();
        this.login = login;
        percentWidth = 100;
        addClass(StyleClass.PAST_GAMES_TABLE);

        header = new HBox();
        header.percentWidth = 100;
        header.addClass(StyleClass.PAST_GAMES_HEADER);
        addComponent(header);

        rowList = new VBox();
        rowList.percentWidth = 100;
        rowList.addClass(StyleClass.PAST_GAMES_ROWS);
        addComponent(rowList);

        widthHandle = WidthObserver.observe(this, width -> {
            var newTier:TableTier = width >= SIX_COLUMNS_MIN_WIDTH ? SixColumns : width >= FOUR_COLUMNS_MIN_WIDTH ? FourColumns : Stacked;
            if (newTier != tier)
            {
                tier = newTier;
                render();
            }
        });

        render();
    }

    public function setGames(games:Array<GameRecord>):Void
    {
        this.games = games;
        render();
    }

    public function dispose():Void
    {
        widthHandle.detach();
    }

    private function render():Void
    {
        renderHeader();

        rowList.removeAllComponents();
        for (game in games)
            rowList.addComponent(createRow(game));
    }

    private function renderHeader():Void
    {
        header.removeAllComponents();
        header.hidden = tier == Stacked;
        if (tier == Stacked)
            return;

        header.addComponent(sized(new Box(), BOARD_WIDTH));
        switch tier
        {
            case SixColumns:
                header.addComponent(headingCell("started", StyleClass.PAST_GAMES_DATE_CELL));
                header.addComponent(headingCell("time_control", StyleClass.PAST_GAMES_TIME_CONTROL_CELL));
                header.addComponent(headingCell("type", StyleClass.PAST_GAMES_TYPE_CELL));
            default:
                header.addComponent(headingCell("started", StyleClass.PAST_GAMES_STACK_CELL));
        }
        var playersHeading:Label = headingCell("players", StyleClass.PAST_GAMES_PLAYERS_CELL);
        playersHeading.percentWidth = 100;
        header.addComponent(playersHeading);
        header.addComponent(headingCell("result", tier == SixColumns ? StyleClass.PAST_GAMES_RESULT_CELL : StyleClass.PAST_GAMES_NARROW_RESULT_CELL));
    }

    private function headingCell(key:String, cellClass:StyleClass):Label
    {
        var heading:Label = new Label();
        heading.text = LocaleUtils.localeBinding('intellector.profile.past.column.$key');
        heading.addClass(StyleClass.PAST_GAMES_HEADING);
        heading.addClass(cellClass);
        heading.verticalAlign = "center";
        return heading;
    }

    private function createRow(game:GameRecord):HBox
    {
        var ownColor:PieceColor = game.colorOf(login) ?? White;

        var row:HBox = new HBox();
        row.percentWidth = 100;
        row.addClass(StyleClass.PAST_GAMES_ROW);
        row.trackHover();
        PageLink.attach(row, PagePaths.liveGame(game.id));

        row.addComponent(new BoardPreview(game.position, ownColor, BOARD_WIDTH));

        switch tier
        {
            case SixColumns:
                row.addComponent(dateCell(game, StyleClass.PAST_GAMES_DATE_CELL));
                row.addComponent(timeControlCell(game, StyleClass.PAST_GAMES_TIME_CONTROL_CELL));
                row.addComponent(typeLabel(game, StyleClass.PAST_GAMES_TYPE_CELL));
                row.addComponent(playersCell(game));
                row.addComponent(resultCell(game, ownColor, StyleClass.PAST_GAMES_RESULT_CELL));
            case FourColumns:
                var stack:VBox = new VBox();
                stack.addClass(StyleClass.PAST_GAMES_STACK_CELL);
                stack.addClass(StyleClass.PAST_GAMES_STACK);
                stack.verticalAlign = "center";
                stack.addComponent(dateCell(game, null));
                stack.addComponent(timeControlCell(game, null));
                stack.addComponent(typeLabel(game, null));
                row.addComponent(stack);
                row.addComponent(playersCell(game));
                row.addComponent(resultCell(game, ownColor, StyleClass.PAST_GAMES_NARROW_RESULT_CELL));
            case Stacked:
                var column:VBox = new VBox();
                column.percentWidth = 100;
                column.addClass(StyleClass.PAST_GAMES_MOBILE_COLUMN);
                column.verticalAlign = "center";

                var summaryLabel:Label = new Label();
                summaryLabel.addClass(StyleClass.PROFILE_SMALL_MUTED);
                LocaleManager.instance.registerComponent(summaryLabel, "text", () -> summaryText(game));
                column.addComponent(summaryLabel);

                column.addComponent(playersCell(game));
                column.addComponent(resultCell(game, ownColor, null));
                row.addComponent(column);
        }

        return row;
    }

    private function dateCell(game:GameRecord, cellClass:Null<StyleClass>):VBox
    {
        var cell:VBox = new VBox();
        cell.addClass(StyleClass.PAST_GAMES_DATE);
        if (cellClass != null)
            cell.addClass(cellClass);
        cell.verticalAlign = "center";

        var dateLabel:Label = new Label();
        dateLabel.addClass(StyleClass.PROFILE_TEXT);
        var startedAtMs:Null<Float> = game.startedAtMs;
        if (startedAtMs == null)
        {
            dateLabel.percentWidth = 100;
            dateLabel.wordWrap = true;
            dateLabel.text = LocaleUtils.localeBinding("intellector.common.date_unknown");
            cell.addComponent(dateLabel);
            return cell;
        }

        LocaleManager.instance.registerComponent(dateLabel, "text", () -> ProfileFormatters.shortDate(startedAtMs, ServerTime.now()));
        cell.addComponent(dateLabel);

        var timeLabel:Label = new Label();
        timeLabel.text = ProfileFormatters.timeOfDay(startedAtMs);
        timeLabel.addClass(StyleClass.PROFILE_SMALL_MUTED);
        cell.addComponent(timeLabel);

        return cell;
    }

    private function timeControlCell(game:GameRecord, cellClass:Null<StyleClass>):HBox
    {
        var cell:HBox = new HBox();
        cell.addClass(StyleClass.PAST_GAMES_TIME_CONTROL);
        if (cellClass != null)
            cell.addClass(cellClass);
        cell.verticalAlign = "center";

        cell.addComponent(new TimeControlKindIcon(game.timeControl.getKind()));

        var timed:Bool = !game.timeControl.match(None);
        var valueLabel:Label = new Label();
        valueLabel.text = timed ? TimeControlFormatters.formatTimeControl(game.timeControl) : LocaleUtils.localeBinding("intellector.common.no_clock");
        valueLabel.addClass(timed ? StyleClass.PROFILE_MONO : StyleClass.PROFILE_TEXT);
        valueLabel.verticalAlign = "center";
        cell.addComponent(valueLabel);

        return cell;
    }

    private function typeLabel(game:GameRecord, cellClass:Null<StyleClass>):Label
    {
        var label:Label = new Label();
        label.text = LocaleUtils.localeBinding(game.rated ? "intellector.common.game_type.rated" : "intellector.common.game_type.casual");
        label.addClass(StyleClass.PROFILE_MUTED);
        if (cellClass != null)
            label.addClass(cellClass);
        label.verticalAlign = "center";
        return label;
    }

    private function playersCell(game:GameRecord):VBox
    {
        var winner:Null<PieceColor> = winnerOf(game.ending);

        var cell:VBox = new VBox();
        cell.percentWidth = 100;
        cell.addClass(StyleClass.PAST_GAMES_PLAYERS);
        cell.verticalAlign = "center";
        cell.addComponent(playerLine(game.white, White, winner == White));
        cell.addComponent(playerLine(game.black, Black, winner == Black));
        return cell;
    }

    private function playerLine(participant:GameParticipant, color:PieceColor, winner:Bool):HBox
    {
        var line:HBox = new HBox();
        line.addClass(StyleClass.GAME_RECORD_LINE);

        var colorDot:Box = new Box();
        colorDot.addClass(color == White ? StyleClass.GAME_RECORD_WHITE_DOT : StyleClass.GAME_RECORD_BLACK_DOT);
        colorDot.verticalAlign = "center";
        line.addComponent(colorDot);

        var nicknameLabel:Label = new Label();
        nicknameLabel.text = participant.nickname;
        nicknameLabel.addClass(StyleClass.GAME_RECORD_TEXT);
        nicknameLabel.setClass(StyleClass.GAME_RECORD_WINNER, winner);
        nicknameLabel.verticalAlign = "center";
        line.addComponent(nicknameLabel);

        if (participant.rating != null)
        {
            var ratingLabel:Label = new Label();
            ratingLabel.text = GameFormatters.bareRating(participant.rating);
            ratingLabel.addClass(StyleClass.GAME_RECORD_RATING);
            ratingLabel.verticalAlign = "center";
            line.addComponent(ratingLabel);
        }

        return line;
    }

    private function resultCell(game:GameRecord, ownColor:PieceColor, cellClass:Null<StyleClass>):VBox
    {
        var cell:VBox = new VBox();
        cell.addClass(StyleClass.PAST_GAMES_RESULT);
        if (cellClass != null)
            cell.addClass(cellClass);
        cell.verticalAlign = "center";

        var outcomeLabel:Label = new Label();
        outcomeLabel.text = outcomeText(game.ending, ownColor);
        outcomeLabel.addClass(StyleClass.PAST_GAMES_OUTCOME);
        cell.addComponent(outcomeLabel);

        var reasonLabel:Label = new Label();
        reasonLabel.addClass(StyleClass.PROFILE_SMALL_MUTED);
        LocaleManager.instance.registerComponent(reasonLabel, "text", () -> reasonText(game.ending));
        cell.addComponent(reasonLabel);

        return cell;
    }

    private function summaryText(game:GameRecord):String
    {
        var timeControl:String = game.timeControl.match(None)
            ? LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.common.no_clock"))
            : TimeControlFormatters.formatTimeControl(game.timeControl);
        var type:String = LocaleUtils.resolveText(LocaleUtils.localeBinding(game.rated ? "intellector.common.game_type.rated" : "intellector.common.game_type.casual"));
        var startedAtMs:Null<Float> = game.startedAtMs;
        var start:String = startedAtMs != null
            ? '${ProfileFormatters.shortDate(startedAtMs, ServerTime.now())} ${ProfileFormatters.timeOfDay(startedAtMs)}'
            : LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.common.date_unknown"));
        return '$start · $timeControl · $type';
    }

    /** A locale binding: won, lost or drawn, for the player **/
    private static function outcomeText(ending:Null<GameEnding>, ownColor:PieceColor):String
    {
        var winner:Null<PieceColor> = winnerOf(ending);
        var aborted:Bool = ending != null && ending.outcome.match(Drawish(Abort));
        var key:String = aborted ? "aborted" : winner == null ? "draw" : winner == ownColor ? "won" : "lost";
        return LocaleUtils.localeBinding('intellector.profile.past.outcome.$key');
    }

    private static function reasonText(ending:Null<GameEnding>):String
    {
        if (ending == null)
            return "";

        return switch ending.outcome {
            case Decisive(kind, winner):
                var key:String = 'intellector.profile.past.reason.${GameFormatters.snakeCase(kind.getName())}';
                LocaleUtils.resolveText(LocaleUtils.localeBinding(key), GameFormatters.colorName(winner), GameFormatters.colorName(winner.opposite()));
            case Drawish(Abort):
                "";
            case Drawish(kind):
                LocaleUtils.resolveText(LocaleUtils.localeBinding('intellector.profile.past.reason.${GameFormatters.snakeCase(kind.getName())}'));
        }
    }

    private static function winnerOf(ending:Null<GameEnding>):Null<PieceColor>
    {
        if (ending == null)
            return null;
        return switch ending.outcome {
            case Decisive(_, winner): winner;
            case Drawish(_): null;
        }
    }

    private static function sized(box:Box, width:Float):Box
    {
        box.width = width;
        return box;
    }
}
