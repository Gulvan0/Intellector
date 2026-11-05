package client.ui.common.overlays.challenge.bot;

import client.datatypes.bot.BotKind;
import client.logic.bot.BotKinds;
import haxe.ui.containers.Box;
import haxe.ui.containers.ScrollView;
import haxe.ui.layouts.HorizontalLayout;
import haxefolio.structure.SidewaysScroll;
import js.Browser;
import js.html.StyleElement;

/**
    The bots to choose from, as cards in a single row scrolling sideways in every layout.
**/
class BotPicker extends ScrollView
{
    private static inline final MARKER_CLASS:String = "intellector-challenge-bot-picker-scroller";
    private static inline final ROW_BOTTOM_PADDING:Int = 6; // between the cards and the scrollbar

    private static var styleInjected:Bool = false;

    private final cards:Map<BotKind, BotCard> = [];
    private final content:Box;

    public function new(onPick:BotKind->Void)
    {
        super();

        injectStyleOnce();

        this.percentWidth = 100;
        this.percentHeight = 100;
        this.scrollMode = NATIVE;
        this.addClass(StyleClass.CHALLENGE_BOT_PICKER);
        this.element.classList.add(MARKER_CLASS);
        SidewaysScroll.attach(this.element);

        content = new Box();
        content.layout = new HorizontalLayout();
        content.paddingBottom = ROW_BOTTOM_PADDING;
        content.horizontalSpacing = StyleVars.CHALLENGE_OVERLAY_BOT_CARD_GAP;
        this.addComponent(content);

        for (kind in BotKinds.ALL)
        {
            var card:BotCard = new BotCard(kind, onPick);
            cards.set(kind, card);
            content.addComponent(card);
        }
    }

    public function dispose():Void
    {
        for (card in cards)
            card.dispose();
    }

    // HaxeUI applies its own overflow to a native scroller when it becomes ready
    private override function onReady():Void
    {
        super.onReady();
        applyOverflow();
    }

    private function applyOverflow():Void
    {
        this.element.style.overflowX = "scroll";
        this.element.style.overflowY = "hidden";
        (cast this.element.style : Dynamic).overscrollBehaviorX = "contain";
    }

    private static function injectStyleOnce():Void
    {
        if (styleInjected)
            return;

        styleInjected = true;

        // the surrounding scroll area lets touch pan vertically only; the row pans both ways, the page behind it needs vertical
        var style:StyleElement = Browser.document.createStyleElement();
        style.textContent = '
            #haxeui-container .haxeui-component.$MARKER_CLASS, #haxeui-container .haxeui-component.$MARKER_CLASS .haxeui-component { touch-action: pan-x pan-y; }
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
