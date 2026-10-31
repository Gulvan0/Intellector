package client.ui.common.overlays.challenge.bot;

import client.datatypes.bot.BotKind;
import client.logic.bot.BotKinds;
import haxe.ui.containers.Box;
import haxe.ui.containers.ScrollView;
import haxe.ui.layouts.HorizontalLayout;
import haxe.ui.layouts.VerticalGridLayout;
import haxefolio.ResponsivityController;
import js.Browser;
import js.html.StyleElement;
import morestd.Detachable;

/**
    The bots to choose from, as cards: a row scrolling sideways in the expanded layout, a grid of
    two columns scrolling down otherwise. `current` is outlined.
**/
class BotPicker extends ScrollView
{
    private static inline final MARKER_CLASS:String = "intellector-challenge-bot-picker-scroller";
    private static inline final ROW_BOTTOM_PADDING:Int = 6; // between the cards and the scrollbar

    private static var styleInjected:Bool = false;

    private final cards:Map<BotKind, BotCard> = [];
    private final content:Box;
    private final layoutBinding:Detachable;
    private var sideways:Bool = true;

    /** The outlined bot, if any **/
    public var current(default, set):Null<BotKind>;

    public function new(current:Null<BotKind>, onPick:BotKind->Void)
    {
        super();

        injectStyleOnce();

        this.percentWidth = 100;
        this.percentHeight = 100;
        this.scrollMode = NATIVE;
        this.addClass(StyleClass.CHALLENGE_BOT_PICKER);
        this.element.classList.add(MARKER_CLASS);

        content = new Box();
        content.horizontalSpacing = StyleVars.CHALLENGE_OVERLAY_BOT_CARD_GAP;
        content.verticalSpacing = StyleVars.CHALLENGE_OVERLAY_BOT_CARD_GAP;
        this.addComponent(content);

        for (kind in BotKinds.ALL)
        {
            var card:BotCard = new BotCard(kind, onPick);
            cards.set(kind, card);
            content.addComponent(card);
        }

        this.current = current;

        layoutBinding = ResponsivityController.bind(StyleVars.CHALLENGE_OVERLAY_BOT_CARDS_SIDEWAYS, applyLayout);
    }

    public function dispose():Void
    {
        layoutBinding.detach();
        for (card in cards)
            card.dispose();
    }

    private function set_current(value:Null<BotKind>):Null<BotKind>
    {
        current = value;
        for (kind => card in cards)
            card.selected = kind == value;
        return value;
    }

    private function applyLayout(sideways:Bool):Void
    {
        this.sideways = sideways;

        if (sideways)
            content.layout = new HorizontalLayout();
        else
        {
            var grid:VerticalGridLayout = new VerticalGridLayout();
            grid.columns = StyleVars.CHALLENGE_OVERLAY_BOT_CARDS_PER_ROW_NARROW;
            content.layout = grid;
        }

        content.paddingBottom = sideways ? ROW_BOTTOM_PADDING : 0;
        applyOverflow();
    }

    // HaxeUI applies its own overflow to a native scroller when it becomes ready
    private override function onReady():Void
    {
        super.onReady();
        applyOverflow();
    }

    private function applyOverflow():Void
    {
        this.element.style.overflowX = sideways ? "scroll" : "hidden";
        this.element.style.overflowY = sideways ? "hidden" : "scroll";
        (cast this.element.style : Dynamic).overscrollBehaviorX = "contain";
    }

    private static function injectStyleOnce():Void
    {
        if (styleInjected)
            return;

        styleInjected = true;

        // the surrounding scroll area lets touch pan vertically only; cards scrolling sideways need both
        var style:StyleElement = Browser.document.createStyleElement();
        style.textContent = '
            #haxeui-container .$MARKER_CLASS, #haxeui-container .$MARKER_CLASS .haxeui-component { touch-action: pan-x pan-y; }
            @media not (pointer: coarse) {
                .$MARKER_CLASS::-webkit-scrollbar { width: 8px; height: 8px; background: transparent; }
                .$MARKER_CLASS::-webkit-scrollbar-track { background: transparent; }
                .$MARKER_CLASS::-webkit-scrollbar-thumb { background-color: #d0c6b5; border-radius: 4px; }
                .$MARKER_CLASS::-webkit-scrollbar-thumb:hover { background-color: #bdb2a0; }
                .$MARKER_CLASS::-webkit-scrollbar-thumb:active { background-color: #9e9282; }
                @supports not selector(::-webkit-scrollbar) { .$MARKER_CLASS { scrollbar-width: thin; scrollbar-color: #d0c6b5 transparent; } }
            }
        ';
        Browser.document.head.appendChild(style);
    }
}
