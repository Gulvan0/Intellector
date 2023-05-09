package gfx.popups;

import net.shared.board.Situation;
import net.shared.variation.ReadOnlyVariation;
import net.shared.variation.VariationPath;
import gfx.basic_components.BaseDialog;
import gfx.ResponsiveToolbox.Dimension;
import gfx.profile.complex_components.StudyFilterList;
import net.Requests;
import haxe.ui.events.MouseEvent;
import dict.Dictionary;
import net.shared.dataobj.StudyInfo;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.core.Screen as HaxeUIScreen;

using utils.StringUtils;
using StringTools;

enum StudyParamsDialogMode
{
    Create(variation:ReadOnlyVariation);
    CreateOrOverwrite(newVariation:ReadOnlyVariation, existingStudyParams:StudyInfo);
    Edit(studyID:Int, currentParams:StudyInfo, onNewParamsSent:StudyInfo->Void);
}

@:build(haxe.ui.macros.ComponentMacros.build('assets/layouts/popups/study_params_dialog.xml'))
class StudyParamsDialog extends BaseDialog
{
    private static inline final MAX_TAG_COUNT:Int = 10;

    private final oldStudyID:Null<Int>;
    private final onParamsEdited:Null<StudyInfo->Void>;
    private final studyVariation:ReadOnlyVariation;
    private final keySIP:String;

    private var studyTagList:StudyFilterList;
    private var tags:Array<String> = [];

    private var onExploredStudyUpdated:StudyInfo->Void;

    private function resize()
    {
        width = Math.min(400, HaxeUIScreen.instance.actualWidth * 0.98);
        ResponsiveToolbox.resizeComponent(descTextArea, [Height => Min([Exact(200), VH(35)])]);
    }

    private function onClose(button)
    {
        //* Do nothing
    }

    private function generateKeySIP():String
    {
        var startingSituation:Situation = studyVariation.rootNode().getSituation();
        if (!startingSituation.isDefaultStarting())
            return startingSituation.serialize();
        else
        {
            var path:VariationPath = studyVariation.getFullMainlinePath();
            return studyVariation.getNode(path).getSituation().serialize();
        }
    }

    private function constructStudyInfo():StudyInfo
    {
        var info:StudyInfo = new StudyInfo();

        info.excludeNonParameters();
        info.assignVariation(studyVariation);
        info.keyPositionSIP = keySIP;
        info.name = nameTF.text.trim().shorten(StudyName, false);
        info.description = descTextArea.text.trim().shorten(StudyDescription, false);
        info.publicity = StudyPublicity.createByIndex(accessDropdown.selectedIndex);
        info.tags = tags;

        return info;
    }

    private function fillParams(studyInfo:StudyInfo)
    {
        nameTF.text = studyInfo.name;
        descTextArea.text = studyInfo.description;
        accessDropdown.selectedIndex = studyInfo.publicity.getIndex();
        tags = studyInfo.tags;
        for (tag in tags)
            studyTagList.appendTag(tag);
    }

    @:bind(createBtn, MouseEvent.CLICK)
    private function onCreatePressed(e)
    {
        var info = constructStudyInfo();
        Requests.createStudy(info, onExploredStudyUpdated); //will update study info automatically
        hideDialog(null);
    }

    @:bind(overwriteBtn, MouseEvent.CLICK)
    private function onOverwritePressed(e)
    {
        var info = constructStudyInfo();
        info.id = oldStudyID;
        info.ownerLogin = LoginManager.getLogin();
        Networker.emitEvent(OverwriteStudy(oldStudyID, info));
        onExploredStudyUpdated(info);
        hideDialog(null);
    }

    @:bind(saveParamsBtn, MouseEvent.CLICK)
    private function onSaveParamsPressed(e)
    {
        var info = constructStudyInfo();
        Networker.emitEvent(OverwriteStudy(oldStudyID, info));
        onParamsEdited(info);
        hideDialog(null);
    }

    @:bind(cancelBtn, MouseEvent.CLICK)
    private function onCancelPressed(e)
    {
        hideDialog(null);
    }

    private function onTagAdded(tag:String)
    {
        if (tags.length < MAX_TAG_COUNT)
            tags.push(tag);
    }

    private function onTagRemoved(tag:String)
    {
        tags.remove(tag);
    }

    private function onTagsCleared()
    {
        tags = [];
    }

    public function new(mode:StudyParamsDialogMode, onExploredStudyUpdated:StudyInfo->Void)
    {
        super(null, false);
        this.onExploredStudyUpdated = onExploredStudyUpdated;
        
        descOptionName.text = Dictionary.getPhrase(STUDY_PARAMS_DIALOG_PARAM_DESCRIPTION(StudyDescription));
        tagsOptionName.text = Dictionary.getPhrase(STUDY_PARAMS_DIALOG_PARAM_TAGS(MAX_TAG_COUNT));

        nameTF.maxChars = StudyName;

        studyTagList = new StudyFilterList(Percent(100), 25, onTagAdded, onTagRemoved, onTagsCleared, STUDY_PARAMS_DIALOG_TAG_LIST_PREPENDER, STUDY_PARAMS_DIALOG_NO_TAGS_PLACEHOLDER, STUDY_PARAMS_DIALOG_ADD_TAG_BUTTON_TOOLTIP, STUDY_PARAMS_DIALOG_REMOVE_TAG_BUTTON_TOOLTIP, STUDY_PARAMS_DIALOG_CLEAR_TAGS_BUTTON_TOOLTIP, STUDY_PARAMS_DIALOG_TAG_PROMPT_QUESTION);
        tagListContainer.addComponent(studyTagList);

        switch mode 
        {
            case Create(variation):
                title = Dictionary.getPhrase(STUDY_PARAMS_DIALOG_CREATE_TITLE);

                createBtn.text = Dictionary.getPhrase(STUDY_PARAMS_DIALOG_CREATE_BUTTON_TEXT);
                overwriteBtn.hidden = true;
                saveParamsBtn.hidden = true;

                studyVariation = variation;
                keySIP = generateKeySIP();

            case CreateOrOverwrite(newVariation, existingStudyParams):
                title = Dictionary.getPhrase(STUDY_PARAMS_DIALOG_CREATE_TITLE);

                createBtn.text = Dictionary.getPhrase(STUDY_PARAMS_DIALOG_CREATE_AS_NEW_BUTTON_TEXT);
                overwriteBtn.text = Dictionary.getPhrase(STUDY_PARAMS_DIALOG_OVERWRITE_BUTTON_TEXT(existingStudyParams.name));
                saveParamsBtn.hidden = true;

                oldStudyID = existingStudyParams.id;
                studyVariation = newVariation;
                keySIP = generateKeySIP();

                fillParams(existingStudyParams);
            case Edit(studyID, currentParams, onNewParamsSent):
                title = Dictionary.getPhrase(STUDY_PARAMS_DIALOG_EDIT_TITLE);

                createBtn.hidden = true;
                overwriteBtn.hidden = true;
                saveParamsBtn.text = Dictionary.getPhrase(STUDY_PARAMS_DIALOG_SAVE_CHANGES_BUTTON_TEXT);

                oldStudyID = studyID;
                onParamsEdited = onNewParamsSent;
                studyVariation = currentParams.plainVariation.toVariation();
                keySIP = currentParams.keyPositionSIP;

                fillParams(currentParams);
        }
    }
}