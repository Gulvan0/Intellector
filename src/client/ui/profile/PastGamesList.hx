package client.ui.profile;

import client.datatypes.game.GameEnding;
import client.datatypes.game.GameParticipant;
import client.datatypes.game.GameRecord;
import client.formatters.GameFormatters;
import client.formatters.ProfileFormatters;
import client.formatters.TimeControlFormatters;
import client.ui.common.TimeControlKindIcon;
import client.ui.common.board.BoardPreview;
import client.utils.PagePaths;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;
import haxefolio.PageLink;
import intellectorboard.primitives.piece.PieceColor;

using client.ui.ComponentExtension;

/**
    A page of the player's past games, one row each with its final position, newest first.
    Rows open the game. The owner picks the wide or the narrow row layout.
**/
class PastGamesList extends VBox
{
    public static inline final WIDE_ROW_HEIGHT:Float = 168;
    public static inline final NARROW_ROW_HEIGHT:Float = 176;

    private static inline final WIDE_BOARD_WIDTH:Float = 160;
    private static inline final NARROW_BOARD_WIDTH:Float = 132;

    private final login:String;

    private var games:Array<GameRecord> = [];
    private var narrow:Bool = false;

    /** `login`: the profile's player, whose results the rows tell **/
    public function new(login:String)
    {
        super();
        this.login = login;
        percentWidth = 100;
        addClass(StyleClass.PAST_GAMES_LIST);
    }

    public function setGames(games:Array<GameRecord>):Void
    {
        this.games = games;
        render();
    }

    public function setNarrow(narrow:Bool):Void
    {
        if (narrow == this.narrow)
            return;
        this.narrow = narrow;
        render();
    }

    private function render():Void
    {
        removeAllComponents();
        for (game in games)
            addComponent(narrow ? createNarrowRow(game) : createWideRow(game));
    }

    private function createWideRow(game:GameRecord):HBox
    {
        var row:HBox = new HBox();
        row.addClass(StyleClass.PAST_GAMES_WIDE_ROW);
        attachLink(row, game);

        var board:BoardPreview = new BoardPreview(game.position, orientationOf(game), WIDE_BOARD_WIDTH);
        board.verticalAlign = "center";
        row.addComponent(board);

        var column:VBox = new VBox();
        column.percentWidth = 100;
        column.addClass(StyleClass.PAST_GAMES_WIDE_TEXT);
        column.verticalAlign = "center";
        row.addComponent(column);

        var metaLine:HBox = createLine();
        metaLine.addComponent(new TimeControlKindIcon(game.timeControl.getKind()));
        metaLine.addComponent(timeControlLabel(game));
        metaLine.addComponent(separator());
        var ratedLabel:Label = mutedLabel();
        ratedLabel.text = LocaleUtils.localeBinding(game.rated ? "intellector.common.game_type.rated" : "intellector.common.game_type.casual");
        metaLine.addComponent(ratedLabel);
        metaLine.addComponent(separator());
        metaLine.addComponent(dateLabel(game));
        column.addComponent(metaLine);

        column.addComponent(playersBlock(game, false));

        var resultLine:HBox = createLine();
        resultLine.addComponent(outcomeLabel(game));
        if (hasReason(game.ending))
        {
            resultLine.addComponent(separator());
            var reasonLabel:Label = mutedLabel();
            registerReason(reasonLabel, game.ending);
            resultLine.addComponent(reasonLabel);
        }
        column.addComponent(resultLine);

        return row;
    }

    /** The players and the result are pinned to the board's top edge, so a wrapped reason grows downward **/
    private function createNarrowRow(game:GameRecord):VBox
    {
        var row:VBox = new VBox();
        row.addClass(StyleClass.PAST_GAMES_NARROW_ROW);
        attachLink(row, game);

        var topLine:HBox = createLine();
        topLine.percentWidth = 100;
        topLine.addClass(StyleClass.PAST_GAMES_TOP_LINE);
        var timeControlGroup:HBox = createLine();
        timeControlGroup.addComponent(new TimeControlKindIcon(game.timeControl.getKind()));
        timeControlGroup.addComponent(timeControlLabel(game));
        topLine.addComponent(timeControlGroup);
        var spacer:Box = new Box();
        spacer.percentWidth = 100;
        topLine.addComponent(spacer);
        topLine.addComponent(dateLabel(game));
        row.addComponent(topLine);

        var body:HBox = new HBox();
        body.percentWidth = 100;
        body.addClass(StyleClass.PAST_GAMES_NARROW_BODY);
        row.addComponent(body);

        body.addComponent(new BoardPreview(game.position, orientationOf(game), NARROW_BOARD_WIDTH));

        var column:VBox = new VBox();
        column.percentWidth = 100;
        column.addClass(StyleClass.PAST_GAMES_NARROW_TEXT);
        body.addComponent(column);

        column.addComponent(playersBlock(game, true));

        var result:VBox = new VBox();
        result.percentWidth = 100;
        result.addClass(StyleClass.PAST_GAMES_NARROW_RESULT);
        result.addComponent(outcomeLabel(game));
        if (hasReason(game.ending))
        {
            var reasonLabel:Label = new Label();
            reasonLabel.percentWidth = 100;
            reasonLabel.addClass(StyleClass.PAST_GAMES_WRAPPING_REASON);
            registerReason(reasonLabel, game.ending);
            result.addComponent(reasonLabel);
        }
        column.addComponent(result);

        return row;
    }

