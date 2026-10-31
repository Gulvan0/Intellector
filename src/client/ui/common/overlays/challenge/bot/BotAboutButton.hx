package client.ui.common.overlays.challenge.bot;

import haxe.ui.containers.Box;
import haxe.ui.events.MouseEvent;
import js.Browser;
import js.html.Element;

/** The borderless "?" beside a bot's name, opening what the bot is about **/
class BotAboutButton extends Box
{
    private static inline final GLYPH_SIZE:Int = 16;
    private static inline final GLYPH:String = '<circle cx="8" cy="8" r="6.5"/><path d="M6.1 6.3a1.95 1.95 0 0 1 3.8.5c0 1.3-1.9 1.6-1.9 2.8"/><path d="M8 11.7v.01"/>';

    public function new(onActivate:Void->Void)
    {
        super();

        this.addClass(StyleClass.CHALLENGE_BOT_ABOUT_BUTTON);
        ComponentExtension.trackHover(this);

        var glyph:Element = Browser.document.createSpanElement();
        glyph.style.cssText = 'position: absolute; left: 50%; top: 50%; width: ${GLYPH_SIZE}px; height: ${GLYPH_SIZE}px; margin: -${GLYPH_SIZE >> 1}px 0 0 -${GLYPH_SIZE >> 1}px; pointer-events: none;';
        glyph.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="$GLYPH_SIZE" height="$GLYPH_SIZE" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" style="display: block;">$GLYPH</svg>';
        this.element.appendChild(glyph);
        this.element.setAttribute("role", "button");

        this.registerEvent(MouseEvent.CLICK, _ -> onActivate());
    }

    /** Its tooltip, naming the bot **/
    public function setLabel(label:String):Void
    {
        this.tooltip = label;
    }
}
