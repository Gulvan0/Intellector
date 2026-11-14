package client.ui.games.flow;

import client.datatypes.games.DateTimeBound;
import client.datatypes.games.EventDay;
import client.datatypes.games.LocalDateTime;
import client.datatypes.games.TimeOfDay;
import client.formatters.ArchiveFormatters;
import client.logic.games.EventDays;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;
import haxefolio.structure.ScrollArea;

using client.ui.ComponentExtension;

/**
    A `DateTime` operand: a day from the calendar or the event days, optionally with a time. A hint
    says what the operand resolves to under its operator.
**/
class DateTimeStep
{
    private static inline final BODY_WIDTH:Float = 308;
    private static inline final WIDE_SLOT_HEIGHT:Float = 300;
    private static inline final NARROW_SLOT_HEIGHT:Float = 374;
    private static inline final ROWS:Int = 6;
    private static inline final DAYS_IN_WEEK:Int = 7;

    private final bound:DateTimeBound;
    private final footer:StepFooter;
    private final calendarTab:Box;
    private final eventsTab:Box;
    private final calendarPane:VBox;
    private final eventsPane:Component;
    private final monthLabel:Label;
    private final grid:VBox;
    private final timeBox:Box;
    private final timeFields:Array<DigitField> = [];
    private final colons:Array<Label> = [];
    private final hint:Label;

    private var viewYear:Int;
    private var viewMonth:Int;
    private var selected:Null<LocalDateTime> = null;
    private var timeOn:Bool = false;

    public static function create(title:Void->String, bound:DateTimeBound, initial:Null<LocalDateTime>, back:Null<Void->Void>, onValue:LocalDateTime->Void):FlowStep
    {
        var step:DateTimeStep = new DateTimeStep(bound, initial, onValue);
        return new FlowStep(title, step.body(), step.footer, back, () -> false);
    }

    private function new(bound:DateTimeBound, initial:Null<LocalDateTime>, onValue:LocalDateTime->Void)
    {
        this.bound = bound;

        var today:Date = Date.now();
        selected = initial != null ? new LocalDateTime(initial.year, initial.month, initial.day) : null;
        viewYear = initial?.year ?? today.getFullYear();
        viewMonth = initial?.month ?? today.getMonth() + 1;
        timeOn = initial?.time != null;

        footer = new StepFooter(() -> {
            var value:Null<LocalDateTime> = value();
            if (value != null)
                onValue(value);
        });
        footer.setInfoMono(true);

        calendarTab = tab("intellector.games.step.date.calendar", () -> showTab(true));
        eventsTab = tab("intellector.games.step.date.events", () -> showTab(false));

        monthLabel = new Label();
        monthLabel.percentWidth = 100;
        monthLabel.addClass(StyleClass.GAMES_CALENDAR_MONTH);
        monthLabel.verticalAlign = "center";

        grid = new VBox();
        grid.percentWidth = 100;
        grid.addClass(StyleClass.GAMES_CALENDAR_GRID);

        calendarPane = new VBox();
        calendarPane.percentWidth = 100;
        calendarPane.addClass(StyleClass.GAMES_CALENDAR);
        calendarPane.addComponent(monthRow());
        calendarPane.addComponent(weekdayRow());
        calendarPane.addComponent(grid);

        eventsPane = eventsList();

        for (i in 0...3)
            timeFields.push(new DigitField(2, refresh, () -> clampTime(i)));
        var time:TimeOfDay = initial?.time ?? new TimeOfDay(0, 0, 0);
        timeFields[0].showPadded(time.hours, 2);
        timeFields[1].showPadded(time.minutes, 2);
        timeFields[2].showPadded(time.seconds, 2);

        timeBox = new Box();
        hint = new Label();
        hint.percentWidth = 100;
        hint.addClass(StyleClass.GAMES_STEP_HINT);

        renderGrid();
        refresh();
    }

    private function body():VBox
    {
        var content:VBox = new VBox();
        content.addClass(StyleClass.GAMES_CALENDAR_BODY);
        FlowLayout.size(content, BODY_WIDTH);

        var tabs:HBox = new HBox();
        tabs.percentWidth = 100;
        tabs.addClass(StyleClass.GAMES_CALENDAR_TABS);
        tabs.addComponent(calendarTab);
        tabs.addComponent(eventsTab);
        content.addComponent(tabs);

        var slot:Box = new Box();
        slot.percentWidth = 100;
        slot.height = FlowLayout.narrow ? NARROW_SLOT_HEIGHT : WIDE_SLOT_HEIGHT;
        slot.addClass(StyleClass.GAMES_CALENDAR_SLOT);
        slot.addComponent(calendarPane);
        slot.addComponent(eventsPane);
        content.addComponent(slot);
        showTab(true);

        var timeSection:VBox = new VBox();
        timeSection.percentWidth = 100;
        timeSection.addClass(StyleClass.GAMES_CALENDAR_TIME_SECTION);
        timeSection.addComponent(timeRow());
        timeSection.addComponent(hint);
        content.addComponent(timeSection);
        return content;
    }

