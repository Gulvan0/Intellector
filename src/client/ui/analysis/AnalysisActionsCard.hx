package client.ui.analysis;

import client.ui.game.GameButtons;
import haxe.ui.components.Button;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;

typedef AnalysisActionHandlers =
{
    onFlip:Void->Void,
    onEditPosition:Void->Void,
    onShare:Void->Void,
    onPlayFromHere:Void->Void
}

/** Flip board, Edit position, Share, Play from here: two a row while wide, one icon row while compact **/
class AnalysisActionsCard extends VBox
{
    private final buttons:Array<{button:Button, captionKey:String}>;
    private var compact:Bool = false;

    public function new(handlers:AnalysisActionHandlers)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.GAME_CARD);
        addClass(StyleClass.GAME_ACTIONS_CARD);

        buttons = [
            {button: GameButtons.action("flip", "intellector.live_game.action.flip", handlers.onFlip), captionKey: "intellector.live_game.action.flip"},
            {button: GameButtons.actionWithIcon(Assets.analysisIcon("edit"), "intellector.analysis.action.edit_position", handlers.onEditPosition), captionKey: "intellector.analysis.action.edit_position"},
            {button: GameButtons.action("share", "intellector.live_game.action.share", handlers.onShare), captionKey: "intellector.live_game.action.share"},
            {button: GameButtons.action("play_from_here", "intellector.live_game.action.play_from_here", handlers.onPlayFromHere), captionKey: "intellector.live_game.action.play_from_here"}
        ];
        arrange();
    }

    public function setCompact(compact:Bool):Void
    {
        this.compact = compact;
        arrange();
    }

    private function arrange():Void
    {
        for (entry in buttons)
            if (entry.button.parentComponent != null)
                entry.button.parentComponent.removeComponent(entry.button, false);
        removeAllComponents();

        var rowSize:Int = compact ? buttons.length : 2;
        var i:Int = 0;
        while (i < buttons.length)
        {
            var row:HBox = new HBox();
            row.percentWidth = 100;
            row.addClass(StyleClass.GAME_ACTIONS_ROW);
            addComponent(row);

            var rowEntries:Array<{button:Button, captionKey:String}> = buttons.slice(i, i + rowSize);
            for (entry in rowEntries)
            {
                entry.button.percentWidth = 100 / rowEntries.length;
                GameButtons.setCaption(entry.button, entry.captionKey, !compact);
                row.addComponent(entry.button);
            }
            i += rowSize;
        }
    }
}
