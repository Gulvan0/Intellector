package client.ui.games.flow;

import client.datatypes.game.Outcome.DecisiveOutcomeKind;
import client.datatypes.game.Outcome.DrawishOutcomeKind;
import client.datatypes.games.BotFilter;
import client.datatypes.games.Condition;
import client.datatypes.games.ConditionGroup;
import client.datatypes.games.ConditionOperator;
import client.datatypes.games.ConditionParameter;
import client.datatypes.games.DateTimeBound;
import client.datatypes.games.EqualityValue;
import client.datatypes.games.FormulaNode;
import client.datatypes.games.GameProperty;
import client.datatypes.games.GroupKind;
import client.datatypes.games.LocalDateTime;
import client.datatypes.games.Operand;
import client.datatypes.games.OperandType;
import client.datatypes.games.ParameterType;
import client.datatypes.games.PlayerValue;
import client.datatypes.games.ResultKind;
import client.datatypes.timecontrol.TimeControlKind;
import client.formatters.ArchiveFormatters;
import client.formatters.GameFormatters;
import client.logic.games.FormulaCaps;
import client.logic.games.FormulaCaps.FormulaCounts;
import client.logic.games.PropertyCatalog;
import client.openings.OpeningTree;
import client.ui.games.FormulaBox;
import haxe.ui.components.Label;
import haxe.ui.core.Component;
import haxefolio.LocaleUtils;

/** The first step's choice **/
enum KindChoice
{
    PropertyKind(property:GameProperty);
    GroupKindChoice(kind:GroupKind);
}

private enum Stage
{
    Kind;
    Parameter;
    Operator;
    OperandAt(index:Int);
    Values;
}

/**
    Adding or editing a condition, step by step. The condition being built stands in the formula
    from the property's choice on, showing each choice as it is made; going back shrinks it again.
    Cancelling removes it (adding) or restores the condition as it was (editing).
**/
class ConditionFlow
{
    private static inline final KIND_WIDTH:Float = 300;
    private static inline final KIND_MAX_HEIGHT:Float = 560;
    private static inline final PARAMETER_WIDTH:Float = 220;
    private static inline final OPERATOR_WIDTH:Float = 260;
    private static inline final VALUES_WIDTH:Float = 300;
    private static inline final VALUES_MAX_HEIGHT:Float = 333;

    private static final GROUPS:Array<{heading:String, properties:Array<GameProperty>}> = [
        {heading: "game", properties: [STARTED_AT, ENDED_AT, DURATION, MOVE_CNT, RATED, RESULT, OUTCOME, WINNER, STARTING_POSITION, OPENING]},
        {heading: "time_control", properties: [TIME_CONTROL_KIND, INITIAL_TIME, BONUS_TIME, TIME_LEFT]},
        {heading: "players", properties: [PLAYER, ELO, ELO_PROVISIONAL]}
    ];

    private final box:FormulaBox;
    private final root:ConditionGroup;
    private final parent:ConditionGroup;
    private final onFinished:Void->Void;
    private final surface:StepSurface;
    /** Editing: the condition as it was **/
    private final original:Null<Condition>;
    private final narrow:Bool;

    /** In the formula from the property's choice on **/
    private var shown:Null<Condition> = null;
    /** Every choice made so far, including those of the steps gone back from **/
    private var memory:Null<Condition> = null;
    private var finished:Bool = false;

    /** Starts adding a condition to `parent`, from its "Add condition" (or "Specify condition") button `anchor` **/
    public static function add(box:FormulaBox, root:ConditionGroup, parent:ConditionGroup, anchor:Component, page:Component, narrow:Bool, onFinished:Void->Void):ConditionFlow
    {
        var flow:ConditionFlow = new ConditionFlow(box, root, parent, null, anchor, page, narrow, onFinished);
        flow.goTo(Kind);
        return flow;
    }

