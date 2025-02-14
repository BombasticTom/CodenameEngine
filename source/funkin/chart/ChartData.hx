package funkin.chart;

import flixel.util.FlxColor;

typedef ChartData = {
    public var strumLines:Array<ChartStrumLine>;
    public var events:Array<ChartEvent>;
    public var meta:ChartMetaData;
    public var codenameChart:Bool;
    public var stage:String;
    public var scrollSpeed:Float;
    public var noteTypes:Array<String>;

    public var ?fromMods:Bool;
}

typedef ChartMetaData = {
    public var name:String;
    public var bpm:Float;
    public var ?displayName:String;
    public var ?beatsPerMesure:Float;
    public var ?stepsPerBeat:Float;
    public var ?needsVoices:Bool;
    public var ?icon:String;
    public var ?color:Dynamic;
	public var ?difficulties:Array<String>;
	public var ?coopAllowed:Bool;
	public var ?opponentModeAllowed:Bool;

    // NOT TO BE EXPORTED
	public var ?parsedColor:FlxColor;
}

typedef ChartStrumLine = {
    var characters:Array<String>;
    var opponent:Bool;
    var notes:Array<ChartNote>;
    var position:String;
    var ?strumLinePos:Float; // 0.25 = default opponent pos, 0.75 = default boyfriend pos
    var ?visible:Null<Bool>;
}

typedef ChartNote = {
    var time:Float; // time at which the note will be hit (ms)
    var id:Int; // strum id of the note
    var type:Int; // type (int) of the note
    var sLen:Float; // sustain length of the note (ms)
}

typedef ChartEvent = {
    var time:Float;
    var type:ChartEventType;
    var params:Array<Dynamic>;
}

@:enum
abstract ChartEventType(Int) from Int to Int {
    /**
     * CUSTOM EVENT
     * Params:
     *  - Function Name (String)
     *  - Function Parameters...
     */
    var CUSTOM = -1;
    /**
     * NO EVENT, MADE FOR UNKNOWN EVENTS / EVENTS THAT CANNOT BE PARSED
     */
    var NONE = 0;
    /**
     * CAMERA MOVEMENT EVENT
     * Params:
     *  - Target Strumline ID (Int)
     */
    var CAM_MOVEMENT = 1;

    /**
     * BPM CHANGE EVENT
     * Params:
     *  - Target BPM (Float)
     */
    var BPM_CHANGE = 2;
    /**
     * ALT ANIM TOGGLE
     * Params:
     *  - Strum Line which is going to be toggled (Int)
     *  - Whenever its going to be toggled or not (Bool)
     */
    var ALT_ANIM_TOGGLE = 3;
}