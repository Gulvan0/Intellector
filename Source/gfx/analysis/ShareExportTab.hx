package gfx.analysis;

import utils.StringUtils;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.Box;
using StringTools;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/analysis/share_export_tab.xml"))
class ShareExportTab extends Box
{
    private var exportNewCallback:(name:String)->Void;
    private var overwriteCallback:(newName:String)->Void;

    @:bind(exportNewBtn, MouseEvent.CLICK)
    private function onExportNewPressed(e) 
    {
        exportNewCallback(StringUtils.clean(nameInputField.text, 50));
    }

    @:bind(overwriteBtn, MouseEvent.CLICK)
    private function onOverwritePressed(e) 
    {
        overwriteCallback(StringUtils.clean(nameInputField.text, 50));
    }

    public function init(exportNewCallback:(name:String)->Void, ?overwriteCallback:(newName:String)->Void, ?oldStudyName:String)
    {
        this.exportNewCallback = exportNewCallback;
        this.overwriteCallback = overwriteCallback;

        if (oldStudyName != null)
            overwriteBtn.text = overwriteBtn.text.replace('%name%', oldStudyName);
        else
            overwriteBtn.hidden = true;
    }

    public function new()
    {
        super();
    }
}