    /** Starts editing `condition`, from its pill `anchor` **/
    public static function edit(box:FormulaBox, root:ConditionGroup, condition:Condition, anchor:Component, page:Component, narrow:Bool, onFinished:Void->Void):ConditionFlow
    {
        var parent:Null<ConditionGroup> = parentOf(root, condition);
        if (parent == null)
            throw "The edited condition is not in the formula";

        var flow:ConditionFlow = new ConditionFlow(box, root, parent, condition, anchor, page, narrow, onFinished);
        flow.memory = condition.copy();
        flow.shown = condition.copy();
        flow.replaceInParent(condition, flow.shown);
        flow.goTo(flow.firstPropertyStage());
        return flow;
    }

    private function new(box:FormulaBox, root:ConditionGroup, parent:ConditionGroup, original:Null<Condition>, anchor:Component, page:Component, narrow:Bool, onFinished:Void->Void)
    {
        this.box = box;
        this.root = root;
        this.parent = parent;
        this.original = original;
        this.narrow = narrow;
        this.onFinished = onFinished;
        FlowLayout.narrow = narrow;
        surface = narrow ? new SheetSurface(cancel) : new PopoverSurface(page, anchor, cancel);
    }

    /** Ends the flow as if cancelled, without the surface reporting it (the page closing) **/
    public function abort():Void
    {
        if (finished)
            return;
        surface.close();
        cancel();
    }

    private function cancel():Void
    {
        if (finished)
            return;
        finished = true;

        if (shown != null)
            if (original != null)
                replaceInParent(shown, original);
            else
                removeFromParent(shown);
        box.editing = null;
        box.render();
        onFinished();
    }

    private function commit():Void
    {
        finished = true;
        surface.close();
        shown.parameter = memory.parameter;
        shown.conditionOperator = memory.conditionOperator;
        shown.operands = memory.operands.copy();
        shown.values = memory.values.copy();
        box.editing = null;
        box.render();
        onFinished();
    }

    private function addGroup(kind:GroupKind):Void
    {
        finished = true;
        surface.close();
        parent.children.push(Group(new ConditionGroup(kind)));
        box.render();
        onFinished();
    }

    // Stages

    private function firstPropertyStage():Stage
    {
        if (PropertyCatalog.parameterType(memory.property) != null)
            return Parameter;
        return PropertyCatalog.isOperatorProperty(memory.property) ? Operator : Values;
    }

    /** The stage after `stage`; null once the condition is complete **/
    private function nextStage(stage:Stage):Null<Stage>
    {
        var property:GameProperty = memory.property;
        return switch stage {
            case Kind: firstPropertyStage();
            case Parameter: PropertyCatalog.isOperatorProperty(property) ? Operator : Values;
            case Operator: PropertyCatalog.operandCount(memory.conditionOperator) > 0 ? OperandAt(0) : null;
            case OperandAt(index): index + 1 < PropertyCatalog.operandCount(memory.conditionOperator) ? OperandAt(index + 1) : null;
            case Values: null;
        }
    }

    /** The stage `←` returns to; null for the flow's first one **/
    private function previousStage(stage:Stage):Null<Stage>
    {
        var previous:Null<Stage> = switch stage {
            case Kind: null;
            case Parameter: Kind;
            case Operator | Values: PropertyCatalog.parameterType(memory.property) != null ? Parameter : Kind;
            case OperandAt(0): Operator;
            case OperandAt(index): OperandAt(index - 1);
        }
        return original != null && previous == Kind ? null : previous;
    }

    private function advance(stage:Stage):Void
    {
        var next:Null<Stage> = nextStage(stage);
        if (next == null)
            commit();
        else
            goTo(next);
    }

    private function goTo(stage:Stage):Void
    {
        showPrefix(stage);
        var previous:Null<Stage> = previousStage(stage);
        var back:Null<Void->Void> = previous != null ? goTo.bind(previous) : null;
        surface.show(switch stage {
            case Kind: kindStep();
            case Parameter: parameterStep(back);
            case Operator: operatorStep(back);
            case OperandAt(index): operandStep(index, back);
            case Values: valuesStep(back);
        });
    }

