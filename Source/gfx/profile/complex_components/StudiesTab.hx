package gfx.profile.complex_components;

import tests.SimpleTests;
import haxe.ds.BalancedTree;
import dict.Dictionary;
import gfx.profile.simple_components.StudyWidget;
import haxe.ui.events.MouseEvent;
import net.Requests;
import gfx.profile.simple_components.StudyWidget.StudyWidgetData;
import net.shared.StudyInfo;
import haxe.ui.components.Button;
import haxe.ui.containers.ListView;
import haxe.ui.containers.ScrollView;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/profile/studies_tab.xml'))
class StudiesTab extends ScrollView
{
    private static inline final STUDIES_PAGE_SIZE:Int = 10;

    private var studyFilterList:StudyFilterList;

    private var profileOwner:String;
    private var activeTags:Array<String> = [];
    private var loadedStudies:Map<Int, StudyInfo> = [];

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
        SceneManager.toScreen(Analysis(info.variantStr, null, id, info));
    }

    private function onEditStudyRequested(id:Int)
    {
        Dialogs.studyParams(Edit(id, loadedStudies.get(id), onStudyEdited.bind(id)));
    }

    private function onStudyEdited(id:Int, newParams:StudyInfo)
    {
        var itemIndex:Int = indexOf(id);
        var newWidgetData:StudyWidgetData = generateStudyWidgetData(id, newParams);
        
        studiesList.dataSource.update(itemIndex, newWidgetData);
        loadedStudies.set(id, newParams);
    }

    private function onDeleteStudyRequested(id:Int)
    {
        Networker.emitEvent(DeleteStudy(id));
        studiesList.dataSource.removeAt(indexOf(id));
        loadedStudies.remove(id);
    }

    private function generateStudyWidgetData(id:Int, info:StudyInfo):StudyWidgetData
    {
        return {
            id: id,
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
            studiesList.dataSource.add(studyWidgetData);
            loadedStudies.set(id, info);
        }

        loadMoreBtn.visible = hasNext;
        loadMoreBtn.disabled = false;
    }

    private function reloadStudies()
    {
        studiesList.dataSource.clear();
        loadedStudies = [];
        loadMore();
    }

    @:bind(loadMoreBtn, MouseEvent.CLICK)
    private function loadMore(?e)
    {
        loadMoreBtn.disabled = true;
        Requests.getPlayerStudies(profileOwner, Lambda.count(loadedStudies), STUDIES_PAGE_SIZE, activeTags, appendStudies);
    }

    private function indexOf(id:Int):Int
    {
        for (i in 0...studiesList.dataSource.size)
        {
            var element:StudyWidgetData = studiesList.dataSource.get(i);
            if (element.id == id)
                return i;
        }
        return -1;
    }

    public function new(preloadedStudies:Map<Int, StudyInfo>, totalStudies:Int)
    {
        super();
        this.percentWidth = 100;
        this.percentHeight = 100;
        this.text = Dictionary.getPhrase(PROFILE_STUDIES_TAB_TITLE);

        studyFilterList = new StudyFilterList(Percent(100), 27, onTagFilterAdded, onTagFilterRemoved, onFiltersCleared, PROFILE_TAG_FILTERS_PREPENDER, PROFILE_TAG_NO_FILTERS_PLACEHOLDER_TEXT, PROFILE_ADD_TAG_FILTER_BTN_TEXT, PROFILE_REMOVE_TAG_FILTER_BTN_TOOLTIP, PROFILE_CLEAR_TAG_FILTERS_BTN_TEXT, PROFILE_TAG_FILTER_PROMPT_QUESTION_TEXT);
        addComponentAt(studyFilterList, 0);

        studiesList.addComponent(new StudyWidget());

        appendStudies(preloadedStudies, Lambda.count(preloadedStudies) < totalStudies);
    }
}