package client.ui.games.flow;

import haxe.ui.Toolkit;
import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.overlay.OverlayContent;
import js.Browser;
import js.html.Element;
import js.html.KeyboardEvent;

/**
    The Narrow steps: one full-screen sheet for the whole flow, the steps and prompts replacing each
    other in it. The first step's header has a cancelling cross, the others a ← button; Esc and
    dismissing the sheet cancel, Backspace goes back while the step holds no text.
**/
class SheetSurface implements StepSurface
{
    private static inline final SLUG:String = "games-condition";
    private static inline final HEADER_HEIGHT:Int = 56;

    private final onCancelled:Void->Void;
    private final header:Box;
    private final body:VBox;

    private var dismiss:Null<Void->Void> = null;
    private var closing:Bool = false;
    private var step:Null<FlowStep> = null;
    private var promptStep:Null<FlowStep> = null;

    public function new(onCancelled:Void->Void)
    {
        this.onCancelled = onCancelled;

        header = new Box();
        header.percentWidth = 100;
        header.addClass(StyleClass.GAMES_SHEET_HEADER);

        body = new VBox();
        body.percentWidth = 100;
        body.addClass(StyleClass.GAMES_SHEET_BODY);

        HaxeFolioApp.present(SLUG, build, null, null, onDismissed);
        Browser.document.addEventListener("keydown", onDocumentKeyDown);
    }

    public function show(step:FlowStep):Void
    {
        this.step = step;
        promptStep = null;
        display(step);
    }

    public function showPrompt(step:FlowStep, _:Component):Void
    {
        promptStep = step;
        display(step);
    }

    public function closePrompt():Void
    {
        if (promptStep == null)
            return;
        promptStep = null;
        if (step != null)
            display(step);
    }

    public function reanchor(_:Component):Void {}

    public function close():Void
    {
        closing = true;
        Browser.document.removeEventListener("keydown", onDocumentKeyDown);
        if (dismiss != null)
            dismiss();
    }

    private function build(dismiss:Void->Void):OverlayContent
    {
        this.dismiss = dismiss;
        return {
            regions: [
                Custom(HEADER_HEIGHT, header),
                Scroll(body)
            ]
        };
    }

    private function display(step:FlowStep):Void
    {
        header.removeAllComponents();
        var title:Void->String = step.title ?? () -> LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.games.formula.add_condition"));
        if (step.back != null)
            header.addComponent(new StepHeader(title, step.back));
        else
            header.addComponent(new StepHeader(title, null, cancel));

        body.removeAllComponents(false);
        body.addComponent(step.content);
        if (step.footer != null)
            body.addComponent(step.footer);
        Toolkit.callLater(step.onShown);
    }

    private function cancel():Void
    {
        if (dismiss != null)
            dismiss();
    }

    private function onDismissed():Void
    {
        Browser.document.removeEventListener("keydown", onDocumentKeyDown);
        if (!closing)
            onCancelled();
    }

    private function onDocumentKeyDown(event:KeyboardEvent):Void
    {
        var covered:Null<Element> = header.element.closest("[inert]");
        if (covered != null || event.key != "Backspace")
            return;

        var current:Null<FlowStep> = promptStep ?? step;
        if (current != null && current.back != null && !current.holdsText())
        {
            event.preventDefault();
            current.back();
        }
    }
}
