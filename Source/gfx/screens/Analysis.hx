package gfx.screens;

import gfx.analysis.AnalysisLayout;

class Analysis extends Screen
{
    public override function onEntered()
    {
        //* Do nothing
    }

    public override function onClosed()
    {
        //* Do nothing
    }

    public function new(?initialVariantStr:String)
    {
        super();
        content.addComponent(new AnalysisLayout(initialVariantStr));
    }
}