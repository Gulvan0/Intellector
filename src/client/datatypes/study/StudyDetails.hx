package client.datatypes.study;

/** What a study is called and about, and who sees it: everything of it but the moves **/
class StudyDetails
{
    public static inline final MAX_NAME_LENGTH:Int = 64;
    public static inline final MAX_DESCRIPTION_LENGTH:Int = 2000;
    public static inline final MAX_TAG_COUNT:Int = 10;
    public static inline final MAX_TAG_LENGTH:Int = 16;

    public final name:String;
    public final description:String;
    public final publicity:StudyPublicity;
    public final tags:Array<String>;

    public function new(name:String, description:String, publicity:StudyPublicity, tags:Array<String>)
    {
        this.name = name;
        this.description = description;
        this.publicity = publicity;
        this.tags = tags;
    }
}
