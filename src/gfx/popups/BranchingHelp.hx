package gfx.popups;

import dict.Dictionary;
import haxe.ui.containers.dialogs.MessageBox;
import haxe.ui.core.Screen as HaxeUIScreen;

class BranchingHelp extends MessageBox
{
    public function new()
    {
        super();
        type = MessageBoxType.TYPE_INFO;
        title = Dictionary.getPhrase(ANALYSIS_BRANCHING_HELP_DIALOG_TITLE);
        messageLabel.htmlText = Dictionary.getPhrase(ANALYSIS_BRANCHING_HELP_DIALOG_TEXT);
        messageLabel.customStyle = {fontSize: Math.max(HaxeUIScreen.instance.actualHeight * 0.02, 12)};
        width = Math.min(500, HaxeUIScreen.instance.actualWidth * 0.95);
        height = 550;
    }
}