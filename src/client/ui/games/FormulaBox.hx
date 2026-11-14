package client.ui.games;

import client.datatypes.games.Condition;
import client.datatypes.games.ConditionGroup;
import client.datatypes.games.FormulaNode;
import client.datatypes.games.GroupKind;
import client.logic.games.FormulaCaps;
import client.logic.games.FormulaCaps.FormulaCounts;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Absolute;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.ScrollView;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxefolio.LocaleUtils;

using client.ui.ComponentExtension;

/**
    The card holding the formula as a tree of condition pills and group keywords. Collapsed, it has
    a fixed height and scrolls; expanded, it grows with the formula. Deleting a condition or a group
    happens in place; adding and editing are left to the owner.
**/
class FormulaBox extends VBox
{
    private static inline final COLLAPSED_HEIGHT:Float = 248;
    private static inline final CONNECTOR_WIDTH:Float = 22;
    private static inline final ROW_CENTER:Float = 22; // the 6 px gap above a row plus half its 32 px height
    private static inline final BRANCH_LENGTH:Float = 16;

    private final tree:VBox;
    private final scroller:ScrollView;
    private final countLabel:Label;
    private final toggleLabel:Label;
    private final toggleChevron:Image;

    private var root:ConditionGroup = ConditionGroup.emptyRoot();
    private var counts:FormulaCounts;
    private var expanded:Bool = false;

    /** After a deletion changed the formula **/
    public var onChanged:Void->Void = () -> {};
    /** "Add condition" or "Specify condition" pressed: the group to add to, the pressed button **/
    public var onAddRequested:(ConditionGroup, Component)->Void = (_, _) -> {};
    /** A pill pressed: its condition and the pill **/
    public var onEditRequested:(Condition, Component)->Void = (_, _) -> {};

