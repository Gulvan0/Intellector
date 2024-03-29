package gfx.profile.complex_components;

import haxe.ui.containers.VBox;
import gfx.profile.data.StudyData;
import gfx.popups.StudyParamsDialog;
import tests.SimpleTests;
import haxe.ds.BalancedTree;
import dict.Dictionary;
import gfx.profile.simple_components.StudyWidget;
import haxe.ui.events.MouseEvent;
import net.Requests;
import gfx.profile.simple_components.StudyWidget.StudyWidgetData;
import net.shared.dataobj.StudyInfo;
import haxe.ui.components.Button;
import haxe.ui.containers.ListView;
import haxe.ui.containers.ScrollView;

@:build(haxe.ui.macros.ComponentMacros.build('assets/layouts/profile/studies_tab.xml'))
class StudiesTab extends VBox
{
    private static inline final STUDIES_PAGE_SIZE:Int = 10;

    private var studyFilterList:StudyFilterList;

    private var profileOwner:String;
    private var activeTags:Array<String> = [];
    private var loadedStudies:Map<Int, StudyInfo> = [];
    private var widgetByStudyID:Map<Int, StudyWidget> = [];

    private function onTagFilterAdded(tag:String)
    {
        activeTags.push(tag);
        reloadStudies();
    }

    private function onTagFilterRemoved(tag:String)
    {
        activeTags.remove(tag);
        reloadStudies();
    }

    private function onFiltersCleared()
    {
        activeTags = [];
        reloadStudies();
    }

    private function onTagSelectedFromStudyWidget(tag:String)
    {
        if (activeTags.contains(tag))
            return;

        activeTags.push(tag);
        studyFilterList.appendTag(tag);
        reloadStudies();
    }

    private function onStudyClicked(id:Int)
    {
        var info:StudyInfo = loadedStudies.get(id);
        SceneManager.toScreen(Analysis(info.variantStr, null, new StudyData(id, profileOwner, info)));
    }

    private function onEditStudyRequested(id:Int)
    {
		Dialogs.getQueue().add(new StudyParamsDialog(Edit(id, loadedStudies.get(id), onStudyEdited.bind(id))));
    }

    private function onStudyEdited(id:Int, newParams:StudyInfo)
    {
        var newWidgetData:StudyWidgetData = generateStudyWidgetData(id, newParams);
        
        widgetByStudyID.get(id).updateData(newWidgetData);
        loadedStudies.set(id, newParams);
    }

    private function onDeleteStudyRequested(id:Int)
    {
        Networker.emitEvent(DeleteStudy(id));
        studiesList.removeComponent(widgetByStudyID.get(id));
        loadedStudies.remove(id);
        widgetByStudyID.remove(id);
    }

    private function generateStudyWidgetData(id:Int, info:StudyInfo):StudyWidgetData
    {
        return {
            id: id,
            ownerLogin: profileOwner,
            info: info,
            onStudyClicked: onStudyClicked.bind(id),
            onDeletePressed: onDeleteStudyRequested.bind(id),
            onEditPressed: onEditStudyRequested.bind(id),
            onTagSelected: onTagSelectedFromStudyWidget
        };
    }

    private function appendStudies(infos:Map<Int, StudyInfo>, hasNext:Bool)
    {
        var infoTree:BalancedTree<Int, StudyInfo> = new BalancedTree();
        for (id => info in infos.keyValueIterator())
            infoTree.set(-id, info);

        for (negID => info in infoTree.keyValueIterator())
        {
            var id:Int = -negID;
            var studyWidgetData:StudyWidgetData = generateStudyWidgetData(id, info);
            var studyWidget:StudyWidget = new StudyWidget(studyWidgetData);
            
            studiesList.addComponent(studyWidget);
            loadedStudies.set(id, info);
            widgetByStudyID.set(id, studyWidget);
        }

        loadMoreBtn.hidden = !hasNext;
        loadMoreBtn.disabled = false;
    }

    private function reloadStudies()
    {
        studiesList.removeAllComponents();
        loadedStudies = [];
        widgetByStudyID = [];
        loadMore();
    }

    @:bind(loadMoreBtn, MouseEvent.CLICK)
    private function loadMore(?e)
    {
        loadMoreBtn.disabled = true;
        Requests.getPlayerStudies(profileOwner, Lambda.count(loadedStudies), STUDIES_PAGE_SIZE, activeTags, appendStudies);
    }

    public function new(profileOwner:String, preloadedStudies:Map<Int, StudyInfo>, totalStudies:Int)
    {
        super();
        this.percentWidth = 100;
        this.text = Dictionary.getPhrase(PROFILE_STUDIES_TAB_TITLE);
        
        this.profileOwner = profileOwner;

        studyFilterList = new StudyFilterList(Percent(100), 27, onTagFilterAdded, onTagFilterRemoved, onFiltersCleared, PROFILE_TAG_FILTERS_PREPENDER, PROFILE_TAG_NO_FILTERS_PLACEHOLDER_TEXT, PROFILE_ADD_TAG_FILTER_BTN_TEXT, PROFILE_REMOVE_TAG_FILTER_BTN_TOOLTIP, PROFILE_CLEAR_TAG_FILTERS_BTN_TEXT, PROFILE_TAG_FILTER_PROMPT_QUESTION_TEXT);
        addComponentAt(studyFilterList, 0);

        appendStudies(preloadedStudies, Lambda.count(preloadedStudies) < totalStudies);
    }
}