    private function tab(key:String, onClick:Void->Void):Box
    {
        var button:Box = new Box();
        button.percentWidth = 50;
        button.addClass(StyleClass.GAMES_CALENDAR_TAB);
        button.trackHover();
        button.registerEvent(MouseEvent.CLICK, _ -> onClick());

        var caption:Label = new Label();
        caption.text = LocaleUtils.localeBinding(key);
        caption.addClass(StyleClass.GAMES_CALENDAR_TAB_TEXT);
        caption.horizontalAlign = "center";
        caption.verticalAlign = "center";
        button.addComponent(caption);
        return button;
    }

    private function showTab(calendar:Bool):Void
    {
        calendarTab.setClass(StyleClass.GAMES_CALENDAR_TAB_ON, calendar);
        eventsTab.setClass(StyleClass.GAMES_CALENDAR_TAB_ON, !calendar);
        calendarPane.hidden = !calendar;
        eventsPane.hidden = calendar;
    }

    private function monthRow():HBox
    {
        var row:HBox = new HBox();
        row.percentWidth = 100;
        row.addClass(StyleClass.GAMES_CALENDAR_NAVIGATION);
        row.addComponent(navigationButton("year_previous", -12));
        row.addComponent(navigationButton("month_previous", -1));
        row.addComponent(monthLabel);
        row.addComponent(navigationButton("month_next", 1));
        row.addComponent(navigationButton("year_next", 12));
        return row;
    }

    private function navigationButton(icon:String, monthShift:Int):Box
    {
        var button:Box = new Box();
        button.addClass(StyleClass.GAMES_ICON_BUTTON);
        button.verticalAlign = "center";
        button.trackHover();
        button.registerEvent(MouseEvent.CLICK, _ -> shiftView(monthShift));

        var image:Image = new Image();
        image.resource = Assets.gamesIcon(icon);
        image.horizontalAlign = "center";
        image.verticalAlign = "center";
        button.addComponent(image);
        return button;
    }

    private function weekdayRow():HBox
    {
        var row:HBox = new HBox();
        row.percentWidth = 100;
        row.addClass(StyleClass.GAMES_CALENDAR_WEEKDAYS);
        for (i in 1...DAYS_IN_WEEK + 1)
        {
            var label:Label = new Label();
            label.percentWidth = 100 / DAYS_IN_WEEK;
            label.text = LocaleUtils.localeBinding('intellector.games.step.date.weekday.$i');
            label.addClass(StyleClass.GAMES_CALENDAR_WEEKDAY);
            row.addComponent(label);
        }
        return row;
    }

    private function eventsList():Component
    {
        var days:Array<EventDay> = EventDays.all();
        var list:VBox = new VBox();
        list.percentWidth = 100;
        list.addClass(StyleClass.GAMES_CALENDAR_EVENTS);
        for (day in days)
            list.addComponent(eventRow(day));

        var scroller:ScrollArea = new ScrollArea(list);
        scroller.percentHeight = 100;
        return scroller;
    }

    private function eventRow(day:EventDay):HBox
    {
        var row:HBox = new HBox();
        row.percentWidth = 100;
        row.addClass(StyleClass.GAMES_CALENDAR_EVENT);
        row.trackHover();
        row.registerEvent(MouseEvent.CLICK, _ -> {
            selected = new LocalDateTime(day.date.year, day.date.month, day.date.day);
            viewYear = day.date.year;
            viewMonth = day.date.month;
            renderGrid();
            refresh();
            showTab(true);
        });

        var name:Label = new Label();
        name.percentWidth = 100;
        name.addClass(StyleClass.GAMES_CALENDAR_EVENT_NAME);
        name.verticalAlign = "center";
        LocaleManager.instance.registerComponent(name, "text", () -> day.name(LocaleManager.instance.language));
        row.addComponent(name);

        var date:Label = new Label();
        date.text = ArchiveFormatters.localDateTime(day.date);
        date.addClass(StyleClass.GAMES_CALENDAR_EVENT_DATE);
        date.verticalAlign = "center";
        row.addComponent(date);
        return row;
    }

    private function timeRow():HBox
    {
        var row:HBox = new HBox();
        row.percentWidth = 100;
        row.addClass(StyleClass.GAMES_CALENDAR_TIME_ROW);

        var toggle:HBox = new HBox();
        toggle.percentWidth = 100;
        toggle.addClass(StyleClass.GAMES_CALENDAR_TIME_TOGGLE);
        toggle.verticalAlign = "center";
        toggle.registerEvent(MouseEvent.CLICK, _ -> {
            timeOn = !timeOn;
            refresh();
        });

        timeBox.addClass(StyleClass.FILTER_CHECKBOX);
        timeBox.verticalAlign = "center";
        var check:Image = new Image();
        check.resource = Assets.controlIcon("check");
        check.width = 10;
        check.height = 10;
        check.horizontalAlign = "center";
        check.verticalAlign = "center";
        timeBox.addComponent(check);
        toggle.addComponent(timeBox);

        var caption:Label = new Label();
        caption.text = LocaleUtils.localeBinding("intellector.games.step.date.time");
        caption.addClass(StyleClass.FILTER_OPTION_CAPTION);
        caption.verticalAlign = "center";
        toggle.addComponent(caption);
        row.addComponent(toggle);

        for (i in 0...timeFields.length)
        {
            if (i > 0)
            {
                var colon:Label = new Label();
                colon.text = ":";
                colon.addClass(StyleClass.GAMES_CALENDAR_COLON);
                colon.verticalAlign = "center";
                colons.push(colon);
                row.addComponent(colon);
            }
            timeFields[i].verticalAlign = "center";
            row.addComponent(timeFields[i]);
        }
        return row;
    }