    public function new()
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.GAMES_FORMULA_CARD);

        tree = new VBox();
        tree.percentWidth = 100;
        tree.addClass(StyleClass.GAMES_FORMULA_TREE);

        scroller = new ScrollView();
        scroller.percentWidth = 100;
        scroller.height = COLLAPSED_HEIGHT;
        scroller.scrollMode = NATIVE;
        scroller.percentContentWidth = 100;
        scroller.addClass(StyleClass.GAMES_FORMULA_SCROLLER);
        scroller.addComponent(tree);
        addComponent(scroller);

        var footer:HBox = new HBox();
        footer.percentWidth = 100;
        footer.addClass(StyleClass.GAMES_FORMULA_FOOTER);
        addComponent(footer);

        countLabel = new Label();
        countLabel.percentWidth = 100;
        countLabel.addClass(StyleClass.GAMES_FORMULA_COUNT);
        countLabel.verticalAlign = "center";
        footer.addComponent(countLabel);

        var toggle:HBox = new HBox();
        toggle.addClass(StyleClass.GAMES_SMALL_BUTTON);
        toggle.verticalAlign = "center";
        toggle.trackHover();
        toggle.registerEvent(MouseEvent.CLICK, _ -> setExpanded(!expanded));
        footer.addComponent(toggle);

        toggleLabel = new Label();
        toggleLabel.addClass(StyleClass.GAMES_BUTTON_TEXT);
        toggleLabel.verticalAlign = "center";
        toggle.addComponent(toggleLabel);

        toggleChevron = new Image();
        toggleChevron.verticalAlign = "center";
        toggle.addComponent(toggleChevron);

        setExpanded(false);
        render();
    }

    /** Shows `root`, which the box edits in place from now on **/
    public function setFormula(root:ConditionGroup):Void
    {
        this.root = root;
        render();
    }

    public function render():Void
    {
        counts = FormulaCaps.count(root);
        tree.removeAllComponents();

        tree.addComponent(keywordRow(root, true));
        tree.addComponent(childrenColumn(root, 1));

        countLabel.text = LocaleUtils.localeBinding("intellector.games.formula.count", Std.string(counts.leaves), Std.string(FormulaCaps.MAX_LEAVES));
    }

    private function setExpanded(expanded:Bool):Void
    {
        this.expanded = expanded;
        toggleLabel.text = LocaleUtils.localeBinding(expanded ? "intellector.games.formula.collapse" : "intellector.games.formula.expand");
        toggleChevron.resource = Assets.gamesIcon(expanded ? "chevron_up" : "chevron_down");

        if (expanded && tree.parentComponent == scroller.contents)
        {
            scroller.removeComponent(tree, false);
            removeComponent(scroller, false);
            addComponentAt(tree, 0);
        }
        else if (!expanded && tree.parentComponent == this)
        {
            removeComponent(tree, false);
            scroller.addComponent(tree);
            addComponentAt(scroller, 0);
        }
    }

    /** The children of `group`, at `depth` (the root being 1), with the trailing "Add condition" of AND and OR **/
    private function childrenColumn(group:ConditionGroup, depth:Int):VBox
    {
        var column:VBox = new VBox();
        column.percentWidth = 100;
        column.addClass(StyleClass.GAMES_FORMULA_CHILDREN);

        var items:Array<Component> = [for (child in group.children) nodeContent(child, group, depth)];
        if (group.kind != NOT)
            items.push(addButton(group, depth, false));

        for (i in 0...items.length)
            column.addComponent(branch(items[i], i == items.length - 1));
        return column;
    }

    /** `content` with the tree lines leading to it from its parent **/
    private function branch(content:Component, last:Bool):HBox
    {
        var wrapper:HBox = new HBox();
        wrapper.percentWidth = 100;
        wrapper.addClass(StyleClass.GAMES_FORMULA_BRANCH);

        var connector:Absolute = new Absolute();
        connector.width = CONNECTOR_WIDTH;
        connector.percentHeight = 100;

        var trunk:Box = new Box();
        trunk.addClass(StyleClass.GAMES_FORMULA_LINE);
        trunk.left = 0;
        trunk.top = 0;
        trunk.width = 1;
        if (last)
            trunk.height = ROW_CENTER;
        else
            trunk.percentHeight = 100;
        connector.addComponent(trunk);

        var twig:Box = new Box();
        twig.addClass(StyleClass.GAMES_FORMULA_LINE);
        twig.left = 0;
        twig.top = ROW_CENTER;
        twig.width = BRANCH_LENGTH;
        twig.height = 1;
        connector.addComponent(twig);

        wrapper.addComponent(connector);

        var holder:VBox = new VBox();
        holder.percentWidth = 100;
        holder.addClass(StyleClass.GAMES_FORMULA_BRANCH_CONTENT);
        holder.addComponent(content);
        wrapper.addComponent(holder);
        return wrapper;
    }

    private function nodeContent(node:FormulaNode, parent:ConditionGroup, depth:Int):Component
    {
        switch node
        {
            case Leaf(condition):
                var row:HBox = createRow();
                row.addComponent(createPill(condition, parent));
                return row;
            case Group(group):
                var content:VBox = new VBox();
                content.addClass(StyleClass.GAMES_FORMULA_GROUP);
                var row:HBox = keywordRow(group, false);
                content.addComponent(row);

                var inlineChild:Null<FormulaNode> = group.kind == NOT ? group.children[0] : null;
                switch inlineChild
                {
                    case null if (group.kind == NOT):
                        row.addComponentAt(addButton(group, depth + 1, true), 1);
                    case Leaf(condition):
                        row.addComponentAt(createPill(condition, group), 1);
                    case null | Group(_):
                        content.addComponent(childrenColumn(group, depth + 1));
                }
                return content;
        }
    }

    /** A group's keyword with the cross deleting the group, or the root's bare keyword **/
    private function keywordRow(group:ConditionGroup, isRoot:Bool):HBox
    {
        var row:HBox = createRow();

        var keyword:Label = new Label();
        keyword.text = keywordText(group.kind);
        keyword.addClass(isRoot ? StyleClass.GAMES_KEYWORD_ROOT : StyleClass.GAMES_KEYWORD);
        keyword.verticalAlign = "center";
        row.addComponent(keyword);

        if (!isRoot)
            row.addComponent(ConditionPill.createDeleteButton(StyleClass.GAMES_GROUP_CROSS, () -> delete(Group(group))));
        return row;
    }

    private function createRow():HBox
    {
        var row:HBox = new HBox();
        row.addClass(StyleClass.GAMES_FORMULA_ROW);
        return row;
    }

    private function createPill(condition:Condition, parent:ConditionGroup):ConditionPill
    {
        var pill:Null<ConditionPill> = null;
        pill = new ConditionPill(condition, edited -> onEditRequested(edited, pill), _ -> delete(Leaf(condition)));
        return pill;
    }

    /** "Add condition" under an AND or OR at `depth`, "Specify condition" beside a NOT; disabled at a cap, saying which **/
    private function addButton(group:ConditionGroup, depth:Int, specify:Bool):HBox
    {
        var button:HBox = new HBox();
        button.addClass(StyleClass.GAMES_ADD_BUTTON);
        button.verticalAlign = "center";

        var blockingCap:Null<String> = blockingCapKey();
        var icon:Image = new Image();
        icon.resource = Assets.gamesIcon(blockingCap != null ? "plus_disabled" : "plus");
        icon.verticalAlign = "center";
        button.addComponent(icon);

        var label:Label = new Label();
        label.text = LocaleUtils.localeBinding(specify ? "intellector.games.formula.specify_condition" : "intellector.games.formula.add_condition");
        label.addClass(StyleClass.GAMES_ADD_BUTTON_TEXT);
        label.verticalAlign = "center";
        button.addComponent(label);

        if (blockingCap != null)
        {
            button.addClass(StyleClass.GAMES_ADD_BUTTON_DISABLED);
            button.tooltip = blockingCap;
        }
        else
        {
            button.trackHover();
            button.registerEvent(MouseEvent.CLICK, _ -> onAddRequested(group, button));
        }

        if (!specify)
        {
            var row:HBox = createRow();
            row.addComponent(button);
            return row;
        }
        return button;
    }

    /** The cap leaving no room for another condition, as a locale binding; null while there is room **/
    private function blockingCapKey():Null<String>
    {
        if (counts.nodes >= FormulaCaps.MAX_NODES)
            return LocaleUtils.localeBinding("intellector.games.cap.nodes", Std.string(FormulaCaps.MAX_NODES));
        if (counts.leaves >= FormulaCaps.MAX_LEAVES)
            return LocaleUtils.localeBinding("intellector.games.cap.leaves", Std.string(FormulaCaps.MAX_LEAVES));
        return null;
    }

    private function delete(node:FormulaNode):Void
    {
        if (removeFrom(root, node))
        {
            render();
            onChanged();
        }
    }

    private static function removeFrom(group:ConditionGroup, node:FormulaNode):Bool
    {
        for (i in 0...group.children.length)
        {
            var child:FormulaNode = group.children[i];
            if (sameNode(child, node))
            {
                group.children.splice(i, 1);
                return true;
            }
            switch child
            {
                case Group(subgroup):
                    if (removeFrom(subgroup, node))
                        return true;
                case Leaf(_):
            }
        }
        return false;
    }

    private static function sameNode(a:FormulaNode, b:FormulaNode):Bool
    {
        return switch [a, b] {
            case [Leaf(first), Leaf(second)]: first == second;
            case [Group(first), Group(second)]: first == second;
            default: false;
        }
    }

    private static function keywordText(kind:GroupKind):String
    {
        return LocaleUtils.localeBinding('intellector.games.keyword.$kind');
    }
}
