package engine.hxconda.protocol;

/**
    Decoded `HxcondaResponse`.
**/
enum HxcondaEvent
{
    Progress(percent:Int);
    Iteration(report:HxcondaReportMessage);
    Completed(report:Null<HxcondaReportMessage>);
    Failed(error:String);
}
