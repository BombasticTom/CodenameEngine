package funkin.scripting.events;

import funkin.game.StrumLine;
import flixel.math.FlxPoint;

class CamMoveEvent extends CancellableEvent {
    /**
     * Final camera position.
     */
    public var position:FlxPoint;

    /**
     * Currently focused strumline.
     */
    public var strumLine:StrumLine;

    /**
     * Number of focused characters
     */
    public var focusedCharacters:Int;
}