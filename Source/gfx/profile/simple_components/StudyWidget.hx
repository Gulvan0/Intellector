package gfx.profile.simple_components;

import gameboard.lightweight.LighttBoard.LightBoard;
import net.shared.dataobj.StudyInfo;
import gfx.basic_components.BoardWrapper;
import gameboard.Board;
import gfx.profile.complex_components.StudyTagList;
import haxe.ui.events.MouseEvent;
import haxe.ui.core.ItemRenderer;
import dict.Dictionary;
import net.shared.board.Situation;

typedef StudyWidgetData =
{
    var id:Int;
    var ownerLogin:String;
    var info:StudyInfo;
    var onTagSelected:String->Void;
    var onEditPressed:Void->Void;
    var onDeletePressed:Void->Void;
    var onStudyClicked:Void->Void;
}

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/profile/study_widget.xml"))
class StudyWidget extends ItemRenderer
{
    private var typedData:StudyWidgetData;

    @:bind(editBtn, MouseEvent.CLICK)
    private function edit(e)
    {
        typedData.onEditPressed();
    }

    @:bind(deleteBtn, MouseEvent.CLICK)
    private function delete(e)
    {
        typedData.onDeletePressed();
    }

    @:bind(contentBox, MouseEvent.CLICK)
    private function open(e)
    {
        typedData.onStudyClicked();
    }

    private function reloadTagList(tags:Array<String>)
    {
        tagListContainer.removeAllComponents();

        var tagList:StudyTagList = new StudyTagList(Percent(100), 26, tags, typedData.onTagSelected);
        tagList.verticalAlign = 'center';
        tagListContainer.addComponent(tagList);
    }

    private function reloadBoard(keyPositionSIP:String) 
    {
        boardContainer.removeChildren();

        var keySituation:Situation = Situation.deserialize(keyPositionSIP);
        var board:LightBoard = new LightBoard(keySituation, keySituation.turnColor, 10, true);
        board.x = (boardContainer.width - board.width) / 2;
        board.y = (boardContainer.height - board.height) / 2;
        boardContainer.addChild(board);
    }

    private override function onDataChanged(data:Dynamic)
    {
        super.onDataChanged(data);
        
        if (data == null)
            return;

        typedData = data;

        if (!LoginManager.isPlayer(typedData.ownerLogin))
        {
            editBtn.hidden = true;
            deleteBtn.hidden = true;
        }

        var info:StudyInfo = typedData.info;

        nameLabel.text = info.name;
        descriptionLabel.text = info.description;

        reloadTagList(info.tags);
        reloadBoard(info.keyPositionSIP);
    }
}