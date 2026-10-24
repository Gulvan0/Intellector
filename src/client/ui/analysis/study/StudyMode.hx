package client.ui.analysis.study;

import client.auth.Identity;
import client.auth.IdentityKeeper;
import client.datatypes.study.Study;
import client.datatypes.study.StudyDetails;
import client.datatypes.variations.PlyTree;
import client.datatypes.variations.PlyTreeCursor;
import client.datatypes.variations.PlyTreeNode;
import client.logic.study.StudyContent;
import client.ui.analysis.study.StudyFormOverlay.StudyPreviewOptions;
import client.ui.analysis.study.StudyPreviewPanel.PreviewKind;
import client.ui.analysis.study.StudyPreviewPanel.PreviewSource;
import client.ui.common.overlays.login.LoginOverlay;
import client.utils.PagePaths;
import client.utils.TimedLoad;
import haxefolio.HaxeFolioApp;
import http.HttpError;
import intellectorboard.primitives.piece.PieceColor;
import net.models.study.StudyPublic;
import net.models.study.StudySummaryPublic;
import net.models.study.mappers.StudyMapper;
import net.rest.Rest;
import net.rest.RestOperationRegistry;

/** Where the page stands with its study **/
enum StudyStatus
{
    /** A bare analysis board **/
    None;
    Loading;
    LoadFailed(timedOut:Bool);
    /** It can't be shown; the board works as a bare one **/
    Unavailable(messageKey:String);
    Open(study:Study, own:Bool);
}

typedef StudyModeHost =
{
    cursor:PlyTreeCursor,
    /** The node marked as the card preview **/
    getMarked:Void->Null<PlyTreeNode>,
    setMarked:Null<PlyTreeNode>->Void,
    getOrientation:Void->PieceColor,
    /** The study's status or details changed **/
    onChanged:Void->Void
}

/**
    The analysis page's study: loading it into the board, saving the owner's edits, saving the board
    as a new study, editing the details and deleting it. Drives the study card, the compact study bar
    and the study sheet; the page lays them out and reacts to `onChanged`.
**/
class StudyMode
{
    public final card:StudyCard;
    public final bar:StudyBar;

    public var status(default, null):StudyStatus = None;
    public var saveState(default, null):StudySaveState = Saved;

    private final host:StudyModeHost;
    private final studyLoad:TimedLoad = new TimedLoad();
    private final saveLoad:TimedLoad = new TimedLoad();

    private var studyId:Null<Int> = null;
    private var savedSignature:String = "";
    private var locked:Bool = false;
    private var sheetFooter:Null<StudyFooter> = null;
    private var createAfterLogin:Bool = false;

    public function new(host:StudyModeHost)
    {
        this.host = host;
        var actions:StudyFooter.StudyActions = {onSave: save, onSaveAsNew: saveAsNew, onEditDetails: editDetails};
        card = new StudyCard(actions);
        bar = new StudyBar(openSheet, save);
        IdentityKeeper.addChangeListener(onIdentityChanged);
    }

    public function dispose():Void
    {
        IdentityKeeper.removeChangeListener(onIdentityChanged);
        studyLoad.cancel();
        saveLoad.cancel();
    }

    /** Opens study `studyId` **/
    public function open(studyId:Int):Void
    {
        this.studyId = studyId;
        load();
    }

    public function isShown():Bool
    {
        return status != None;
    }

    public function isLoading():Bool
    {
        return status == Loading;
    }

    /** The study open for its author, who may save the board into it **/
    public function isOwnOpen():Bool
    {
        return status.match(Open(_, true));
    }

    /** A study by someone else is open: its card preview is the author's business **/
    public function isVisitorOpen():Bool
    {
        return status.match(Open(_, false));
    }

    public function openStudy():Null<Study>
    {
        return switch status {
            case Open(study, _): study;
            default: null;
        }
    }

    /** Whether leaving would lose the owner's edits **/
    public function hasUnsavedChanges():Bool
    {
        return isOwnOpen() && saveState != Saved;
    }