    /** Shows in the formula the choices made before `stage` **/
    private function showPrefix(stage:Stage):Void
    {
        if (stage == Kind)
        {
            if (shown != null)
                removeFromParent(shown);
            shown = null;
            box.editing = null;
            box.render();
            surface.reanchor(box.addButtonOf(parent));
            return;
        }

        if (shown == null)
        {
            shown = new Condition(memory.property);
            parent.children.push(Leaf(shown));
        }
        var past:Array<Stage> = [];
        var cursor:Null<Stage> = firstPropertyStage();
        while (cursor != null && !Type.enumEq(cursor, stage))
        {
            past.push(cursor);
            cursor = nextStage(cursor);
        }

        shown.parameter = past.contains(Parameter) ? memory.parameter : null;
        shown.conditionOperator = past.contains(Operator) ? memory.conditionOperator : null;
        var operandCount:Int = 0;
        for (pastStage in past)
            switch pastStage
            {
                case OperandAt(_):
                    operandCount++;
                default:
            }
        shown.operands = memory.operands.slice(0, operandCount);
        shown.values = [];

        box.editing = shown;
        box.render();
        surface.reanchor(box.pillOf(shown));
    }

    // Steps

    private function kindStep():FlowStep
    {
        var counts:FormulaCounts = FormulaCaps.count(root);
        var entries:Array<ChoiceEntry<KindChoice>> = [];
        for (group in GROUPS)
        {
            entries.push(Heading(text('intellector.games.step.kind.${group.heading}')));
            for (property in group.properties)
            {
                var reason:Null<Void->String> = PropertyCatalog.isCostly(property) && !FormulaCaps.canAddCostlyLeaf(counts) ? text("intellector.games.cap.costly", Std.string(FormulaCaps.MAX_COSTLY_LEAVES)) : null;
                entries.push(Fixed(PropertyKind(property), () -> ArchiveFormatters.propertyName(property), null, null, reason));
            }
        }

        entries.push(Heading(text("intellector.games.step.kind.groups")));
        var parentDepth:Int = depthOf(root, parent, 1);
        for (kind in [AND, OR, NOT])
        {
            var reason:Null<Void->String> = null;
            if (kind == parent.kind)
                reason = () -> LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.games.step.kind.already_inside"), keyword(kind));
            else if (counts.nodes >= FormulaCaps.MAX_NODES)
                reason = text("intellector.games.cap.nodes", Std.string(FormulaCaps.MAX_NODES));
            else if (!FormulaCaps.canAddGroup(counts, parentDepth))
                reason = text("intellector.games.cap.depth", Std.string(FormulaCaps.MAX_DEPTH));
            entries.push(Fixed(GroupKindChoice(kind), keyword.bind(kind), null, null, reason));
        }

        var list:ChoiceList<KindChoice> = ChoiceList.single(entries, null, choice -> switch choice {
            case PropertyKind(property):
                memory = new Condition(property);
                advance(Kind);
            case GroupKindChoice(kind):
                addGroup(kind);
        }, Type.enumEq, FlowLayout.listWidth(KIND_WIDTH), FlowLayout.listHeight(KIND_MAX_HEIGHT));
        return new FlowStep(null, list.content);
    }

    private function parameterStep(back:Null<Void->Void>):FlowStep
    {
        var property:GameProperty = memory.property;
        var title:Void->String = text('intellector.games.step.parameter.$property');
        var type:ParameterType = PropertyCatalog.parameterType(property);

        var entries:Array<ChoiceEntry<ConditionParameter>> = [];
        if (type == OptionalColor)
            entries.push(Fixed(EitherColor, text("intellector.games.step.parameter.any"), Assets.gamesIcon("color_any")));
        var colorKey:String = type == OptionalColor ? "intellector.games.step.parameter.color" : "intellector.games.step.parameter";
        entries.push(Fixed(OfColor(White), text('$colorKey.white'), Assets.gamesIcon("color_white")));
        entries.push(Fixed(OfColor(Black), text('$colorKey.black'), Assets.gamesIcon("color_black")));
        if (type != OptionalColor)
            for (entry in playerEntries(title, type == UserOrColor, OfPlayer, parameter -> switch parameter {
                case OfPlayer(player): player;
                default: null;
            }))
                entries.push(entry);

        var list:ChoiceList<ConditionParameter> = ChoiceList.single(entries, memory.parameter, parameter -> {
            memory.parameter = parameter;
            advance(Parameter);
        }, Type.enumEq, FlowLayout.listWidth(PARAMETER_WIDTH), null);
        return new FlowStep(title, list.content, null, back);
    }

