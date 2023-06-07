package gfx.profile.simple_components;

import haxe.ui.containers.Box;
import net.shared.dataobj.StudyInfo;
import gfx.game.board.Board;
import gfx.profile.complex_components.StudyTagList;
import haxe.ui.events.MouseEvent;
import dict.Dictionary;
import net.shared.board.Situation;

typedef StudyWidgetData =
{
    var info:StudyInfo;
    var onTagSelected:String->Void;
    var onEditPressed:Void->Void;
    var onDeletePressed:Void->Void;
    var onStudyClicked:Void->Void;
}

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/profile/simple_components/study_widget.xml"))
class StudyWidget extends Box
{
    private var typedData:StudyWidgetData;

    public function studyID():Int
    {
        return typedData.info.id;
    }

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

    private function loadBoard(keyPositionSIP:String) 
    {
        var keySituation:Situation = Situation.deserialize(keyPositionSIP);
        var board:Board = new Board(keySituation, keySituation.turnColor, None, 150, 150, true);
        board.horizontalAlign = "center";
        board.verticalAlign = "center";
        contentBox.addComponentAt(board, 0);
    }

    public function updateData(data:StudyWidgetData)
    {
        this.typedData = data;

        if (!LoginManager.isPlayer(typedData.info.ownerLogin))
        {
            editBtn.hidden = true;
            deleteBtn.hidden = true;
        }

        var info:StudyInfo = typedData.info;

        nameLabel.text = info.name;
        descriptionLabel.text = info.description;

        reloadTagList(info.tags);
        contentBox.removeComponentAt(0);
        loadBoard(info.keyPositionSIP);
    }

    public function new(data:StudyWidgetData)
    {
        super();
        this.typedData = data;

        if (!LoginManager.isPlayer(typedData.info.ownerLogin))
        {
            editBtn.hidden = true;
            deleteBtn.hidden = true;
        }

        var info:StudyInfo = typedData.info;

        nameLabel.text = info.name;
        descriptionLabel.text = info.description;

        reloadTagList(info.tags);
        loadBoard(info.keyPositionSIP);
    }
}