package client.ui.analysis.study;

import client.datatypes.study.Study;
import client.formatters.StudyFormatters;
import client.ui.profile.ProfileState;
import haxe.ui.components.Button;
import haxefolio.HaxeFolioApp;

class StudyTagButtons
{
    /**
        One button per tag of `study`, named after the author's studies it stands for. Pressing one
        opens the author's profile on the Studies tab filtered by the tag; `beforeNavigate` runs first
        and receives the navigation as a callback, for callers that must close something before leaving.
    **/
    public static function create(study:Study, ?beforeNavigate:(Void->Void)->Void):Array<Button>
    {
        return [
            for (tag in study.details.tags)
            {
                var button:Button = new Button();
                button.text = tag;
                button.tooltip = StudyFormatters.tagHint(study, tag);
                button.addClass(StyleClass.STUDY_TAG);
                button.onClick = _ -> {
                    var open:Void->Void = () -> openAuthorStudies(study, tag);
                    if (beforeNavigate != null)
                        beforeNavigate(open);
                    else
                        open();
                };
                button;
            }
        ];
    }

    private static function openAuthorStudies(study:Study, tag:String):Void
    {
        var state:ProfileState = {
            archive: {
                studies: true,
                kinds: [],
                rated: null,
                pastPage: 1,
                tags: [tag],
                studyOffset: 0
            }
        };
        HaxeFolioApp.navigateTo('player/${study.authorLogin}', state);
    }
}
