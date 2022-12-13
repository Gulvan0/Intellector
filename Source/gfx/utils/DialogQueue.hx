package gfx.utils;

import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import gfx.basic_components.utils.DialogGroup;
import gfx.basic_components.BaseDialog;

class DialogQueue
{
    private var shownDialogs:Array<Dialog> = [];
    private var groupMap:Map<DialogGroup, Array<Dialog>> = [for (group in DialogGroup.createAll()) group => []];
    private var modalCount:Int = 0;

    public function hasActiveDialog():Bool
    {
        return !Lambda.empty(shownDialogs);
    }

    private function onDialogClosed(dialog:BaseDialog)
    {
        shownDialogs.remove(dialog);
        if (dialog.group != null)
            groupMap[dialog.group].remove(dialog);

        if (dialog.modal)
        {
            modalCount--;
            if (modalCount == 0)
                SceneManager.onModalDialogHidden();
        }

        if (hasActiveDialog())
            shownDialogs[0].disabled = false;
    }

    private function onBasicDialogClosed(dialog:Dialog) 
    {
        shownDialogs.remove(dialog);

        if (hasActiveDialog())
            shownDialogs[0].disabled = false;
    }

    public function add(dialog:BaseDialog)
    {
        if (dialog.group == ReconnectionPopUp && !Lambda.empty(groupMap[ReconnectionPopUp]))
            return;

        if (hasActiveDialog())
            shownDialogs[0].disabled = true;

        dialog.assignQueueCallback(onDialogClosed);

        shownDialogs.unshift(dialog);
        if (dialog.group != null)
            groupMap[dialog.group].push(dialog);

        dialog.showDialog(dialog.modal);

        if (dialog.modal)
        {
            modalCount++;
            SceneManager.onModalDialogShown();
        }
    }

    public function addBasic(dialog:Dialog, ?closeHandler:DialogButton->Void, ?addToStage:Bool = false, ?group:Null<DialogGroup>)
    {
        if (hasActiveDialog())
            shownDialogs[0].disabled = true;

        shownDialogs.unshift(dialog);
        if (group != null)
            groupMap[group].push(dialog);

        dialog.onDialogClosed = e -> {
            onBasicDialogClosed(dialog);
            if (closeHandler != null)
                closeHandler(e.button);
        };

        if (addToStage)
            dialog.showDialog(dialog.modal);
    }

    public function closeGroup(group:DialogGroup) 
    {
        for (dialog in groupMap[group])
            dialog.hideDialog(DialogButton.CANCEL);
    }

    public function new()
    {

    }
}