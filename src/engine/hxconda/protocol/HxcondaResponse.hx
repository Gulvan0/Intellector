package engine.hxconda.protocol;

/**
    Message posted by the engine worker. Decode it with `HxcondaProtocol.decodeResponse`.
**/
typedef HxcondaResponse = {
    var kind:HxcondaResponseKind;
    /** Share of the node budget used up **/
    var ?percent:Int;
    var ?report:HxcondaReportMessage;
    var ?error:String;
}
