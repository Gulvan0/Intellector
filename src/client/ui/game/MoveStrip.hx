package client.ui.game;

import client.datatypes.game.PlyNavigationType;
import haxe.ui.components.Button;
import haxe.ui.containers.HBox;
import haxefolio.LocaleUtils;

/** Compact navigation: first, previous, the shown move (opening the move list), next, last **/
class MoveStrip extends HBox
{
    private static inline final NAVIGATION_BUTTON_SIZE:Float = 44;

    private final startButton:Button;
    private final previousButton:Button;
    private final currentButton:Button;
    private final nextButton:Button;
    private final endButton:Button;

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

        for (button in [startButton, previousButton, nextButton, endButton])
            button.width = NAVIGATION_BUTTON_SIZE;
        for (button in [startButton, previousButton, currentButton, nextButton, endButton])
            addComponent(button);
    }

    /** `shownNotation`: the shown ply's, null at the starting position **/
    public function setShown(shownPlyCount:Int, plyCount:Int, shownNotation:Null<String>):Void
    {
        currentButton.text = shownNotation != null ? '$shownPlyCount. $shownNotation' : LocaleUtils.localeBinding("intellector.live_game.moves.start_short");
        startButton.disabled = shownPlyCount == 0;
        previousButton.disabled = shownPlyCount == 0;
        nextButton.disabled = shownPlyCount == plyCount;
        endButton.disabled = shownPlyCount == plyCount;
    }
}
