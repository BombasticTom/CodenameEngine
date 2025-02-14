package funkin.system;

import funkin.chart.Chart;
import funkin.chart.ChartData;
import flixel.math.FlxMath;
import openfl.Lib;
import flixel.FlxState;
import funkin.interfaces.IBeatReceiver;
import flixel.FlxG;
import funkin.system.Song.SwagSong;
import flixel.util.FlxSignal.FlxTypedSignal;

/**
 * ...
 * @author
 */

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

class Conductor
{
	/**
	 * FlxSignals
	 */
	public static var onBeatHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
	public static var onStepHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
	public static var onBPMChange:FlxTypedSignal<Float->Void> = new FlxTypedSignal();

	/**
	 * Current BPM
	 */
	public static var bpm:Float = 100;

	/**
	 * Current Crochet (time per beat), in milliseconds.
	 */
	public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
	
	/**
	 * Current StepCrochet (time per step), in milliseconds.
	 */
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds

	/**
	 * Number of beats per mesure (top number in time signature). Defaults to 4.
	 */
	public static var beatsPerMesure:Float = 4;
	
	/**
	 * Number of steps per beat (bottom number in time signature). Defaults to 4.
	 */
	public static var stepsPerBeat:Float = 4;

	
	/**
	 * Current position of the song, in milliseconds.
	 */
	public static var songPosition:Float;

	
	/**
	 * Current step
	 */
	public static var curStep:Int = 0;
	
	 /**
	  * Current beat
	  */
	public static var curBeat:Int = 0;
	
	 /**
	  * Current measure
	  */
	public static var curMeasure:Int = 0;
 
	 
	 /**
	  * Current step, as a `Float` (ex: 4.94, instead of 4)
	  */
	public static var curStepFloat:Float = 0;
 
	 /**
	  * Current beat, as a `Float` (ex: 1.24, instead of 1)
	  */
	public static var curBeatFloat:Float = 0;
 
	 /**
	  * Current measure, as a `Float` (ex: 1.24, instead of 1)
	  */
	public static var curMeasureFloat:Float = 0;

	
	@:dox(hide) public static var lastSongPos:Float = 0;
	@:dox(hide) public static var lastSongPosTime:Float = 0;
	@:dox(hide) public static var speed:Float = 0;
	@:dox(hide) public static var destSpeed:Float = 0;
	@:dox(hide) public static var offset:Float = 0;

	/**
	 * Array of all BPM changes that have been mapped.
	 */
	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	@:dox(hide) public function new() {}

	public static function reset() {
		songPosition = lastSongPos = curBeatFloat = curStepFloat = curBeat = curStep = 0;
		speed = 1;
		bpmChangeMap = [];
		changeBPM(0);
	}

	public static function setupSong(SONG:ChartData) {
		reset();
		// mapBPMChanges(SONG); // TODO!!!
		changeBPM(SONG.meta.bpm, cast SONG.meta.beatsPerMesure.getDefault(4), cast SONG.meta.stepsPerBeat.getDefault(4));
	}
	/**
	 * Maps BPM changes from a song.
	 * @param song Song to map BPM changes from.
	 */
	public static function mapBPMChanges(song:SwagSong)
	{
		bpmChangeMap = [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i=>notes in song.notes)
		{
			if (notes == null) continue;
			if (notes.changeBPM && notes.bpm != curBPM)
			{
				curBPM = notes.bpm;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = notes.lengthInSteps;
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
	}

	private static var elapsed:Float;

	public static function init() {
		FlxG.signals.preUpdate.add(update);
		FlxG.signals.preStateCreate.add(onStateSwitch);
		reset();
	}

	private static var __timeUntilUpdate:Float;
	private static var __elapsedAL:Float;
	private static function __updateSongPos(elapsed:Float, mainTime:Float) {
		if (FlxG.sound.music == null || !FlxG.sound.music.playing) {
			speed = destSpeed = 1;
			lastSongPos = FlxG.sound.music != null ? FlxG.sound.music.time : 0;
			lastSongPosTime = mainTime;
			return;
		}

		var lastPos = lastSongPos;
		if (lastSongPos != (lastSongPos = FlxG.sound.music.time)) {
			// update conductor
			__timeUntilUpdate = -(lastSongPosTime - (lastSongPosTime = mainTime));
			__elapsedAL = (lastSongPos - lastPos);
			destSpeed = FlxMath.bound(__timeUntilUpdate / __elapsedAL, 0.925, 1.075);
			songPosition = lastSongPos;
		} else {
			songPosition += elapsed * 1000 * speed;
		}
		speed = FlxMath.lerp(speed, destSpeed, FlxMath.bound(elapsed, 0, 1));
	}

	private static function onStateSwitch(newState:FlxState) {
		if (FlxG.sound.music == null)
			reset();
	}
	private static var __lastChange:BPMChangeEvent;
	private static var __updateBeat:Bool;
	private static var __updateMeasure:Bool;

	private static function update() {
		if (FlxG.state != null && FlxG.state is MusicBeatState && cast(FlxG.state, MusicBeatState).cancelConductorUpdate) return;

		__updateSongPos(FlxG.elapsed, Main.time);

		if (bpm > 0) {
			// updates curbeat and stuff
			__lastChange = {
				stepTime: 0,
				songTime: 0,
				bpm: 0
			};
			for (change in Conductor.bpmChangeMap)
			{
				if (Conductor.songPosition >= change.songTime)
					__lastChange = change;
			}
	
			if (__lastChange.bpm > 0 && bpm != __lastChange.bpm) changeBPM(__lastChange.bpm);

			curStepFloat = __lastChange.stepTime + ((Conductor.songPosition - __lastChange.songTime) / Conductor.stepCrochet);
			curBeatFloat = curStepFloat / stepsPerBeat;
			curMeasureFloat = curBeatFloat / beatsPerMesure;

			if (curStep != (curStep = Std.int(curStepFloat))) {
				// updates step
				__updateBeat = curBeat != (curBeat = Std.int(curBeatFloat));
				__updateMeasure = __updateBeat && (curMeasure != (curMeasure = Std.int(curMeasureFloat)));

				onStepHit.dispatch(curStep);
				if (__updateBeat)
					onBeatHit.dispatch(curBeat);

				if (FlxG.state is IBeatReceiver) {
					var state = FlxG.state;
					while(state != null) {
						if (state is IBeatReceiver && (state.subState == null || state.persistentUpdate)) {
							var st = cast(state, IBeatReceiver);
							st.stepHit(curStep);
							if (__updateBeat)
								st.beatHit(curBeat);
							if (__updateMeasure)
								st.measureHit(curMeasure);
						}
						state = state.subState;
					}
				}

			}
		}
	}

	public static function changeBPM(newBpm:Float, beatsPerMesure:Float = 4, stepsPerBeat:Float = 4)
	{
		bpm = newBpm;

		crochet = ((60 / bpm) * 1000);
		stepCrochet = crochet / stepsPerBeat;

		Conductor.beatsPerMesure = beatsPerMesure;
		Conductor.stepsPerBeat = stepsPerBeat;
		

		onBPMChange.dispatch(bpm);
	}
}