    private function operatorStep(back:Null<Void->Void>):FlowStep
    {
        var property:GameProperty = memory.property;
        var type:OperandType = PropertyCatalog.operandType(property);
        var entries:Array<ChoiceEntry<ConditionOperator>> = [
            for (conditionOperator in PropertyCatalog.operators(property))
                ChoiceEntry.Fixed(conditionOperator, operatorLabel(conditionOperator, type), null, () -> ArchiveFormatters.operatorSymbol(conditionOperator, true))
        ];

        var list:ChoiceList<ConditionOperator> = ChoiceList.single(entries, memory.conditionOperator, conditionOperator -> {
            memory.conditionOperator = conditionOperator;
            advance(Operator);
        }, Type.enumEq, FlowLayout.listWidth(OPERATOR_WIDTH), null);

        var footnote:Null<Component> = null;
        if (PropertyCatalog.allowsUnknown(property))
        {
            var note:Label = new Label();
            note.percentWidth = 100;
            note.text = LocaleUtils.localeBinding("intellector.games.step.operator.unknown_note");
            note.addClass(StyleClass.GAMES_STEP_NOTE);
            footnote = note;
        }
        return new FlowStep(subjectTitle(), list.content, footnote, back);
    }

    private function operandStep(index:Int, back:Null<Void->Void>):FlowStep
    {
        var property:GameProperty = memory.property;
        var conditionOperator:ConditionOperator = memory.conditionOperator;
        var between:Bool = conditionOperator == BETWEEN;
        var title:Void->String = () -> {
            var head:String = ArchiveFormatters.conditionSubject(property, memory.parameter) + " " + ArchiveFormatters.operatorSymbol(conditionOperator, false);
            if (!between)
                return head;
            return LocaleUtils.resolveText(LocaleUtils.localeBinding(index == 0 ? "intellector.games.step.lower_bound" : "intellector.games.step.upper_bound"), head);
        };
        var initial:Null<Operand> = memory.operands[index];
        var lower:Null<Operand> = between && index == 1 ? memory.operands[0] : null;
        var onValue:Operand->Void = operand -> {
            memory.operands[index] = operand;
            if (between && index == 0 && memory.operands.length > 1 && !aboveLowerBound(memory.operands[1], operand))
                memory.operands.splice(1, 1);
            advance(OperandAt(index));
        };

        return switch PropertyCatalog.operandType(property) {
            case DateTimeOperand:
                var bound:DateTimeBound = switch conditionOperator {
                    case LT: Before;
                    case GT: After;
                    default: index == 0 ? FromInclusive : UpToInclusive;
                }
                DateTimeStep.create(title, bound, switch initial {
                    case DateTimeValue(value): value;
                    default: null;
                }, back, value -> onValue(DateTimeValue(value)));
            case DurationOperand:
                DurationStep.create(property, title, switch initial {
                    case DurationValue(ms): ms;
                    default: null;
                }, back, ms -> onValue(DurationValue(ms)), switch lower {
                    case DurationValue(ms): ms;
                    default: null;
                });
            case IntOperand:
                TextSteps.wholeNumber(title, LocaleUtils.localeBinding('intellector.games.step.number.label.$property'), 0, switch initial {
                    case IntValue(value): value;
                    default: null;
                }, back, value -> onValue(IntValue(value)), switch lower {
                    case IntValue(value): value;
                    default: null;
                });
        }
    }

    private function valuesStep(back:Null<Void->Void>):FlowStep
    {
        var property:GameProperty = memory.property;
        var title:Void->String = subjectTitle();
        var entries:Array<ChoiceEntry<EqualityValue>> = valueEntries(property, title);

        if (PropertyCatalog.isSingleValued(property))
        {
            var list:ChoiceList<EqualityValue> = ChoiceList.single(entries, memory.values[0], value -> {
                memory.values = [value];
                advance(Values);
            }, Type.enumEq, FlowLayout.listWidth(PARAMETER_WIDTH), null);
            return new FlowStep(title, list.content, null, back);
        }

        var list:ChoiceList<EqualityValue> = ChoiceList.multi(entries, {
            ticked: memory.values,
            onConfirm: values -> {
                memory.values = values;
                advance(Values);
            },
            labelOf: ArchiveFormatters.valueText,
            maxTicked: FormulaCaps.MAX_VALUES_PER_LEAF,
            capReason: LocaleUtils.localeBinding("intellector.games.cap.values", Std.string(FormulaCaps.MAX_VALUES_PER_LEAF))
        }, Type.enumEq, FlowLayout.listWidth(VALUES_WIDTH), FlowLayout.listHeight(VALUES_MAX_HEIGHT));
        return new FlowStep(title, list.content, list.footer, back);
    }

