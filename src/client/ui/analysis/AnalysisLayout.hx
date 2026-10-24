package client.ui.analysis;

import client.ui.analysis.AnalysisPanel;
import client.ui.analysis.editor.EditorCard;
import client.ui.analysis.editor.EditorToolCard;
import client.ui.analysis.study.StudyBar;
import client.ui.analysis.study.StudyCard;
import client.ui.analysis.variations.VariationsCard;
import client.ui.game.MoveStrip;
import client.ui.game.MovesCard;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;

using client.ui.ComponentExtension;

/**
    Arranges the page's parts. Wide: the study over the variations | the board | moves, then the
    actions or the editor. Medium: the board with the move strip under it | the variations, the
    moves and the study as tabs of one card, then the actions or the editor (the card shrinking to
    its tabs meanwhile). Compact: the study bar, the move strip, the board, the actions, then the
    variations filling the rest (the editor in their place while it's open); the moves open as a
    popover over the bottom. Expanded, the variations take the whole area. The study's parts show
    only while a study is open, or loading.
**/
class AnalysisLayout extends Box
{
    private static inline final SIDE_COLUMN_WIDTH:Float = 312;
    private static inline final MOVES_POPOVER_HEIGHT:Float = 200;
    private static inline final MIN_COMPACT_VARIATIONS_HEIGHT:Float = 220;

    private final variationsCard:VariationsCard;
    private final stage:AnalysisStage;
    private final moveStrip:MoveStrip;
    private final movesCard:MovesCard;
    private final actionsCard:AnalysisActionsCard;
    private final editorCard:EditorCard;
    private final toolCard:EditorToolCard;
    private final studyCard:StudyCard;
    private final studyBar:StudyBar;
    private final panelTabs:PanelTabs;

    private final wideRow:HBox;
    private final leftColumn:VBox;
    private final rightColumn:VBox;
    private final compactColumn:VBox;

    private var tier:Null<BoardLayoutTier> = null;
    private var editing:Bool = false;
    private var expanded:Bool = false;
    private var studyShown:Bool = false;
    private var roomy:Bool = true;
    // compact: Moves while the moves popover is open; medium: the shared card's tab
    private var shownPanel:AnalysisPanel = Variations;