    /** After any change of the tree or the marked node **/
    public function contentChanged():Void
    {
        if (isOwnOpen() && saveState != Saving)
            saveState = signature() == savedSignature ? Saved : Unsaved;
        refreshFooters();
    }

    /** Disabled in place while the position editor is open **/
    public function setLocked(locked:Bool):Void
    {
        this.locked = locked;
        card.setLocked(locked, saveState);
        refreshFooters();
    }

    /** Saving the board as a new study, after logging in for a guest **/
    public function saveAsNew():Void
    {
        if (IdentityKeeper.currentIdentity.isGuest())
        {
            createAfterLogin = true;
            LoginOverlay.present();
            return;
        }

        var tree:PlyTree = host.cursor.tree;
        var marked:Null<PlyTreeNode> = host.getMarked();
        var study:Null<Study> = openStudy();
        var kind:PreviewKind = if (marked == null)
            LineEnd;
        else if (isVisitorOpen())
            AuthorsPick;
        else
            Marked;
        var preview:StudyPreviewOptions = {
            node: StudyContent.previewNode(tree, marked),
            kind: kind,
            selected: host.cursor.selected,
            orientation: host.getOrientation()
        };
        var initial:StudyDetails = study != null ? new StudyDetails(study.details.name, study.details.description, LINK_ONLY, study.details.tags.copy()) : new StudyDetails("", "", LINK_ONLY, []);
        StudyFormOverlay.presentCreate(initial, preview, create);
    }

    private function load():Void
    {
        setStatus(Loading);
        studyLoad.start(
            (onResponse, onError) -> Rest.client().execute(RestOperationRegistry.GET_STUDY, onResponse, onError, ["study_id" => Std.string(studyId)]),
            onLoaded,
            onLoadFailed
        );
    }

    private function onLoaded(dto:StudyPublic):Void
    {
        if (dto.deleted)
        {
            setStatus(Unavailable("intellector.analysis.study.deleted"));
            return;
        }

        var tree:PlyTree = StudyMapper.treeFromDto(dto);
        host.cursor.load(tree);
        var marked:Null<PlyTreeNode> = StudyMapper.markedNodeFromDto(dto, tree);
        host.setMarked(marked);
        var study:Study = StudyMapper.dtoToDatatype(dto);
        savedSignature = StudyContent.signature(tree, marked);
        saveState = Saved;
        setStatus(Open(study, isOwnedByCurrentUser(study)));
    }

    private function onLoadFailed(error:Null<HttpError>):Void
    {
        if (error != null && error.httpStatus == 404)
            setStatus(Unavailable("intellector.analysis.study.not_found"));
        else if (error != null && error.httpStatus == 403)
            setStatus(Unavailable("intellector.analysis.study.private"));
        else
            setStatus(LoadFailed(error == null));
    }

    private function save():Void
    {
        var study:Null<Study> = openStudy();
        if (study == null || !isOwnOpen() || locked || saveState == Saving)
            return;

        var tree:PlyTree = host.cursor.tree;
        var marked:Null<PlyTreeNode> = host.getMarked();
        var sentSignature:String = StudyContent.signature(tree, marked);
        saveState = Saving;
        refreshFooters();

        saveLoad.start(
            (onResponse, onError) -> Rest.client().execute(RestOperationRegistry.UPDATE_STUDY, onResponse, onError, ["study_id" => Std.string(study.id)], null, StudyMapper.contentUpdate(tree, marked)),
            (dto:StudyPublic) -> {
                savedSignature = sentSignature;
                saveState = signature() == savedSignature ? Saved : Unsaved;
                replaceOpenStudy(StudyMapper.dtoToDatatype(dto));
            },
            _ -> {
                saveState = Failed;
                refreshFooters();
            }
        );
    }

