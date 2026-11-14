package client.ui.games.flow;

import haxe.ui.core.Component;

/**
    Where the condition flow shows its steps: a popover under the condition on Wide, a full-screen
    sheet on Narrow. Cancellation by the user (an outside press, Esc, dismissing the sheet) is
    reported to the callback the surface is built with, after the surface has closed.
**/
interface StepSurface
{
    /** Replaces the step on display, closing a prompt **/
    public function show(step:FlowStep):Void;

    /** An appended option's prompt, `option` being the list row that opened it **/
    public function showPrompt(step:FlowStep, option:Component):Void;

    public function closePrompt():Void;

    /** The component the steps belong to, after it was re-rendered **/
    public function reanchor(anchor:Component):Void;

    /** Closes without reporting a cancellation **/
    public function close():Void;
}