    public function new(variationsCard:VariationsCard, stage:AnalysisStage, moveStrip:MoveStrip, movesCard:MovesCard, actionsCard:AnalysisActionsCard, editorCard:EditorCard, toolCard:EditorToolCard, studyCard:StudyCard, studyBar:StudyBar)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.ANALYSIS_LAYOUT);

        this.variationsCard = variationsCard;
        this.stage = stage;
        this.moveStrip = moveStrip;
        this.movesCard = movesCard;
        this.actionsCard = actionsCard;
        this.editorCard = editorCard;
        this.toolCard = toolCard;
        this.studyCard = studyCard;
        this.studyBar = studyBar;
        panelTabs = new PanelTabs(showPanel);

        wideRow = new HBox();
        wideRow.percentWidth = 100;
        wideRow.percentHeight = 100;
        wideRow.addClass(StyleClass.GAME_WIDE_ROW);

        leftColumn = createSideColumn();
        rightColumn = createSideColumn();

        compactColumn = new VBox();
        compactColumn.percentWidth = 100;
        compactColumn.percentHeight = 100;
        compactColumn.addClass(StyleClass.GAME_COMPACT_COLUMN);
    }

    public function isCompact():Bool
    {
        return tier == Compact;
    }

    /** Compact: the least height that leaves the variations card its minimum; measured, so call it after a layout **/
    public function compactMinHeight():Float
    {
        return compactNonStageHeight() + stage.element.offsetHeight;
    }

    /** Compact: the most the stage can take of `availableHeight` while leaving the variations card its minimum; measured, so call it after a layout **/
    public function compactStageMaxHeight(availableHeight:Float):Float
    {
        return availableHeight - compactNonStageHeight();
    }

    // summed up rather than derived from the card's position, which stops tracking the stage once the card is squeezed to its content
    private function compactNonStageHeight():Float
    {
        var height:Float = MIN_COMPACT_VARIATIONS_HEIGHT;
        var shownCount:Int = 0;
        for (part in compactColumn.childComponents)
        {
            if (part.hidden)
                continue;
            shownCount++;
            if (part != stage && part != variationsCard)
                height += part.element.offsetHeight;
        }
        var spacing:Float = compactColumn.style.verticalSpacing ?? 0.0;
        return height + spacing * Math.max(0, shownCount - 1);
    }

    /** Whether it fits the height it's given; the compact editor takes its content's height instead **/
    public function fillsHeight():Bool
    {
        return !(tier == Compact && editing);
    }

    /** Wide: whether the height leaves room to keep the editor's tool card space reserved under the board **/
    public function setRoomy(roomy:Bool):Void
    {
        if (this.roomy == roomy)
            return;
        this.roomy = roomy;
        refreshToolCardReserve();
    }

    // otherwise, as in medium, the board shrinks for the editor rather than staying small without it
    private function refreshToolCardReserve():Void
    {
        stage.setToolCardReserved(tier == Wide && roomy);
    }

    public function setTier(tier:BoardLayoutTier):Void
    {
        if (this.tier == tier)
            return;
        this.tier = tier;

        var compact:Bool = tier == Compact;
        var tabbed:Bool = tier == Medium;
        actionsCard.setCompact(compact);
        editorCard.setCompact(compact);
        toolCard.setCompact(compact);
        moveStrip.setCompact(compact);
        movesCard.setNavigationShown(tier == Wide);
        movesCard.setTitleShown(!tabbed);
        movesCard.setClass(StyleClass.ANALYSIS_TABBED, tabbed);
        stage.setFitsHeight(!compact);
        refreshToolCardReserve();
        studyCard.setTabbed(tabbed);
        shownPanel = Variations;
        build();
    }

    public function setEditing(editing:Bool):Void
    {
        this.editing = editing;
        stage.setEditing(editing);
        if (editing && tier != Medium) // medium keeps the chosen tab for after editing
            shownPanel = Variations;
        refreshVisibility();
    }

    public function setExpanded(expanded:Bool):Void
    {
        this.expanded = expanded;
        if (expanded)
            shownPanel = Variations;
        refreshVisibility();
    }

    /** Whether a study is open or loading, which gives its card, tab and bar a place **/
    public function setStudyShown(shown:Bool):Void
    {
        studyShown = shown;
        if (!shown && shownPanel == Study)
            shownPanel = Variations;
        refreshVisibility();
    }

    /** Compact: toggles the moves popover; medium: switches between the Variations and Moves tabs **/
    public function toggleMoves():Void
    {
        if (!editing && !expanded)
            showPanel(shownPanel == Moves ? Variations : Moves);
    }

    private function showPanel(panel:AnalysisPanel):Void
    {
        shownPanel = panel;
        refreshVisibility();
    }

    // only a tier change moves parts between containers; the rest toggles visibility, so scroll positions survive
    private function build():Void
    {
        stage.setStrip(null);
        detachParts();
        removeAllComponents(false);

        variationsCard.percentHeight = 100;
        switch tier
        {
            case Compact:
                editorCard.percentHeight = null;
                movesCard.percentHeight = null;
                movesCard.height = MOVES_POPOVER_HEIGHT;
                movesCard.verticalAlign = "bottom";

                for (part in ([studyBar, moveStrip, stage, actionsCard, editorCard, variationsCard] : Array<Component>))
                    compactColumn.addComponent(part);
                addComponent(compactColumn);
            case Medium:
                resetMovesSize();

                for (part in ([studyCard, variationsCard, movesCard, actionsCard, editorCard] : Array<Component>))
                    rightColumn.addComponent(part);
                wideRow.addComponent(stage);
                wideRow.addComponent(rightColumn);
                addComponent(wideRow);
                stage.setStrip(moveStrip);
            default:
                resetMovesSize();

                leftColumn.addComponent(studyCard);
                leftColumn.addComponent(variationsCard);
                rightColumn.addComponent(movesCard);
                rightColumn.addComponent(actionsCard);
                rightColumn.addComponent(editorCard);
                wideRow.addComponent(leftColumn);
                wideRow.addComponent(stage);
                wideRow.addComponent(rightColumn);
                addComponent(wideRow);
        }
        refreshVisibility();
    }

    private function refreshVisibility():Void
    {
        if (tier == null)
            return;

        actionsCard.hidden = editing || (tier != Wide && expanded);
        editorCard.hidden = !editing;
        stage.hidden = expanded;
        var movesOpen:Bool = shownPanel == Moves;

        switch tier
        {
            case Compact:
                setPanelContentShown(true);
                studyCard.hidden = true;
                studyBar.hidden = !studyShown || expanded;
                moveStrip.hidden = expanded;
                variationsCard.hidden = editing;
                movesCard.hidden = false;
                compactColumn.percentHeight = editing ? null : 100;
                if (movesOpen && movesCard.parentComponent == null)
                    addComponent(movesCard);
                else if (!movesOpen && movesCard.parentComponent == this)
                    removeComponent(movesCard, false);
            case Medium:
                studyBar.hidden = true;
                moveStrip.hidden = false;
                variationsCard.hidden = shownPanel != Variations;
                movesCard.hidden = shownPanel != Moves;
                studyCard.hidden = shownPanel != Study;
                // all are locked while editing: the card shrinks to its tabs and leaves the height to the editor
                setPanelContentShown(!editing);
                for (card in ([variationsCard, movesCard, studyCard] : Array<Component>))
                {
                    card.percentHeight = editing ? null : 100;
                    card.invalidateComponentLayout(); // a null size alone doesn't return it to its auto height
                }
                rightColumn.hidden = false;
                setColumnFullWidth(rightColumn, expanded);
            default:
                setPanelContentShown(true);
                studyBar.hidden = true;
                studyCard.hidden = !studyShown || expanded;
                variationsCard.hidden = false;
                movesCard.hidden = false;
                rightColumn.hidden = expanded;
                setColumnFullWidth(rightColumn, false);
                setColumnFullWidth(leftColumn, expanded);
        }
        refreshPanelTabs();
    }

    // medium: the tabs head whichever card is shown; moved only once it's shown, as a hidden card doesn't lay out its new child
    private function refreshPanelTabs():Void
    {
        var host:Null<Component> = if (tier != Medium)
            null;
        else switch shownPanel {
            case Moves: movesCard;
            case Study: studyCard;
            default: variationsCard;
        }
        if (panelTabs.parentComponent != host)
        {
            if (panelTabs.parentComponent != null)
                panelTabs.parentComponent.removeComponent(panelTabs, false);
            if (host != null)
                host.addComponentAt(panelTabs, 0);
        }
        panelTabs.hidden = expanded;
        panelTabs.disabled = editing;
        panelTabs.setStudyShown(studyShown);
        panelTabs.setShown(shownPanel);

        var variationsTabbed:Bool = tier == Medium && !expanded; // expanded, the tabs are hidden and the title names the card again
        variationsCard.setTitleShown(!variationsTabbed);
        variationsCard.setClass(StyleClass.ANALYSIS_TABBED, variationsTabbed);
    }

    private function setPanelContentShown(shown:Bool):Void
    {
        variationsCard.setContentShown(shown);
        movesCard.setContentShown(shown);
        studyCard.setContentShown(shown);
    }

    private function resetMovesSize():Void
    {
        movesCard.height = null;
        movesCard.percentHeight = 100;
        movesCard.verticalAlign = null;
    }

    private function setColumnFullWidth(column:VBox, full:Bool):Void
    {
        if (full)
        {
            column.width = null;
            column.percentWidth = 100;
        }
        else
        {
            column.percentWidth = null;
            column.width = SIDE_COLUMN_WIDTH;
        }
    }

    private function detachParts():Void
    {
        for (part in ([studyCard, studyBar, variationsCard, stage, moveStrip, movesCard, actionsCard, editorCard] : Array<Component>))
            if (part.parentComponent != null)
                part.parentComponent.removeComponent(part, false);
        for (container in [leftColumn, rightColumn, wideRow, compactColumn])
            if (container.parentComponent != null)
                container.parentComponent.removeComponent(container, false);
    }

    private function createSideColumn():VBox
    {
        var column:VBox = new VBox();
        column.width = SIDE_COLUMN_WIDTH;
        column.percentHeight = 100;
        column.addClass(StyleClass.GAME_SIDE_COLUMN);
        return column;
    }
}