    private function valueEntries(property:GameProperty, title:Void->String):Array<ChoiceEntry<EqualityValue>>
    {
        var playerOf:EqualityValue->Null<PlayerValue> = value -> switch value {
            case IsPlayer(player): player;
            default: null;
        };
        var label:EqualityValue->(Void->String) = value -> () -> ArchiveFormatters.valueText(value);

        return switch property {
            case PLAYER:
                playerEntries(title, false, IsPlayer, playerOf);
            case WINNER:
                [ChoiceEntry.Fixed(IsOngoing, label(IsOngoing)), ChoiceEntry.Fixed(IsDraw, label(IsDraw)), ChoiceEntry.Separator].concat(playerEntries(title, false, IsPlayer, playerOf));
            case TIME_CONTROL_KIND:
                [for (kind in Type.allEnums(TimeControlKind)) ChoiceEntry.Fixed(IsTimeControlKind(kind), label(IsTimeControlKind(kind)), Assets.timeControlKindIcon(kind))];
            case RATED | ELO_PROVISIONAL:
                [ChoiceEntry.Fixed(IsBool(true), label(IsBool(true))), ChoiceEntry.Fixed(IsBool(false), label(IsBool(false)))];
            case OUTCOME:
                var decisive:Array<ChoiceEntry<EqualityValue>> = [for (kind in Type.allEnums(DecisiveOutcomeKind)) ChoiceEntry.Fixed(IsDecisiveOutcome(kind), label(IsDecisiveOutcome(kind)))];
                var drawish:Array<ChoiceEntry<EqualityValue>> = [for (kind in Type.allEnums(DrawishOutcomeKind)) ChoiceEntry.Fixed(IsDrawishOutcome(kind), label(IsDrawishOutcome(kind)))];
                decisive.concat(drawish);
            case STARTING_POSITION:
                var owns:EqualityValue->Bool = value -> value.match(IsCustomPosition(_));
                [
                    ChoiceEntry.Fixed(IsDefaultPosition, label(IsDefaultPosition)),
                    Separator,
                    Appended(text("intellector.games.step.appended.sip"), null, (row, take) -> prompt(TextSteps.sip(promptTitle("sip"), null, surface.closePrompt, sip -> take(IsCustomPosition(sip))), row), owns)
                ];
            case OPENING:
                var ids:Array<Int> = [for (id in OpeningTree.byId.keys()) id];
                ids.sort((a, b) -> a - b);
                [for (id in ids) ChoiceEntry.Fixed(IsOpening(id), label(IsOpening(id)))];
            case RESULT:
                [for (result in [ResultKind.ONGOING, ResultKind.WHITE_WON, ResultKind.BLACK_WON, ResultKind.DRAW]) ChoiceEntry.Fixed(IsResult(result), label(IsResult(result)))];
            default:
                throw 'Not an equality property: $property';
        }
    }

