package gfx.live.common.action_bar;

import dict.Dictionary;
import dict.Phrase;
import haxe.ui.containers.HBox;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/game/request_box.xml"))
class RequestBox extends HBox
{
    public function new(question:Phrase, onAccept:Void->Void, onDecline:Void->Void)
    {
        super();

        questionLabel.text = Dictionary.getPhrase(question);
        acceptBtn.onClick = e -> {onAccept();};
        declineBtn.onClick = e -> {onDecline();};
    }
}