    private function attachLink(row:Component, game:GameRecord):Void
    {
        row.percentWidth = 100;
        row.addClass(StyleClass.PAST_GAMES_ROW);
        row.trackHover();
        PageLink.attach(row, PagePaths.liveGame(game.id));
    }

    private function createLine():HBox
    {
        var line:HBox = new HBox();
        line.addClass(StyleClass.PAST_GAMES_LINE);
        return line;
    }

    /** Correspondence names its kind instead of a time control **/
    private function timeControlLabel(game:GameRecord):Label
    {
        var timed:Bool = !game.timeControl.match(None);
        var label:Label = new Label();
        label.text = timed ? TimeControlFormatters.formatTimeControl(game.timeControl) : LocaleUtils.localeBinding("intellector.common.time_control_kind.correspondence");
        label.addClass(timed ? StyleClass.GAME_RECORD_MONO : StyleClass.GAME_RECORD_TEXT);
        label.verticalAlign = "center";
        return label;
    }

    private function dateLabel(game:GameRecord):Label
    {
        var label:Label = mutedLabel();
        var startedAtMs:Null<Float> = game.startedAtMs;
        if (startedAtMs == null)
            label.text = LocaleUtils.localeBinding("intellector.common.date_unknown");
        else
            LocaleManager.instance.registerComponent(label, "text", () -> '${ProfileFormatters.longDate(startedAtMs)}, ${ProfileFormatters.timeOfDay(startedAtMs)}');
        return label;
    }

    private function separator():Label
    {
        var label:Label = new Label();
        label.text = "·";
        label.addClass(StyleClass.PAST_GAMES_SEPARATOR);
        label.verticalAlign = "center";
        return label;
    }

    private function mutedLabel():Label
    {
        var label:Label = new Label();
        label.addClass(StyleClass.GAME_RECORD_MUTED);
        label.verticalAlign = "center";
        return label;
    }

    private function playersBlock(game:GameRecord, narrow:Bool):VBox
    {
        var winner:Null<PieceColor> = winnerOf(game.ending);
        var block:VBox = new VBox();
        block.percentWidth = 100;
        block.addClass(StyleClass.PAST_GAMES_PLAYERS);
        block.addComponent(playerLine(game.white, White, game.rated, winner == White, narrow));
        block.addComponent(playerLine(game.black, Black, game.rated, winner == Black, narrow));
        return block;
    }

    private function playerLine(participant:GameParticipant, color:PieceColor, rated:Bool, winner:Bool, narrow:Bool):HBox
    {
        var line:HBox = new HBox();
        line.percentWidth = 100;
        line.addClass(narrow ? StyleClass.PAST_GAMES_NARROW_PLAYER_LINE : StyleClass.PAST_GAMES_WIDE_PLAYER_LINE);

        var colorDot:Box = new Box();
        colorDot.addClass(color == White ? StyleClass.GAME_RECORD_WHITE_DOT : StyleClass.GAME_RECORD_BLACK_DOT);
        colorDot.verticalAlign = "center";
        line.addComponent(colorDot);

        var nicknameLabel:Label = new Label();
        nicknameLabel.text = participant.nickname;
        nicknameLabel.addClass(narrow ? StyleClass.PAST_GAMES_NARROW_NICKNAME : StyleClass.PAST_GAMES_WIDE_NICKNAME);
        nicknameLabel.setClass(StyleClass.PAST_GAMES_WINNER, winner);
        nicknameLabel.verticalAlign = "center";
        line.addComponent(nicknameLabel);

        if (rated && participant.rating != null)
        {
            var ratingLabel:Label = new Label();
            ratingLabel.text = GameFormatters.bareRating(participant.rating);
            ratingLabel.addClass(StyleClass.GAME_RECORD_RATING);
            ratingLabel.verticalAlign = "center";
            line.addComponent(ratingLabel);
        }

        return line;
    }

    private function outcomeLabel(game:GameRecord):Label
    {
        var label:Label = new Label();
        label.text = outcomeText(game.ending, orientationOf(game));
        label.addClass(StyleClass.PAST_GAMES_OUTCOME);
        label.verticalAlign = "center";
        return label;
    }

    private function registerReason(label:Label, ending:Null<GameEnding>):Void
    {
        LocaleManager.instance.registerComponent(label, "text", () -> reasonText(ending));
    }

    private function orientationOf(game:GameRecord):PieceColor
    {
        return game.colorOf(login) ?? White;
    }

    /** A locale binding: won, lost or drawn, for the player **/
    private static function outcomeText(ending:Null<GameEnding>, ownColor:PieceColor):String
    {
        var winner:Null<PieceColor> = winnerOf(ending);
        var aborted:Bool = ending != null && ending.outcome.match(Drawish(Abort));
        var key:String = aborted ? "aborted" : winner == null ? "draw" : winner == ownColor ? "won" : "lost";
        return LocaleUtils.localeBinding('intellector.profile.past.outcome.$key');
    }

    private static function hasReason(ending:Null<GameEnding>):Bool
    {
        return ending != null && !ending.outcome.match(Drawish(Abort));
    }

    private static function reasonText(ending:Null<GameEnding>):String
    {
        if (!hasReason(ending))
            return "";

        return switch ending.outcome {
            case Decisive(kind, winner):
                var key:String = 'intellector.profile.past.reason.${GameFormatters.snakeCase(kind.getName())}';
                LocaleUtils.resolveText(LocaleUtils.localeBinding(key), GameFormatters.colorName(winner), GameFormatters.colorName(winner.opposite()));
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
}
