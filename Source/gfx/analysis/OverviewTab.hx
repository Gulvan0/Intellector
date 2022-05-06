package gfx.analysis;

import dict.Phrase;
import dict.Dictionary;
import haxe.ui.containers.HBox;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.styles.Style;
import gfx.utils.PlyScrollType;
import struct.PieceColor;
import gfx.common.MoveNavigator;
import gfx.analysis.RightPanel.RightPanelEvent;
import haxe.ui.containers.VBox;

enum OverviewTabEvent
{
    ExportSIPRequested;
    ExportStudyRequested;
    ScrollBtnPressed(type:PlyScrollType);
    SetPositionPressed;
}

class OverviewTab extends VBox
{
    public var navigator(default, null):MoveNavigator;

    private var eventHandler:OverviewTabEvent->Void;

    public function init(firstToMove:PieceColor, eventHandler:OverviewTabEvent->Void)
    {
        this.eventHandler = eventHandler;
        navigator.init(firstToMove, m -> {eventHandler(ScrollBtnPressed(m));});
    }

    public function new()
    {
        super();

        //TODO: Redesign; define in XML; add actionBar; add special mode to actionBar; add export image btn; add export as puzzle 'todo'
        navigator = new MoveNavigator();
        navigator.horizontalAlign = 'center';

        var setPositionBtn:Button = createSimpleBtn(ANALYSIS_SET_POSITION, 300, SetPositionPressed);
        setPositionBtn.horizontalAlign = 'center';

        var exportSIPBtn:Button = createSimpleBtn(EXPORT_SIP_BTN_TOOLTIP, 300, ExportSIPRequested);
        exportSIPBtn.horizontalAlign = 'center';

        var exportStudyBtn:Button = createSimpleBtn(ANALYSIS_EXPORT_STUDY, 300, ExportStudyRequested);
        exportStudyBtn.horizontalAlign = 'center';

        horizontalAlign = 'center';
        addComponent(navigator);
        addComponent(setPositionBtn);
        addComponent(exportSIPBtn);
        addComponent(exportStudyBtn);
    }

    private function createSimpleBtn(phrase:Phrase, width:Float, emittedEvent:OverviewTabEvent):Button
    {
        var btn = new Button();
        btn.width = width;
        btn.text = Dictionary.getPhrase(phrase);
        btn.onClick = e -> {
            eventHandler(emittedEvent);
        }
        return btn;
    }
}