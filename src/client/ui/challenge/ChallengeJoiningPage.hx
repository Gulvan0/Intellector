package client.ui.challenge;

import haxe.ui.components.Label;
import haxefolio.LocaleUtils;
import haxefolio.PageBase;

class ChallengeJoiningPage extends PageBase
{
    private final challengeId:Int;

    public function new(challengeId:Int)
    {
        super();
        this.challengeId = challengeId;
    }

    private override function init():Void
    {
        var titleKey:String = LocaleUtils.localeBinding("intellector.challenge_joining.title");
        setTitle(titleKey, challengeId);

        var label:Label = new Label();
        label.text = LocaleUtils.resolveText(titleKey, challengeId);
        addComponent(label);
    }
}
