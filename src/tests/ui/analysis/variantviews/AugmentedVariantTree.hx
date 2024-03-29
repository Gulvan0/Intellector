package tests.ui.analysis.variantviews;

import tests.ui.TestedComponent.ComponentGraphics;
import tests.ui.analysis.TVariantView.ITestedVariantView;
import gfx.analysis.VariantTree;
import net.shared.board.Situation;

class AugmentedVariantTree extends VariantTree implements ITestedVariantView
{
    private override function onNodeSelectRequest(code:String)
    {
        UITest.logHandledEvent('select|$code');
        super.onNodeSelectRequest(code);
    }

    private override function onNodeRemoveRequest(code:String)
    {
        UITest.logHandledEvent('remove|$code');
        super.onNodeRemoveRequest(code);
    }

    public function _imitateEvent(encodedEvent:String)
    {
        var parts = encodedEvent.split('|');
        if (parts[0] == 'select')
            super.onNodeSelectRequest(parts[1]);
        else if (parts[0] == 'remove')
            super.onNodeRemoveRequest(parts[1]);
    }

    public function getCurrentSituation():Situation
    {
        return variantRef.getSituationByPath(selectedBranch.subpath(selectedMove));
    }

    public function getComponent():ComponentGraphics 
    {
		return Sprite(this);
	}
}