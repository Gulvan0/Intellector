package client.ui.analysis.study;

import client.datatypes.study.Study;
import client.formatters.StudyFormatters;
import client.utils.PagePaths;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;
import haxefolio.PageLink;

using client.ui.ComponentExtension;

/** A study's name, author (linking to their profile), dates and description **/
class StudyInfo extends VBox
{
    private final nameLabel:Label;
    private final authorLabel:Label;
    private final youLabel:Label;
    private final datesLabel:Label;
    private final descriptionLabel:Label;
    private final authorLink:PageLink;

    private var study:Null<Study> = null;

    public function new()
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.STUDY_INFO);

        nameLabel = new Label();
        nameLabel.percentWidth = 100;
        nameLabel.addClass(StyleClass.STUDY_NAME);
        addComponent(nameLabel);

        var byline:HBox = new HBox();
        byline.addClass(StyleClass.STUDY_BYLINE);
        addComponent(byline);

        var byLabel:Label = new Label();
        byLabel.text = LocaleUtils.localeBinding("intellector.analysis.study.by");
        byLabel.addClass(StyleClass.STUDY_BYLINE_TEXT);
        byline.addComponent(byLabel);

        authorLabel = new Label();
        authorLabel.addClass(StyleClass.STUDY_AUTHOR);
        authorLabel.trackHover();
        byline.addComponent(authorLabel);
        authorLink = PageLink.attach(authorLabel, null);

        youLabel = new Label();
        youLabel.text = LocaleUtils.localeBinding("intellector.analysis.study.you");
        youLabel.addClass(StyleClass.STUDY_BYLINE_TEXT);
        byline.addComponent(youLabel);

        datesLabel = new Label();
        datesLabel.percentWidth = 100;
        datesLabel.addClass(StyleClass.GAME_HINT);
        addComponent(datesLabel);
        LocaleManager.instance.registerComponent(datesLabel, "text", () -> study != null ? StudyFormatters.dates(study, ServerTime.now()) : "");

        descriptionLabel = new Label();
        descriptionLabel.percentWidth = 100;
        descriptionLabel.addClass(StyleClass.STUDY_DESCRIPTION);
        addComponent(descriptionLabel);
    }

    public function setStudy(study:Study, own:Bool):Void
    {
        this.study = study;
        nameLabel.text = study.details.name;
        authorLabel.text = study.authorNickname;
        authorLink.setPath(PagePaths.playerProfile(study.authorLogin));
        youLabel.hidden = !own;
        descriptionLabel.text = study.details.description;
        descriptionLabel.hidden = study.details.description.length == 0;
        LocaleManager.instance.refreshFor(datesLabel);
    }
}