    /** +User, plus +Guest and +Bot unless `usersOnly`, wrapping the player as the list's value **/
    private function playerEntries<T>(title:Void->String, usersOnly:Bool, wrap:PlayerValue->T, unwrap:T->Null<PlayerValue>):Array<ChoiceEntry<T>>
    {
        var entries:Array<ChoiceEntry<T>> = [
            Appended(text("intellector.games.step.appended.user"), Assets.playerKindIcon("user"), (row, take) -> {
                prompt(TextSteps.user(promptTitle("user"), null, surface.closePrompt, narrow, login -> take(wrap(User(login)))), row);
            }, value -> playerKindOf(unwrap(value)) == "user")
        ];
        if (usersOnly)
            return entries;

        entries.push(Appended(text("intellector.games.step.appended.guest"), Assets.playerKindIcon("guest"), (row, take) -> {
            prompt(TextSteps.guest(promptTitle("guest"), null, surface.closePrompt, id -> take(wrap(Guest(id)))), row);
        }, value -> playerKindOf(unwrap(value)) == "guest"));

        entries.push(Appended(text("intellector.games.step.appended.bot"), Assets.playerKindIcon("bot"), (row, take) -> {
            var show:FlowStep->Void = step -> prompt(step, row);
            show(BotSteps.family(promptTitle("bot"), null, surface.closePrompt, show, (filter:BotFilter) -> take(wrap(Bot(filter)))));
        }, value -> playerKindOf(unwrap(value)) == "bot"));
        return entries;
    }

    /** Shows an appended option's prompt; its value closes it **/
    private function prompt(step:FlowStep, row:Component):Void
    {
        surface.showPrompt(step, row);
    }

    // Formula editing

    private function removeFromParent(condition:Condition):Void
    {
        for (i in 0...parent.children.length)
            switch parent.children[i]
            {
                case Leaf(child) if (child == condition):
                    parent.children.splice(i, 1);
                    return;
                default:
            }
    }

    private function replaceInParent(condition:Condition, replacement:Condition):Void
    {
        for (i in 0...parent.children.length)
            switch parent.children[i]
            {
                case Leaf(child) if (child == condition):
                    parent.children[i] = Leaf(replacement);
                    return;
                default:
            }
    }

    private static function parentOf(group:ConditionGroup, condition:Condition):Null<ConditionGroup>
    {
        for (child in group.children)
            switch child
            {
                case Leaf(leaf) if (leaf == condition):
                    return group;
                case Group(subgroup):
                    var found:Null<ConditionGroup> = parentOf(subgroup, condition);
                    if (found != null)
                        return found;
                default:
            }
        return null;
    }

    /** The depth of `target` (the root being at 1); 0 if it isn't in the formula **/
    private static function depthOf(group:ConditionGroup, target:ConditionGroup, depth:Int):Int
    {
        if (group == target)
            return depth;
        for (child in group.children)
            switch child
            {
                case Group(subgroup):
                    var found:Int = depthOf(subgroup, target, depth + 1);
                    if (found > 0)
                        return found;
                default:
            }
        return 0;
    }

    /** `user`, `guest` or `bot`; null for no player **/
    private static function playerKindOf(player:Null<PlayerValue>):Null<String>
    {
        if (player == null)
            return null;
        return switch player {
            case User(_): "user";
            case Guest(_): "guest";
            case Bot(_): "bot";
        }
    }

    private static function aboveLowerBound(upper:Operand, lower:Operand):Bool
    {
        return switch [upper, lower] {
            case [DurationValue(upperMs), DurationValue(lowerMs)]: upperMs > lowerMs;
            case [IntValue(upperValue), IntValue(lowerValue)]: upperValue > lowerValue;
            default: true;
        }
    }

    // Texts

    private function subjectTitle():Void->String
    {
        return () -> ArchiveFormatters.conditionSubject(memory.property, memory.parameter);
    }

    /** `Winner · user` **/
    private function promptTitle(kind:String):Void->String
    {
        var property:GameProperty = memory.property;
        return () -> LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.games.step.prompt_title"), ArchiveFormatters.propertyName(property), LocaleUtils.resolveText(LocaleUtils.localeBinding('intellector.games.step.prompt_kind.$kind')));
    }

    private static function operatorLabel(conditionOperator:ConditionOperator, type:OperandType):Void->String
    {
        var family:String = type == DateTimeOperand ? "date" : "number";
        return text('intellector.games.step.operator.$family.$conditionOperator');
    }

    private static function keyword(kind:GroupKind):String
    {
        return LocaleUtils.resolveText(LocaleUtils.localeBinding('intellector.games.keyword.$kind'));
    }

    private static function text(key:String, ?parameter:String):Void->String
    {
        return () -> LocaleUtils.resolveText(LocaleUtils.localeBinding(key, parameter));
    }
}
