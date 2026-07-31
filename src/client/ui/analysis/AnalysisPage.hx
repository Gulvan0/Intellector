package client.ui.analysis;

import haxe.ui.components.Label;
import haxefolio.LocaleUtils;
import haxefolio.PageBase;

class AnalysisPage extends PageBase
{
    private final studyId:Null<Int>;

    public function new(?studyId:Null<Int>)
    {
        super();
        this.studyId = studyId;
    }

    private override function init():Void
    {
        var titleKey:String = studyId != null
            ? LocaleUtils.localeBinding("intellector.analysis.study_title")
            : LocaleUtils.localeBinding("intellector.analysis.title");
        setTitle(titleKey, studyId);

        var label:Label = new Label();
        label.text = LocaleUtils.resolveText(titleKey, studyId);
        addComponent(label);
    }
}
