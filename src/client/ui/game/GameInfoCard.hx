package client.ui.game;

import client.GroupedLocaleResolvers;
import client.datatypes.game.GameEnding;
import client.datatypes.game.GameParticipant;
import client.datatypes.game.LiveGameInfo;
import client.formatters.GameFormatters;
import client.openings.OpeningEntry;
import client.ui.Assets;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;
import intellectorboard.primitives.piece.PieceColor;

using client.ui.ComponentExtension;

/** The game's facts: time control, start, resolution, players and opening **/
class GameInfoCard extends VBox
{
    private final timeControlIcon:Image;
    private final timeControlLabel:Label;
    private final ratedLabel:Label;
    private final startedAtLabel:Label;
    private final resolutionLabel:Label;
    private final whiteRow:HBox;
    private final blackRow:HBox;
    private final whiteDot:Box;
    private final blackDot:Box;
    private final openingLabel:Label;
    private final onNicknameClicked:GameParticipant->Void;

    private var info:Null<LiveGameInfo> = null;
    private var ending:Null<GameEnding> = null;
    private var opening:Null<OpeningEntry> = null;

    public function new(onNicknameClicked:GameParticipant->Void)
    {
        super();
        this.onNicknameClicked = onNicknameClicked;
        percentWidth = 100;
        addClass(StyleClass.GAME_CARD);
        addClass(StyleClass.GAME_INFO_CARD);

        var headRow:HBox = new HBox();
        headRow.percentWidth = 100;
        addComponent(headRow);

        timeControlIcon = new Image();
        timeControlIcon.width = 28;
        timeControlIcon.height = 28;
        timeControlIcon.scaleMode = "fitinside";
        timeControlIcon.verticalAlign = "center";
        headRow.addComponent(timeControlIcon);

        var timeControlColumn:VBox = new VBox();
        timeControlColumn.addClass(StyleClass.GAME_TIGHT_STACK);
        timeControlColumn.percentWidth = 100;
        timeControlColumn.verticalAlign = "center";
        headRow.addComponent(timeControlColumn);

        timeControlLabel = new Label();
        timeControlLabel.addClass(StyleClass.GAME_MONO);
        timeControlLabel.percentWidth = 100;
        timeControlLabel.wordWrap = true; // a long one ("15s+0 · Hyperbullet") would run under the start date
        timeControlColumn.addComponent(timeControlLabel);

        ratedLabel = new Label();
        ratedLabel.addClass(StyleClass.GAME_HINT);
        timeControlColumn.addComponent(ratedLabel);

        startedAtLabel = new Label();
        startedAtLabel.addClass(StyleClass.GAME_HINT);
        startedAtLabel.verticalAlign = "center";
        headRow.addComponent(startedAtLabel);

        resolutionLabel = new Label();
        resolutionLabel.percentWidth = 100;
        resolutionLabel.addClass(StyleClass.GAME_RESOLUTION);
        addComponent(resolutionLabel);

        var playersBox:VBox = new VBox();
        playersBox.percentWidth = 100;
        playersBox.addClass(StyleClass.GAME_PLAYERS_BOX);
        addComponent(playersBox);

        whiteDot = PlayerBar.createPresenceDot();
        whiteRow = createPlayerRow(whiteDot, White);
        playersBox.addComponent(whiteRow);

        blackDot = PlayerBar.createPresenceDot();
        blackRow = createPlayerRow(blackDot, Black);
        playersBox.addComponent(blackRow);

        openingLabel = new Label();
        openingLabel.percentWidth = 100;
        openingLabel.addClass(StyleClass.GAME_OPENING);
        addComponent(openingLabel);
    }

    public function setInfo(info:LiveGameInfo):Void
    {
        this.info = info;

        var kindIconPath:String = Assets.timeControlKindIcon(info.timeControl.getKind());
        timeControlIcon.resource = kindIconPath;
        LocaleManager.instance.registerComponent(timeControlLabel, "text", () -> GameFormatters.timeControl(info.timeControl));
        ratedLabel.text = GroupedLocaleResolvers.challengeRated(info.rated);
        startedAtLabel.text = GameFormatters.optionalDateTime(info.startedAtMs);

        fillPlayerRow(whiteRow, info.white);
        fillPlayerRow(blackRow, info.black);
        refreshOpening();
        refreshResolution();
    }

    public function setEnding(ending:Null<GameEnding>):Void
    {
        this.ending = ending;
        refreshResolution();
    }

    public function setPresent(color:PieceColor, present:Bool):Void
    {
        PlayerBar.setPresence(color == White ? whiteDot : blackDot, present);
    }

    /** Null before any known opening position, and for a custom starting position **/
    public function setOpening(opening:Null<OpeningEntry>):Void
    {
        this.opening = opening;
        refreshOpening();
    }

    private function refreshResolution():Void
    {
        LocaleManager.instance.registerComponent(resolutionLabel, "text", () -> GameFormatters.resolution(ending));
    }

    private function refreshOpening():Void
    {
        var openingText:Null<Void->String> = GameFormatters.opening(opening, info != null && info.customStartingPosition);
        openingLabel.hidden = openingText == null;
        if (openingText != null)
            LocaleManager.instance.registerComponent(openingLabel, "text", openingText);
    }

    private function createPlayerRow(dot:Box, color:PieceColor):HBox
    {
        var row:HBox = new HBox();
        row.percentWidth = 100;
        row.addClass(StyleClass.GAME_PLAYER_ROW);
        row.addComponent(dot);

        var nicknameLabel:Label = new Label();
        nicknameLabel.id = "nickname";
        nicknameLabel.addClass(StyleClass.GAME_NICKNAME);
        nicknameLabel.verticalAlign = "center";
        nicknameLabel.onClick = _ -> {
            if (info != null)
                onNicknameClicked(info.participant(color));
        };
        nicknameLabel.trackHover();
        row.addComponent(nicknameLabel);

        var ratingLabel:Label = new Label();
        ratingLabel.id = "rating";
        ratingLabel.addClass(StyleClass.GAME_RATING);
        ratingLabel.verticalAlign = "center";
        row.addComponent(ratingLabel);

        var spacer:Box = new Box();
        spacer.percentWidth = 100;
        row.addComponent(spacer);

        var colorLabel:Label = new Label();
        colorLabel.addClass(StyleClass.GAME_HINT);
        colorLabel.verticalAlign = "center";
        colorLabel.text = LocaleUtils.localeBinding('intellector.common.color.${color.getName().toLowerCase()}');
        row.addComponent(colorLabel);

        return row;
    }

    private function fillPlayerRow(row:HBox, participant:GameParticipant):Void
    {
        var nicknameLabel:Label = row.findComponent("nickname", Label);
        nicknameLabel.text = participant.nickname;
        if (PlayerBar.isPlayer(participant))
            nicknameLabel.addClass(StyleClass.GAME_NICKNAME_LINK);

        var ratingLabel:Label = row.findComponent("rating", Label);
        ratingLabel.text = GameFormatters.rating(participant.rating);
        ratingLabel.hidden = participant.rating == null;
    }
}
