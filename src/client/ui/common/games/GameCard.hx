package client.ui.common.games;

import client.datatypes.game.GameParticipant;
import client.datatypes.game.GameRecord;
import client.formatters.GameFormatters;
import client.formatters.TimeControlFormatters;
import client.ui.common.TimeControlKindIcon;
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

using client.ui.ComponentExtension;

/**
    A game as a card: its position, time control and rated status (correspondence leaves the latter
    out, as it wouldn't fit beside the kind name), players and two lines of status under them,
    which the owner supplies (the result and how it came about, or whose move it is and when the
    last one was made). It links to the game anywhere.
**/
class GameCard extends HBox
{
    private static inline final BOARD_WIDTH:Float = 132;

    public var game(default, null):GameRecord;

    private final link:PageLink;
    private final board:BoardPreview;
    private final kindIcon:TimeControlKindIcon;
    private final timeControlLabel:Label;
    private final ratedLabel:Label;
    private final whiteRow:PlayerLine;
    private final blackRow:PlayerLine;
    private final statusLabel:Label;
    private final detailLabel:Label;

    public function new(game:GameRecord, orientation:PieceColor)
    {
        super();
        this.game = game;
        percentWidth = 100;
        addClass(StyleClass.GAME_RECORD_CARD);
        this.trackHover();
        link = PageLink.attach(this, null);

        board = new BoardPreview(game.position, orientation, BOARD_WIDTH);
        addComponent(board);

        var column:VBox = new VBox();
        column.percentWidth = 100;
        column.percentHeight = 100;
        column.addClass(StyleClass.GAME_RECORD_CARD_COLUMN);
        addComponent(column);

        var headRow:HBox = new HBox();
        headRow.addClass(StyleClass.GAME_RECORD_LINE);
        column.addComponent(headRow);

        kindIcon = new TimeControlKindIcon(game.timeControl.getKind());
        headRow.addComponent(kindIcon);

        timeControlLabel = new Label();
        timeControlLabel.verticalAlign = "center";
        headRow.addComponent(timeControlLabel);

        ratedLabel = new Label();
        ratedLabel.addClass(StyleClass.GAME_RECORD_MUTED);
        ratedLabel.verticalAlign = "center";
        headRow.addComponent(ratedLabel);

        whiteRow = new PlayerLine(White);
        column.addComponent(whiteRow);
        blackRow = new PlayerLine(Black);
        column.addComponent(blackRow);

        var spacer:Box = new Box();
        spacer.percentHeight = 100;
        column.addComponent(spacer);

        statusLabel = new Label();
        statusLabel.addClass(StyleClass.GAME_RECORD_STATUS);
        column.addComponent(statusLabel);

        detailLabel = new Label();
        detailLabel.addClass(StyleClass.GAME_RECORD_DETAIL);
        column.addComponent(detailLabel);

        setGame(game, null);
    }

    /** `winner`, if any, is emphasised **/
    public function setGame(game:GameRecord, winner:Null<PieceColor>):Void
    {
        this.game = game;
        link.setPath(PagePaths.liveGame(game.id));
        board.setPosition(game.position);
        kindIcon.setKind(game.timeControl.getKind());

        var timed:Bool = !game.timeControl.match(None);
        timeControlLabel.text = timed ? TimeControlFormatters.formatTimeControl(game.timeControl) : LocaleUtils.localeBinding("intellector.common.time_control_kind.correspondence");
        timeControlLabel.setClass(StyleClass.GAME_RECORD_MONO, timed);
        timeControlLabel.setClass(StyleClass.GAME_RECORD_TEXT, !timed);
        ratedLabel.text = LocaleUtils.localeBinding(game.rated ? "intellector.common.game_type.rated" : "intellector.common.game_type.casual");
        ratedLabel.hidden = !timed;

        whiteRow.setParticipant(game.white, game.rated, winner == White);
        blackRow.setParticipant(game.black, game.rated, winner == Black);
    }

    /** The two lines under the players, re-resolved on a language switch **/
    public function setStatus(status:Void->String, detail:Void->String):Void
    {
        LocaleManager.instance.registerComponent(statusLabel, "text", status);
        LocaleManager.instance.registerComponent(detailLabel, "text", detail);
    }
}

/** A player of a game card: the colour, the nickname, and the rating in a rated game **/
private class PlayerLine extends HBox
{
    private final nicknameLabel:Label;
    private final ratingLabel:Label;

    public function new(color:PieceColor)
    {
        super();
        addClass(StyleClass.GAME_RECORD_LINE);

        var colorDot:Box = new Box();
        colorDot.addClass(color == White ? StyleClass.GAME_RECORD_WHITE_DOT : StyleClass.GAME_RECORD_BLACK_DOT);
        colorDot.verticalAlign = "center";
        addComponent(colorDot);

        nicknameLabel = new Label();
        nicknameLabel.addClass(StyleClass.GAME_RECORD_TEXT);
        nicknameLabel.verticalAlign = "center";
        addComponent(nicknameLabel);

        ratingLabel = new Label();
        ratingLabel.addClass(StyleClass.GAME_RECORD_RATING);
        ratingLabel.verticalAlign = "center";
        addComponent(ratingLabel);
    }

    public function setParticipant(participant:GameParticipant, showRating:Bool, winner:Bool):Void
    {
        nicknameLabel.text = participant.nickname;
        nicknameLabel.setClass(StyleClass.GAME_RECORD_WINNER, winner);
        ratingLabel.hidden = !showRating || participant.rating == null;
        if (participant.rating != null)
            ratingLabel.text = GameFormatters.bareRating(participant.rating);
    }
}
