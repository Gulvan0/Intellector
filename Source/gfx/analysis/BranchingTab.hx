package gfx.analysis;

import struct.Situation;
import struct.Ply;
import struct.Variant;
import dict.Dictionary;
import openfl.text.TextField;
import haxe.ui.containers.ScrollView;
import Preferences.BranchingTabType;
import gfx.analysis.RightPanel.RightPanelEvent;
import openfl.display.Sprite;

enum BranchingTabEvent
{
    BranchSelected(branch:Array<Ply>, plyStrArray:Array<String>, startingSituation:Situation);
    RevertNeeded(plyCnt:Int);
}

class BranchingTab extends ScrollView 
{
    private var innerContentWidth:Float;
    private var innerContentHeight:Float;

    public var variant(default, null):Variant;
    public var selectedBranch(default, null):Array<Int> = [];

    private var variantView:IVariantView;
    private var backgroundSprite:Sprite;
    private var variantSprite:Sprite;
    private var vbox:VBox;

    private var eventHandler:BranchingTabEvent->Void;

    public function selectBranch(branch:Array<Int>)
    {
        selectedBranch = branch.copy();
        variantView.selectBranch(selectedBranch);
    }

    public function updateContentSize() 
    {
        backgroundSprite.width = vbox.width = Math.max(innerContentWidth, 145 + variantSprite.width); //TODO: Magic value?
		backgroundSprite.height = vbox.height = Math.max(innerContentHeight, 20 + variantSprite.height); //TODO: Magic value?
    }

    private function onBranchSelect(path:Array<Int>)
    {
        var extendedPath:Array<Int> = variant.extendPathLeftmost(path);
        selectBranch(extendedPath);

        var plys:Array<Ply> = variant.getBranchByPath(path);
        var plyStrs:Array<Ply> = Ply.plySequenceToNotation(plys, variant.startingSituation);
        eventHandler(BranchSelected(plys, plyStrs, variant.startingSituation));
    }

    private function onBranchRemove(path:Array<Int>)
    {
        if (Variant.belongs(path, selectedBranch))
        {
            var plysToRevertCnt:Int = selectedBranch.length - path.length + 1;
            selectBranch(Variant.parentPath(path));
            eventHandler(RevertNeeded(plysToRevertCnt));
        }
        variantView.removeNode(path, variant);
        variant.removeNode(path);
        updateContentSize();
    }

    public function init(eventHandler:BranchingTabEvent->Void)
    {
        this.eventHandler = eventHandler;

        var tf:TextField = new TextField();
        tf.text = Dictionary.getPhrase(BRANCH_REMOVE_HINT);
        tf.selectable = false;
        tf.setTextFormat(new TextFormat(null, 16, null, null, true));
        tf.y = -5; //TODO: Magic value?
        tf.width = 300; //TODO: Magic value?

        variantSprite.addChildAt(backgroundSprite, 0);
        variantSprite.addChildAt(tf, 1);
        variantView.init(onBranchSelect, onBranchRemove); 
    }

    //390*360; 390 = PANEL_WIDTH - 10; 360 = ???, but self height = 463?! TODO: Experiment with sizes
    public function new(type:BranchingTabType, startingSituation:Situation, innerContentWidth:Float, innerContentHeight:Float)
    {
        super();
        this.innerContentWidth = innerContentWidth;
        this.innerContentHeight = innerContentHeight;
        this.variant = new Variant(startingSituation);

        backgroundSprite = Shapes.fillOnlyRect(innerContentWidth, innerContentHeight, 0xffffff);
        variantSprite = new Sprite();

        switch type 
        {
            case Tree:
                var variantTree = new VariantTree();
                variantTree.x = 20; //TODO: Magic value?
                variantTree.y = 20; //TODO: Magic value?
                variantSprite.addChild(variantTree);
                variantView = variantTree;
            case Outline:
                //TODO: Fill
            case PlainText:
                //TODO: Fill
        }

        var wrapper:SpriteWrapper = new SpriteWrapper();
        wrapper.sprite = variantSprite;
		
		vbox = new VBox();
		vbox.width = innerContentWidth;
		vbox.height = innerContentHeight;
		vbox.addComponent(wrapper);

        horizontalAlign = 'center';
        verticalAlign = 'center';
        width = innerContentWidth;
        height = innerContentHeight * 463 / 360; //TODO: Magic value?
        addComponent(vbox);
    }
}