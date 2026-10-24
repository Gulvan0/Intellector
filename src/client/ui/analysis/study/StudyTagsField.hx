package client.ui.analysis.study;

import client.datatypes.study.StudyDetails;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.ContinuousHBox;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import haxefolio.ResponsivityController;
import haxefolio.appearance.AppearanceContext;
import haxefolio.form.TextInputField;
import haxefolio.structure.ActionButton;
import morestd.Detachable;

using StringTools;
using client.ui.ComponentExtension;

/**
    A study's tags: typed one at a time and added with Enter, a comma or Add, then listed as
    removable tokens. The field's hint counts them, or says why the typed one wasn't added.
**/
class StudyTagsField extends VBox
{
    public var tags(default, null):Array<String>;

    private final input:TextInputField;
    private final addButton:ActionButton;
    private final tokens:ContinuousHBox;
    private final onTagsChanged:Void->Void;
    private final heightBinding:Detachable;

    private var errorKey:Null<String> = null;

    public function new(tags:Array<String>, onTagsChanged:Void->Void)
    {
        super();
        this.tags = tags.copy();
        this.onTagsChanged = onTagsChanged;
        percentWidth = 100;
        addClass(StyleClass.STUDY_TAGS_FIELD);

        var row:HBox = new HBox();
        row.percentWidth = 100;
        row.addClass(StyleClass.STUDY_TAGS_INPUT_ROW);
        addComponent(row);

        input = new TextInputField(LocaleUtils.localeBinding("intellector.overlay.study.tags"), onTyped, add, Plain, StudyDetails.MAX_TAG_LENGTH);
        input.placeholder = LocaleUtils.localeBinding("intellector.overlay.study.tag_placeholder");
        row.addComponent(input);

        addButton = new ActionButton(LocaleUtils.localeBinding("intellector.overlay.study.add_tag"), add);
        addButton.addClass(StyleClass.STUDY_TAG_ADD);
        addButton.verticalAlign = "bottom";
        row.addComponent(addButton);
        heightBinding = ResponsivityController.bind(AppearanceContext.current.geometry.fieldHeight, height -> addButton.height = height);

        tokens = new ContinuousHBox();
        tokens.percentWidth = 100;
        tokens.addClass(StyleClass.STUDY_TAG_TOKENS);
        addComponent(tokens);

        refresh();
    }

    public function dispose():Void
    {
        heightBinding.detach();
        input.dispose();
    }

    private function onTyped(text:String):Void
    {
        errorKey = null;
        if (text.indexOf(",") >= 0)
        {
            input.currentText = text.replace(",", "");
            add();
            return;
        }
        refresh();
    }

    private function add():Void
    {
        var tag:String = input.currentText.trim();
        if (tag.length == 0)
            return;

        if (tags.length >= StudyDetails.MAX_TAG_COUNT)
            errorKey = "intellector.overlay.study.tags_full";
        else if (Lambda.exists(tags, existing -> existing.toLowerCase() == tag.toLowerCase()))
            errorKey = "intellector.overlay.study.tag_duplicate";
        else
        {
            errorKey = null;
            tags.push(tag);
            input.currentText = "";
            onTagsChanged();
        }
        refresh();
    }

    private function remove(tag:String):Void
    {
        tags.remove(tag);
        errorKey = null;
        onTagsChanged();
        refresh();
    }

    private function refresh():Void
    {
        var full:Bool = tags.length >= StudyDetails.MAX_TAG_COUNT;
        input.enabled = !full;
        addButton.enabled = !full && input.currentText.trim().length > 0;
        input.invalid = errorKey != null;
        input.hintState = errorKey != null ? Error : Normal;
        if (errorKey != null)
            input.hint = LocaleUtils.localeBinding(errorKey);
        else if (full)
            input.hint = LocaleUtils.localeBinding("intellector.overlay.study.tags_full");
        else
            input.hint = LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.overlay.study.tag_count"), tags.length);

        tokens.removeAllComponents();
        for (tag in tags)
            tokens.addComponent(token(tag));
        tokens.hidden = tags.length == 0;
    }

    private function token(tag:String):HBox
    {
        var token:HBox = new HBox();
        token.addClass(StyleClass.STUDY_TOKEN);
        token.verticalAlign = "center";

        var text:Label = new Label();
        text.text = tag;
        text.verticalAlign = "center";
        text.addClass(StyleClass.STUDY_TOKEN_TEXT);
        token.addComponent(text);

        var removeButton:Box = new Box();
        removeButton.addClass(StyleClass.STUDY_TOKEN_REMOVE);
        removeButton.tooltip = LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.overlay.study.remove_tag"), tag);
        removeButton.verticalAlign = "center";
        removeButton.trackHover();
        removeButton.onClick = _ -> remove(tag);
        token.addComponent(removeButton);

        var cross:Image = new Image();
        cross.resource = Assets.profileIcon("remove_tag");
        cross.width = 10;
        cross.height = 10;
        cross.horizontalAlign = "center";
        cross.verticalAlign = "center";
        removeButton.addComponent(cross);
        return token;
    }
}
