package client.ui.common.overlays.share;

import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.LocaleUtils;
import haxefolio.appearance.AppearanceContext;
import haxefolio.form.plumbing.FieldHeader;

/** The body of one share group: its sections, top to bottom, `SHARE_SECTION_GAP` apart **/
class SharePage extends VBox
{
    private final disposers:Array<Void->Void> = [];

    public function new()
    {
        super();

        this.percentWidth = 100;
        this.addClass(StyleClass.SHARE_BODY);
    }

    /** Releases what the sections hold **/
    public function dispose():Void
    {
        for (disposer in disposers)
            disposer();
    }

    /** Adds a section that labels itself, released with the page **/
    private function addSection(content:Component, dispose:Void->Void):Void
    {
        this.addComponent(content);
        disposers.push(dispose);
    }

    /** Adds `content` under a label line of its own, released with the page **/
    private function addLabelledSection(labelKey:String, content:Component, dispose:Void->Void):Void
    {
        var section:VBox = new VBox();
        section.percentWidth = 100;
        section.verticalSpacing = 0;

        var header:FieldHeader = new FieldHeader(LocaleUtils.localeBinding(labelKey));
        header.height = AppearanceContext.current.geometry.messageLine;
        section.addComponent(header);
        section.addComponent(content);

        addSection(section, dispose);
    }
}
