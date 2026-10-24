package client.datatypes.study;

/** Where a study is listed and who can open it **/
enum abstract StudyPublicity(String) from String to String
{
    /** On the studies page and the author's profile; anyone with the link **/
    var PUBLIC = "public";
    /** On the author's profile; anyone with the link **/
    var PROFILE_AND_LINK_ONLY = "profile_and_link_only";
    /** Listed nowhere; anyone with the link **/
    var LINK_ONLY = "link_only";
    /** The author only **/
    var PRIVATE = "private";
}
