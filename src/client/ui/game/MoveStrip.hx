package client.ui.game;

import client.datatypes.game.PlyNavigationType;
import client.ui.BoardLayoutTier;
import haxe.ui.components.Button;
import haxe.ui.containers.HBox;
import haxefolio.LocaleUtils;

/** Navigation under or over the board: first, previous, the shown move (opening the move list), next, last **/
class MoveStrip extends HBox
{
    private static inline final NAVIGATION_BUTTON_SIZE:Float = 37;
    private static inline final COMPACT_NAVIGATION_BUTTON_SIZE:Float = 44;
    private static inline final RAIL_NAVIGATION_BUTTON_SIZE:Float = 28; // leaves the shown move room in the rail's narrow column

    private final startButton:Button;
    private final previousButton:Button;
    private final currentButton:Button;
    private final nextButton:Button;
    private final endButton:Button;

    private var shownPlyCount:Int = 0;
    private var plyCount:Int = 0;
    private var shownNotation:Null<String> = null;
    private var locked:Bool = false;

    public function new(onNavigate:PlyNavigationType->Void, onCurrentPressed:Void->Void)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.GAME_MOVE_STRIP);

        startButton = GameButtons.navigation(Start, onNavigate);
        previousButton = GameButtons.navigation(Previous, onNavigate);
        nextButton = GameButtons.navigation(Next, onNavigate);
        endButton = GameButtons.navigation(End, onNavigate);

        currentButton = new Button();
        currentButton.percentWidth = 100;
        currentButton.addClass(StyleClass.GAME_BUTTON);
        currentButton.addClass(StyleClass.GAME_STRIP_MOVE);
        currentButton.tooltip = LocaleUtils.localeBinding("intellector.live_game.navigation.open_moves");
        currentButton.onClick = _ -> onCurrentPressed();

        for (button in [startButton, previousButton, currentButton, nextButton, endButton])
            addComponent(button);
        setTier(Compact);
    }

    /** Sizes the navigation buttons for the tier's layout **/
    public function setTier(tier:BoardLayoutTier):Void
    {
        var size:Float = switch tier {
            case Compact: COMPACT_NAVIGATION_BUTTON_SIZE;
            case Rail: RAIL_NAVIGATION_BUTTON_SIZE;
            default: NAVIGATION_BUTTON_SIZE;
        }
        for (button in [startButton, previousButton, nextButton, endButton])
            button.width = size;
    }

    /** `shownNotation`: the shown ply's, null at the starting position **/
    public function setShown(shownPlyCount:Int, plyCount:Int, shownNotation:Null<String>):Void
    {
        this.shownPlyCount = shownPlyCount;
        this.plyCount = plyCount;
        this.shownNotation = shownNotation;
        currentButton.disabled = locked;
        currentButton.text = shownNotation != null ? '$shownPlyCount. $shownNotation' : LocaleUtils.localeBinding("intellector.live_game.moves.start_short");
        startButton.disabled = locked || shownPlyCount == 0;
        previousButton.disabled = locked || shownPlyCount == 0;
        nextButton.disabled = locked || shownPlyCount == plyCount;
        endButton.disabled = locked || shownPlyCount == plyCount;
    }

    /** Disabled in place **/
    public function setLocked(locked:Bool):Void
    {
        this.locked = locked;
        setShown(shownPlyCount, plyCount, shownNotation);
    }
}
