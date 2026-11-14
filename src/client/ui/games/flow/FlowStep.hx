package client.ui.games.flow;

import haxe.ui.core.Component;

/** What a step of the condition flow shows, and how it is left backwards **/
class FlowStep
{
    /** The header's title; null for none (the first step, while anchored) **/
    public final title:Null<Void->String>;
    public final content:Component;
    /** Pinned under the content, typically holding the Confirm button **/
    public final footer:Null<Component>;
    /** The ← button and Backspace; null for the first step **/
    public final back:Null<Void->Void>;
    /** Whether a text input of the step holds text, so that Backspace edits it rather than going back **/
    public final holdsText:Void->Bool;
    /** Called once the step is on screen, to focus its input **/
    public final onShown:Void->Void;

    public function new(title:Null<Void->String>, content:Component, ?footer:Component, ?back:Void->Void, ?holdsText:Void->Bool, ?onShown:Void->Void)
    {
        this.title = title;
        this.content = content;
        this.footer = footer;
        this.back = back;
        this.holdsText = holdsText ?? () -> false;
        this.onShown = onShown ?? () -> {};
    }
}