    private function shiftView(months:Int):Void
    {
        var index:Int = viewYear * 12 + (viewMonth - 1) + months;
        viewYear = Math.floor(index / 12);
        viewMonth = index - viewYear * 12 + 1;
        renderGrid();
    }

    private function renderGrid():Void
    {
        LocaleManager.instance.registerComponent(monthLabel, "text", () -> LocaleUtils.resolveText(LocaleUtils.localeBinding('intellector.games.step.date.month.$viewMonth')) + ' $viewYear');

        grid.removeAllComponents();
        var offset:Int = (new Date(viewYear, viewMonth - 1, 1, 0, 0, 0).getDay() + 6) % DAYS_IN_WEEK;
        var daysInMonth:Int = DateTools.getMonthDays(new Date(viewYear, viewMonth - 1, 1, 0, 0, 0));
        var today:Date = Date.now();

        for (rowIndex in 0...ROWS)
        {
            var row:HBox = new HBox();
            row.percentWidth = 100;
            row.addClass(StyleClass.GAMES_CALENDAR_ROW);
            for (column in 0...DAYS_IN_WEEK)
            {
                var day:Int = rowIndex * DAYS_IN_WEEK + column - offset + 1;
                var cell:Box = new Box();
                cell.percentWidth = 100 / DAYS_IN_WEEK;
                cell.addClass(StyleClass.GAMES_CALENDAR_CELL);
                if (day >= 1 && day <= daysInMonth)
                {
                    var isToday:Bool = today.getFullYear() == viewYear && today.getMonth() + 1 == viewMonth && today.getDate() == day;
                    fillDayCell(cell, day, isToday);
                }
                row.addComponent(cell);
            }
            grid.addComponent(row);
        }
    }

    private function fillDayCell(cell:Box, day:Int, isToday:Bool):Void
    {
        var current:Null<LocalDateTime> = selected;
        var isSelected:Bool = current != null && current.year == viewYear && current.month == viewMonth && current.day == day;
        cell.addClass(StyleClass.GAMES_CALENDAR_DAY);
        cell.setClass(StyleClass.GAMES_CALENDAR_DAY_SELECTED, isSelected);
        cell.trackHover();
        cell.registerEvent(MouseEvent.CLICK, _ -> {
            selected = new LocalDateTime(viewYear, viewMonth, day);
            renderGrid();
            refresh();
        });

        var label:Label = new Label();
        label.text = Std.string(day);
        label.addClass(StyleClass.GAMES_CALENDAR_DAY_TEXT);
        label.horizontalAlign = "center";
        label.verticalAlign = "center";
        cell.addComponent(label);

        if (isToday)
        {
            var dot:Box = new Box();
            dot.addClass(StyleClass.GAMES_CALENDAR_TODAY);
            dot.horizontalAlign = "center";
            dot.verticalAlign = "bottom";
            cell.addComponent(dot);
        }
    }

    private function clampTime(index:Int):Void
    {
        var max:Int = index == 0 ? 23 : 59;
        var value:Int = Std.int(Math.min(timeFields[index].number ?? 0, max));
        timeFields[index].showPadded(value, 2);
        refresh();
    }

    private function time():Null<TimeOfDay>
    {
        if (!timeOn)
            return null;
        var parts:Array<Int> = [for (i in 0...timeFields.length) Std.int(Math.min(timeFields[i].number ?? 0, i == 0 ? 23 : 59))];
        return new TimeOfDay(parts[0], parts[1], parts[2]);
    }

    private function value():Null<LocalDateTime>
    {
        var day:Null<LocalDateTime> = selected;
        return day != null ? new LocalDateTime(day.year, day.month, day.day, time()) : null;
    }

    private function refresh():Void
    {
        timeBox.setClass(StyleClass.FILTER_BOX_ON, timeOn);
        for (field in timeFields)
            field.disabled = !timeOn;
        for (colon in colons)
            colon.setClass(StyleClass.GAMES_CALENDAR_COLON_OFF, !timeOn);

        var current:Null<LocalDateTime> = value();
        LocaleManager.instance.registerComponent(hint, "text", () -> ArchiveFormatters.resolvedBound(current, bound));
        footer.info = current != null ? ArchiveFormatters.localDateTime(current) : "—";
        footer.enabled = current != null;
    }
}
