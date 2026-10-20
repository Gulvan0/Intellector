package client.ui.common.games.widget;

import client.ServerTime;
import client.datatypes.game.GameClock;
import client.datatypes.game.OngoingGame;
import client.formatters.ClockFormatters;
import client.formatters.OngoingGameFormatters;
import client.ui.Assets;
import client.utils.PagePaths;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import haxefolio.PageLink;
import haxefolio.ResponsivityController;
import intellectorboard.primitives.piece.PieceColor;

using client.ui.ComponentExtension;

/** An ongoing game in the ongoing games widget's list **/
@:build(haxe.ui.ComponentBuilder.build("assets/layouts/common/games/widget/ongoing_game_entry.xml"))
class OngoingGameEntry extends VBox
{
    public var game(default, null):OngoingGame;

    private final openLink:PageLink;
    private var current:Bool = false;

    /** Called with whether the Preview button became selected **/
    public var onPreviewToggled:Bool->Void = _ -> {};

    /**
        Laid out for the current breakpoint: rebuild it after a flip.
        `onFollowed` runs when the Open button is used to navigate in the app.
    **/
    public function new(game:OngoingGame, onFollowed:Void->Void)
    {
        super();

        footer.layoutName = ResponsivityController.isCollapsed ? "vertical" : "horizontal";
        turnMarker.element.setAttribute("role", "img");

        previewToggle.onChange = _ -> onPreviewToggled(previewToggle.selected);
        openLink = PageLink.attach(openButton, null, null, null, onFollowed);

        setGame(game);
        setCurrent(false);
    }

    public function setGame(game:OngoingGame):Void
    {
        this.game = game;
        refreshOpenLink();

        var ownMove:Bool = game.isOwnMove();
        turnMarker.setClass(StyleClass.GAME_ENTRY_TURN_OWN_TIMED, ownMove && game.isTimed());
        turnMarker.setClass(StyleClass.GAME_ENTRY_TURN_OWN_CORRESPONDENCE, ownMove && !game.isTimed());
        turnMarker.element.setAttribute("aria-label", LocaleUtils.resolveText(LocaleUtils.localeBinding(ownMove ? "intellector.games_widget.own_move" : "intellector.games_widget.opponent_move")));

        opponentLabel.text = game.opponentNickname;
        switch game.timeControl
        {
            case None:
                timeControlTag.hidden = true;
            case Fischer(instance):
                timeControlTag.hidden = false;
                timeControlTag.setTimeControl(game.timeControl, instance.getKind());
        }

        colorIcon.resource = Assets.colorIcon(game.ownColor);
        colorLabel.text = LocaleUtils.localeBinding('intellector.games_widget.color.${game.ownColor.getName().toLowerCase()}');
        ratedLabel.text = GroupedLocaleResolvers.challengeRated(game.rated);
        ratedLabel.setClass(StyleClass.GAME_ENTRY_FACT_EMPHASISED, game.rated);
        moveLabel.text = LocaleUtils.localeBinding("intellector.games_widget.move", Std.string(game.moveNumber()));

        clocks.hidden = game.clock == null;
        lastMoveLabel.hidden = game.clock != null;
        ownClockIcon.resource = Assets.colorIcon(game.ownColor);
        opponentClockIcon.resource = Assets.colorIcon(game.ownColor.opposite());

        updateTime(ServerTime.now());
    }

    /** Whether the game is the one open on the page: it can't be opened again **/
    public function setCurrent(current:Bool):Void
    {
        this.current = current;
        openButton.disabled = current;
        refreshOpenLink();
        openButton.text = LocaleUtils.localeBinding(current ? "intellector.games_widget.current_game" : "intellector.games_widget.open_game");
    }

    private function refreshOpenLink():Void
    {
        openLink.setPath(current ? null : PagePaths.liveGame(game.id));
    }

    public function setPreviewSelected(selected:Bool):Void
    {
        previewToggle.selected = selected;
    }

    /** Whether it's the first of its section, which has no hairline above it **/
    public function setFirst(first:Bool):Void
    {
        this.setClass(StyleClass.GAME_ENTRY_FIRST, first);
    }

    /** Whether it's the first one on the opponent's move after some on the user's: a stronger line above **/
    public function setGroupBoundary(boundary:Bool):Void
    {
        this.setClass(StyleClass.GAME_ENTRY_GROUP_BOUNDARY, boundary);
    }

    /** Refreshes the clocks, or the time since the last move, for Unix time `nowMs` **/
    public function updateTime(nowMs:Float):Void
    {
        var clock:Null<GameClock> = game.clock;
        if (clock == null)
        {
            lastMoveLabel.text = OngoingGameFormatters.lastMoveAgo(OngoingGameFormatters.elapsedSince(game.waitingSinceMs(), nowMs));
            return;
        }

        var opponentColor:PieceColor = game.ownColor.opposite();
        ownClockLabel.text = ClockFormatters.formatRemainingTime(clock.remainingMs(game.ownColor, nowMs));
        opponentClockLabel.text = ClockFormatters.formatRemainingTime(clock.remainingMs(opponentColor, nowMs));
        ownClockLabel.setClass(StyleClass.GAME_ENTRY_CLOCK_RUNNING, clock.tickingSide == game.ownColor);
        opponentClockLabel.setClass(StyleClass.GAME_ENTRY_CLOCK_RUNNING, clock.tickingSide == opponentColor);
    }
}
