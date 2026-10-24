package client.formatters;

import client.datatypes.study.Study;
import client.datatypes.study.StudyPublicity;
import client.ui.analysis.study.StudySaveState;
import haxefolio.LocaleUtils;

class StudyFormatters
{
    /** A locale binding: `Link only` **/
    public static function publicityName(publicity:StudyPublicity):String
    {
        return LocaleUtils.localeBinding('intellector.analysis.study.publicity.$publicity');
    }

    /** A locale binding: where it's listed, `Profile · link` **/
    public static function publicityScope(publicity:StudyPublicity):String
    {
        return LocaleUtils.localeBinding('intellector.analysis.study.publicity_scope.$publicity');
    }

    /** A locale binding: the full sentence of who sees it **/
    public static function publicityDescription(publicity:StudyPublicity):String
    {
        return LocaleUtils.localeBinding('intellector.analysis.study.publicity_description.$publicity');
    }

    /** `#4821` **/
    public static function number(study:Study):String
    {
        return LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.analysis.study.number"), study.id);
    }

    /** `Created 12 Sep 2026 · Updated 2 days ago` **/
    public static function dates(study:Study, nowMs:Float):String
    {
        var created:String = ProfileFormatters.shortDateWithYear(study.createdAtMs);
        var updated:String = ProfileFormatters.ago(nowMs - study.modifiedAtMs);
        return LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.analysis.study.dates"), created, updated);
    }

    /** `Studies by hexwanderer tagged opening` **/
    public static function tagHint(study:Study, tag:String):String
    {
        return LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.analysis.study.tag_hint"), study.authorNickname, tag);
    }

    /** A locale binding: how the edits stand; a visitor's are never saved to the study **/
    public static function saveHint(own:Bool, state:StudySaveState):String
    {
        if (!own)
            return LocaleUtils.localeBinding("intellector.analysis.study.visitor_hint");

        return LocaleUtils.localeBinding(switch state {
            case Saved: "intellector.analysis.study.saved";
            case Unsaved: "intellector.analysis.study.unsaved";
            case Saving: "intellector.analysis.study.saving";
            case Failed: "intellector.analysis.study.save_failed";
        });
    }
}
