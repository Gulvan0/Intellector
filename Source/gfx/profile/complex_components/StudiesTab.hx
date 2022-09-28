package gfx.profile.complex_components;

import dict.Dictionary;
import gfx.profile.simple_components.StudyWidget;
import haxe.ui.events.MouseEvent;
import net.Requests;
import gfx.profile.simple_components.StudyWidget.StudyWidgetData;
import net.shared.StudyInfo;
import haxe.ui.components.Button;
import haxe.ui.containers.ListView;
import haxe.ui.containers.ScrollView;

class StudiesTab extends ScrollView
{
    private static inline final STUDIES_PAGE_SIZE:Int = 10;

    private var profileOwner:String;

    private var studyFilterList:StudyFilterList;
    private var studiesList:ListView;
    private var loadMoreBtn:Button;

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
        SceneManager.toScreen(Analysis(info.variantStr, null, id, info.name));
    }

    private function onEditStudyRequested(id:Int)
    {
        Dialogs.editStudyParams(loadedStudies.get(id), onStudyEdited.bind(id));
    }

    private function onStudyEdited(id:Int, newParams:StudyInfo)
    {
        Networker.emitEvent(OverwriteStudy(id, newParams));

        var oldParams:StudyInfo = loadedStudies.get(id);
        var itemIndex:Int = studiesList.dataSource.indexOf(oldParams);

        studiesList.dataSource.update(itemIndex, oldParams);
        loadedStudies.set(id, newParams);
    }

    private function onDeleteStudyRequested(id:Int)
    {
        Networker.emitEvent(DeleteStudy(id));
        studiesList.dataSource.remove(loadedStudies.get(id));
        loadedStudies.remove(id);
    }

    private function appendStudies(infos:Map<Int, StudyInfo>, hasNext:Bool)
    {
        for (id => info in infos.keyValueIterator())
        {
            var studyWidgetData:StudyWidgetData = {
                info: info,
                onStudyClicked: onStudyClicked.bind(id),
                onDeletePressed: onDeleteStudyRequested.bind(id),
                onEditPressed: onEditStudyRequested.bind(id),
                onTagSelected: onTagSelectedFromStudyWidget
            };

            studiesList.dataSource.add(studyWidgetData);
            loadedStudies.set(id, info);
        }

        loadMoreBtn.visible = hasNext;
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
        Requests.getPlayerStudies(profileOwner, Lambda.count(loadedStudies), STUDIES_PAGE_SIZE, activeTags, appendStudies);
    }

    public function new(preloadedStudies:Map<Int, StudyInfo>, totalStudies:Int)
    {
        super();
        this.percentWidth = 100;
        this.percentHeight = 100;
        this.percentContentWidth = 100;

        studyFilterList = new StudyFilterList(Percent(100), 36, onTagFilterAdded, onTagFilterRemoved, onFiltersCleared);
        addComponent(studyFilterList);

        studiesList = new ListView();
        studiesList.percentWidth = 100;
        studiesList.percentContentWidth = 100;
        studiesList.itemRenderer = new StudyWidget();
        addComponent(studiesList);

        loadMoreBtn = new Button();
        loadMoreBtn.text = Dictionary.getPhrase(PROFILE_LOAD_MORE_BTN_TEXT);
        loadMoreBtn.horizontalAlign = 'center';
        addComponent(loadMoreBtn);

        appendStudies(preloadedStudies, Lambda.count(preloadedStudies) < totalStudies);
    }
}