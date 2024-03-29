package gfx.popups;

import gfx.profile.data.StudyData;
import gfx.basic_components.BaseDialog;
import gfx.ResponsiveToolbox.Dimension;
import gfx.profile.complex_components.StudyFilterList;
import net.Requests;
import haxe.ui.events.MouseEvent;
import dict.Dictionary;
import struct.Variant;
import net.shared.dataobj.StudyInfo;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.core.Screen as HaxeUIScreen;

using utils.StringUtils;
using StringTools;

enum StudyParamsDialogMode
{
    Create(variant:Variant);
    CreateOrOverwrite(newVariant:Variant, existingStudyID:Int, existingStudyParams:StudyInfo);
    Edit(studyID:Int, currentParams:StudyInfo, onNewParamsSent:StudyInfo->Void);
}

@:build(haxe.ui.macros.ComponentMacros.build('assets/layouts/popups/study_params_dialog.xml'))
class StudyParamsDialog extends BaseDialog
{
    private static inline final MAX_TAG_COUNT:Int = 10;

    private final oldStudyID:Null<Int>;
    private final onParamsEdited:Null<StudyInfo->Void>;
    private final serializedVariant:String;
    private final keySIP:String;

    private var studyTagList:StudyFilterList;
    private var tags:Array<String> = [];

    private function resize()
    {
        width = Math.min(400, HaxeUIScreen.instance.actualWidth * 0.98);
        ResponsiveToolbox.resizeComponent(descTextArea, [Height => Min([Exact(200), VH(35)])]);
    }

    private function onClose(button)
    {
        //* Do nothing
    }

    private function generateKeySIP(variant:Variant):String
    {
        if (!variant.startingSituation.isDefaultStarting())
            return variant.startingSituation.serialize();
        else
        {
            var path:VariantPath = variant.getLastMainLineDescendantPath([]);
            return variant.getSituationByPath(path).serialize();
        }
    }

    private function constructStudyInfo():StudyInfo
    {
        var info:StudyInfo = new StudyInfo();

        info.keyPositionSIP = keySIP;
        info.variantStr = serializedVariant;
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
        Requests.createStudy(info); //will update study info automatically
        hideDialog(null);
    }

    @:bind(overwriteBtn, MouseEvent.CLICK)
    private function onOverwritePressed(e)
    {
        var info = constructStudyInfo();
        Networker.emitEvent(OverwriteStudy(oldStudyID, info));
        SceneManager.updateAnalysisStudyInfo(new StudyData(oldStudyID, LoginManager.getLogin(), info));
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

    public function new(mode:StudyParamsDialogMode)
    {
        super(null, false);
        
        descOptionName.text = Dictionary.getPhrase(STUDY_PARAMS_DIALOG_PARAM_DESCRIPTION(StudyDescription));
        tagsOptionName.text = Dictionary.getPhrase(STUDY_PARAMS_DIALOG_PARAM_TAGS(MAX_TAG_COUNT));

        nameTF.maxChars = StudyName;

        studyTagList = new StudyFilterList(Percent(100), 25, onTagAdded, onTagRemoved, onTagsCleared, STUDY_PARAMS_DIALOG_TAG_LIST_PREPENDER, STUDY_PARAMS_DIALOG_NO_TAGS_PLACEHOLDER, STUDY_PARAMS_DIALOG_ADD_TAG_BUTTON_TOOLTIP, STUDY_PARAMS_DIALOG_REMOVE_TAG_BUTTON_TOOLTIP, STUDY_PARAMS_DIALOG_CLEAR_TAGS_BUTTON_TOOLTIP, STUDY_PARAMS_DIALOG_TAG_PROMPT_QUESTION);
        tagListContainer.addComponent(studyTagList);

        switch mode 
        {
            case Create(variant):
                title = Dictionary.getPhrase(STUDY_PARAMS_DIALOG_CREATE_TITLE);

                createBtn.text = Dictionary.getPhrase(STUDY_PARAMS_DIALOG_CREATE_BUTTON_TEXT);
                overwriteBtn.hidden = true;
                saveParamsBtn.hidden = true;

                serializedVariant = variant.serialize();
                keySIP = generateKeySIP(variant);

            case CreateOrOverwrite(newVariant, existingStudyID, existingStudyParams):
                title = Dictionary.getPhrase(STUDY_PARAMS_DIALOG_CREATE_TITLE);

                createBtn.text = Dictionary.getPhrase(STUDY_PARAMS_DIALOG_CREATE_AS_NEW_BUTTON_TEXT);
                overwriteBtn.text = Dictionary.getPhrase(STUDY_PARAMS_DIALOG_OVERWRITE_BUTTON_TEXT(existingStudyParams.name));
                saveParamsBtn.hidden = true;

                oldStudyID = existingStudyID;
                serializedVariant = newVariant.serialize();
                keySIP = generateKeySIP(newVariant);

                fillParams(existingStudyParams);
            case Edit(studyID, currentParams, onNewParamsSent):
                title = Dictionary.getPhrase(STUDY_PARAMS_DIALOG_EDIT_TITLE);

                createBtn.hidden = true;
                overwriteBtn.hidden = true;
                saveParamsBtn.text = Dictionary.getPhrase(STUDY_PARAMS_DIALOG_SAVE_CHANGES_BUTTON_TEXT);

                oldStudyID = studyID;
                onParamsEdited = onNewParamsSent;
                serializedVariant = currentParams.variantStr;
                keySIP = currentParams.keyPositionSIP;

                fillParams(currentParams);
        }
    }
}