package engine.hxconda.protocol;

enum abstract HxcondaRequestKind(String)
{
    var SearchByLevel = "searchByLevel";
    var SearchByTime = "searchByTime";
    var SearchByNodes = "searchByNodes";
    var SearchByDepth = "searchByDepth";
}
