package client.ui.home;

import client.ui.common.WidthObserver;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import morestd.Detachable;

using client.ui.ComponentExtension;

/**
    The page's frame, at most `MAX_WIDTH` wide and centred: the Play card beside the open challenges
    (stacked when they don't fit side by side), then the ongoing and the recent games. Narrow: only
    one games section shows, the one its tabs picked.
**/
class HomeLayout extends VBox
{
    private static inline final MAX_WIDTH:Float = 1200;
    private static inline final WIDE_GUTTERS:Float = 44;
    private static inline final NARROW_GUTTERS:Float = 28;
    private static inline final BLOCK_GAP:Float = 18;
    private static inline final PLAY_CARD_MIN_WIDTH:Float = 340;
    private static inline final PLAY_CARD_MAX_WIDTH:Float = 400;
    private static inline final CHALLENGES_MIN_WIDTH:Float = 600;

    private final frame:VBox;
    private final playCard:PlayCard;
    private final challengesCard:OpenChallengesCard;
    private final sections:Array<GamesSection>;
    private final sideBySide:HBox;
    private final stacked:VBox;
    private final widthHandle:Detachable;

    private var narrow:Bool = false;
    private var shownSection:Int = 0;
    private var frameWidth:Float = 0;
    private var topSideBySide:Null<Bool> = null;

    public function new(playCard:PlayCard, challengesCard:OpenChallengesCard, ongoing:GamesSection, recent:GamesSection)
    {
        super();
        this.playCard = playCard;
        this.challengesCard = challengesCard;
        sections = [ongoing, recent];
        percentWidth = 100;

        frame = new VBox();
        frame.horizontalAlign = "center";
        frame.addClass(StyleClass.HOME_FRAME);
        addComponent(frame);

        sideBySide = new HBox();
        sideBySide.percentWidth = 100;
        sideBySide.addClass(StyleClass.HOME_TOP_ROW);

        stacked = new VBox();
        stacked.percentWidth = 100;
        stacked.addClass(StyleClass.HOME_TOP_COLUMN);

        var topSlot:Box = new Box();
        topSlot.percentWidth = 100;
        frame.addComponent(topSlot);
        topSlot.addComponent(sideBySide);
        topSlot.addComponent(stacked);

        for (section in sections)
            frame.addComponent(section);

        widthHandle = WidthObserver.observe(this, width -> {
            frameWidth = Math.min(width, MAX_WIDTH);
            frame.width = frameWidth;
            applyWidth();
        });
    }

    public function setNarrow(narrow:Bool):Void
    {
        this.narrow = narrow;
        playCard.setNarrow(narrow);
        challengesCard.setNarrow(narrow);
        frame.setClass(StyleClass.HOME_NARROW, narrow);
        for (section in sections)
            section.setNarrow(narrow);
        renderSections();
        applyWidth();
    }

    /** Narrow: shows section `index` (0 ongoing, 1 recent) **/
    public function showSection(index:Int):Void
    {
        shownSection = index;
        renderSections();
    }

    public function dispose():Void
    {
        widthHandle.detach();
    }

    private function renderSections():Void
    {
        for (i in 0...sections.length)
            sections[i].hidden = narrow && i != shownSection;
    }

    private function applyWidth():Void
    {
        if (frameWidth <= 0)
            return;

        var contentWidth:Float = frameWidth - (narrow ? NARROW_GUTTERS : WIDE_GUTTERS);
        for (section in sections)
            section.setContentWidth(contentWidth);

        var fits:Bool = contentWidth >= PLAY_CARD_MIN_WIDTH + BLOCK_GAP + CHALLENGES_MIN_WIDTH;
        playCard.width = fits ? PLAY_CARD_MIN_WIDTH : Math.min(PLAY_CARD_MAX_WIDTH, contentWidth);
        if (fits == topSideBySide)
            return;
        topSideBySide = fits;

        for (card in [playCard, challengesCard])
            if (card.parentComponent != null)
                card.parentComponent.removeComponent(card, false);
        var container:Box = fits ? sideBySide : stacked;
        container.addComponent(playCard);
        container.addComponent(challengesCard);
        sideBySide.hidden = !fits;
        stacked.hidden = fits;
    }
}
