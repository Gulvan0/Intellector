package client.ui.common;

import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;

/** What a card shows in place of its content while that loads, or after it failed to **/
class LoadStatus extends VBox
{
    private final textLabel:Label;
    private final retryButton:Button;

    private var onRetry:Void->Void = () -> {};

    public function new()
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.LOAD_STATUS);

        textLabel = new Label();
        textLabel.addClass(StyleClass.LOAD_STATUS_TEXT);
        textLabel.horizontalAlign = "center";
        addComponent(textLabel);

        retryButton = new Button();
        retryButton.text = LocaleUtils.localeBinding("intellector.common.load.retry");
        retryButton.addClass(StyleClass.GAME_BUTTON);
        retryButton.horizontalAlign = "center";
        retryButton.onClick = _ -> onRetry();
        addComponent(retryButton);

        showLoading();
    }

    public function showLoading():Void
    {
        textLabel.text = LocaleUtils.localeBinding("intellector.common.load.loading");
        retryButton.hidden = true;
    }

    /** `timedOut`: the server didn't answer in time, rather than answered with an error **/
    public function showFailure(timedOut:Bool, onRetry:Void->Void):Void
    {
        this.onRetry = onRetry;
        textLabel.text = LocaleUtils.localeBinding(timedOut ? "intellector.common.load.timeout" : "intellector.common.load.failed");
        retryButton.hidden = false;
    }
}
