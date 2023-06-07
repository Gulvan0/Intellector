package gfx.popups;

import hx.strings.collection.SortedStringSet;
import gfx.basic_components.BaseDialog;
import net.Requests;
import haxe.ui.components.Link;
import dict.Dictionary;

@:build(haxe.ui.ComponentBuilder.build('assets/layouts/popups/full_spectator_list_dialog.xml'))
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

    public function new(spectatorList:SortedStringSet) 
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