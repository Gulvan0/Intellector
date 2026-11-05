package client.build;

class BuildInfo
{
    /** Identifies this build; `dev` for a debug one **/
    public static final BUILD_ID:String = BuildInfoMacro.embeddedBuildId();

    /** Update checks make no sense for a build that isn't deployed **/
    public static final IS_DEPLOYABLE:Bool = BUILD_ID != "dev";
}
