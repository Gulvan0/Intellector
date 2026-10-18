package client.ui.profile;

import client.ui.common.WidthObserver;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import morestd.Detachable;

/**
    The page's frame, at most `MAX_WIDTH` wide and centred: the header on top, then the games with
    the aside to their right (wide), or the aside above the games (medium, narrow).
**/
class ProfileLayout extends VBox
{
    private static inline final MAX_WIDTH:Float = 1200;
    private static inline final ASIDE_WIDTH:Float = 340;

    private final frame:VBox;
    private final mainColumn:VBox;
    private final aside:VBox;
    private final columns:HBox;
    private final widthHandle:Detachable;

    private var tier:Null<ProfileLayoutTier> = null;

    public function new(header:Component, mainCards:Array<Component>, asideCards:Array<Component>)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.PROFILE_PAGE);

        frame = new VBox();
        frame.horizontalAlign = "center";
        frame.addClass(StyleClass.PROFILE_FRAME);
        addComponent(frame);

        mainColumn = new VBox();
        mainColumn.addClass(StyleClass.PROFILE_COLUMN);
        for (card in mainCards)
            mainColumn.addComponent(card);

        aside = new VBox();
        aside.addClass(StyleClass.PROFILE_COLUMN);
        for (card in asideCards)
            aside.addComponent(card);

        columns = new HBox();
        columns.percentWidth = 100;
        columns.addClass(StyleClass.PROFILE_COLUMNS);

        frame.addComponent(header);

        widthHandle = WidthObserver.observe(this, width -> frame.width = Math.min(width, MAX_WIDTH));
    }

    public function setTier(tier:ProfileLayoutTier):Void
    {
        var wide:Bool = tier == Wide;
        if (this.tier != null && (this.tier == Wide) == wide)
        {
            this.tier = tier;
            return;
        }
        this.tier = tier;

        for (part in [mainColumn, aside, columns])
            if (part.parentComponent != null)
                part.parentComponent.removeComponent(part, false);

        if (wide)
        {
            mainColumn.percentWidth = 100;
            aside.percentWidth = null;
            aside.width = ASIDE_WIDTH;
            columns.addComponent(mainColumn);
            columns.addComponent(aside);
            frame.addComponent(columns);
        }
        else
        {
            aside.width = null;
            aside.percentWidth = 100;
            mainColumn.percentWidth = 100;
            frame.addComponent(aside);
            frame.addComponent(mainColumn);
        }
    }

    public function dispose():Void
    {
        widthHandle.detach();
    }
}