    private function create(details:StudyDetails, source:PreviewSource, done:Bool->Void):Void
    {
        var tree:PlyTree = host.cursor.tree;
        var marked:Null<PlyTreeNode> = switch source {
            case Preview(_, _): host.getMarked();
            case Selection(node): node;
        }

        Rest.client().execute(
            RestOperationRegistry.CREATE_STUDY,
            (dto:StudySummaryPublic) -> {
                host.setMarked(marked);
                var study:Study = StudyMapper.summaryToDatatype(dto);
                studyId = study.id;
                savedSignature = StudyContent.signature(tree, marked);
                saveState = signature() == savedSignature ? Saved : Unsaved;
                HaxeFolioApp.replacePath(PagePaths.study(study.id));
                setStatus(Open(study, true));
                done(true);
            },
            _ -> done(false),
            null,
            null,
            StudyMapper.createPayload(details, tree, marked)
        );
    }

    private function editDetails():Void
    {
        var study:Null<Study> = openStudy();
        if (study == null || !isOwnOpen())
            return;

        StudyFormOverlay.presentEdit(study, saveDetails.bind(study), deleteStudy.bind(study));
    }

    private function saveDetails(study:Study, details:StudyDetails, done:Bool->Void):Void
    {
        Rest.client().execute(
            RestOperationRegistry.UPDATE_STUDY,
            (dto:StudyPublic) -> {
                replaceOpenStudy(StudyMapper.dtoToDatatype(dto));
                done(true);
            },
            _ -> done(false),
            ["study_id" => Std.string(study.id)],
            null,
            StudyMapper.detailsUpdate(details)
        );
    }

    private function deleteStudy(study:Study, done:Bool->Void):Void
    {
        Rest.client().execute(
            RestOperationRegistry.DELETE_STUDY,
            _ -> {
                studyId = null;
                saveLoad.cancel();
                HaxeFolioApp.replacePath("analysis");
                setStatus(None);
                done(true);
            },
            _ -> done(false),
            ["study_id" => Std.string(study.id)]
        );
    }

    private function openSheet():Void
    {
        var study:Null<Study> = openStudy();
        if (study == null || sheetFooter != null)
            return;

        var actions:StudyFooter.StudyActions = {onSave: save, onSaveAsNew: saveAsNew, onEditDetails: editDetails};
        sheetFooter = StudySheetOverlay.present(study, isOwnOpen(), actions, () -> sheetFooter = null);
        refreshFooters();
    }

    private function onIdentityChanged(identity:Identity):Void
    {
        switch status
        {
            case Open(study, own):
                var nowOwn:Bool = isOwnedByCurrentUser(study);
                if (nowOwn != own)
                {
                    saveState = signature() == savedSignature ? Saved : Unsaved;
                    setStatus(Open(study, nowOwn));
                }
            default:
        }

        if (createAfterLogin && !identity.isGuest())
        {
            createAfterLogin = false;
            saveAsNew();
        }
    }

    private function replaceOpenStudy(study:Study):Void
    {
        switch status
        {
            case Open(_, own):
                setStatus(Open(study, own));
            default:
        }
    }

    private function setStatus(status:StudyStatus):Void
    {
        this.status = status;
        switch status
        {
            case None:
            case Loading:
                card.showLoading();
                bar.showLoading();
            case LoadFailed(timedOut):
                card.showFailure(timedOut, load);
                bar.showFailure(timedOut, load);
            case Unavailable(messageKey):
                card.showUnavailable(messageKey);
                bar.showUnavailable(messageKey);
            case Open(study, own):
                card.showStudy(study, own);
                bar.showStudy(study, own);
        }
        refreshFooters();
        host.onChanged();
    }

    private function refreshFooters():Void
    {
        card.refreshFooter(saveState);
        bar.refresh(saveState, locked);
        if (sheetFooter != null)
            sheetFooter.refresh(isOwnOpen(), saveState, locked);
    }

    private function signature():String
    {
        return StudyContent.signature(host.cursor.tree, host.getMarked());
    }

    private static function isOwnedByCurrentUser(study:Study):Bool
    {
        return IdentityKeeper.currentIdentity.getLogin() == study.authorLogin;
    }
}
