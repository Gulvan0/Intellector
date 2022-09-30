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
        SceneManager.toScreen(Analysis(info.variantStr, null, id, info.name));
    }

    private function onEditStudyRequested(id:Int)
    {
        Dialogs.studyParams(Edit(id, loadedStudies.get(id), onStudyEdited.bind(id)));
    }

    private function onStudyEdited(id:Int, newParams:StudyInfo)
    {
        Networker.emitEvent(OverwriteStudy(id, newParams));

        var oldParams:StudyInfo = loadedStudies.get(id);
        var itemIndex:Int = indexOf(id);

        studiesList.dataSource.update(itemIndex, oldParams);
        loadedStudies.set(id, newParams);
    }

    private function onDeleteStudyRequested(id:Int)
    {
        Networker.emitEvent(DeleteStudy(id));
        studiesList.dataSource.removeAt(indexOf(id));
        loadedStudies.remove(id);
    }

    private function appendStudies(infos:Map<Int, StudyInfo>, hasNext:Bool)
    {
        for (id => info in infos.keyValueIterator())
        {
            var studyWidgetData:StudyWidgetData = {
                id: id,
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
        this.text = Dictionary.getPhrase(PROFILE_STUDIES_TAB_TITLE);

        studyFilterList = new StudyFilterList(Percent(100), 27, onTagFilterAdded, onTagFilterRemoved, onFiltersCleared);
        addComponentAt(studyFilterList, 0);

        studiesList.addComponent(new StudyWidget());

        appendStudies(preloadedStudies, Lambda.count(preloadedStudies) < totalStudies);
    }
}