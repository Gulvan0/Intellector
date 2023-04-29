package gfx.popups;

import gfx.basic_components.BaseDialog;
import net.Requests;
import haxe.ui.components.Link;

@:build(haxe.ui.macros.ComponentMacros.build('assets/layouts/popups/full_spectator_list_popup.xml'))
class FullSpectatorListDialog extends BaseDialog
{
    private function resize()
    {
        //* Do nothing
    }

    private function onClose(btn)
    {
        //* Do nothing
    }

    public function new(spectatorList:Array<String>) 
    {
        super(null, false);

        for (login in spectatorList)
        {
            var link:Link = new Link();
            link.styleNames = "spectator-link";
            link.text = login;
            link.onClick = e -> {Requests.getMiniProfile(login);};
            contentSV.addComponent(link);
        }
    }
}