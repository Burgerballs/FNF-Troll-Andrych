package;

import flixel.FlxSprite;
import funkin.objects.IndependentVideoSprite;
import math.CoolMath;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import funkin.*;
import funkin.states.MusicBeatState;
import funkin.states.FadeTransitionSubstate;

import funkin.data.Highscore;

import flixel.FlxG;
import flixel.FlxState;
import flixel.tweens.*;
import flixel.addons.transition.FlxTransitionableState;
import flixel.input.keyboard.FlxKey;
import funkin.input.Controls;

#if sys
import Sys.time as getTime;
#else
import haxe.Timer.stamp as getTime;
#end


import sys.thread.Thread;
import sys.thread.Mutex;

#if (DO_AUTO_UPDATE || display)
import funkin.states.UpdaterState;
#end

using StringTools;

// Loads the title screen, alongside some other stuff.

class StartupState extends FlxTransitionableState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	public static var fullscreenKeys:Array<FlxKey> = [FlxKey.F11];
	public static var specialKeysEnabled(default, set):Bool;

	@:noCompletion inline public static function set_specialKeysEnabled(val)
	{
		if (val) {
			FlxG.sound.muteKeys = StartupState.muteKeys;
			FlxG.sound.volumeDownKeys = StartupState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = StartupState.volumeUpKeys;
		}
		else {
			final emptyArr = [];
			FlxG.sound.muteKeys = emptyArr;
			FlxG.sound.volumeDownKeys = emptyArr;
			FlxG.sound.volumeUpKeys = emptyArr;
		}

		return specialKeysEnabled = val;
	}

	public function new()
	{
		super();
		// this.canBeScripted = false; // vv wait this isnt a musicbeatstate LOL!

		persistentDraw = true;
		persistentUpdate = true;
	}

	public var bullyIntro:IndependentVideoSprite = null;

	public static var okay = true;

	public var loadActions:Array<() -> Void> = [];

	public static var nextState:Class<FlxState> = funkin.states.TitleState;
	public static var loadPercent:Float = 0;
	public static var loadMax:Float = 0;
	public static var curLoad:Float = 0;

	static var loadBar:FlxBar;
	static var actionTxt:FlxText;
	static var percentageTxt:FlxText;
	override function create()
	{
		this.transIn = null;
		this.transOut = null;
		okay = true; 
		loadActions = [
			function():Void {
				Paths.init();
				Paths.getAllStrings();
				Controls.init();
				ClientPrefs.initialize();
				ClientPrefs.load();
				Highscore.load();

				actionTxt.text += ' Done!\nDoing Flixel System Junk...';
			},
			function():Void {

				Main.resizeGame();
				FlxG.sound.onVolumeChange.add((vol:Float) -> {
					ClientPrefs.masterVolume = vol;
		
					@:privateAccess {
						Reflect.setField(ClientPrefs.optionSave.data, "masterVolume", vol);
						ClientPrefs.optionSave.flush();
					}
				});
		
				specialKeysEnabled = true;
				FlxG.fixedTimestep = false;
				FlxG.keys.preventDefaultKeys = [TAB];
	
				#if (windows || linux || mac) // No idea if this also applies to any other targets
				FlxG.stage.addEventListener(
					openfl.events.KeyboardEvent.KEY_DOWN, 
					(e)->{
						// Prevent Flixel from listening to key inputs when switching fullscreen mode
						if (e.keyCode == FlxKey.ENTER && e.altKey)
							e.stopImmediatePropagation();
		
						// Also add F11 to switch fullscreen mode
						if (specialKeysEnabled && fullscreenKeys.contains(e.keyCode))
							FlxG.fullscreen = !FlxG.fullscreen;
					}, 
					false, 
					100
				);
		
				FlxG.stage.addEventListener(
					openfl.events.FullScreenEvent.FULL_SCREEN, 
					(e) -> FlxG.save.data.fullscreen = e.fullScreen
				);
				#end
	
				#if DISCORD_ALLOWED
				FlxG.stage.application.onExit.add((exitCode) -> funkin.api.Discord.DiscordClient.shutdown(true));
				#end
		
				FlxTransitionableState.defaultTransIn = FadeTransitionSubstate;
				FlxTransitionableState.defaultTransOut = FadeTransitionSubstate;

				actionTxt.text += ' Done!\nLoading Video System...';
			},
			function() {
				okay = false;
				bullyIntro = new IndependentVideoSprite(0,0,true,false);
				bullyIntro.bitmap.onFormatSetup.add(function():Void
				{
					okay = true;
				});
				bullyIntro.load(Paths.video('loading'), [':no-audio']);
				bullyIntro.play();
			},
			function() {
				actionTxt.text += ' Done!';
				MusicBeatState.switchState(Type.createInstance(nextState, []));
			}
		];

		loadMax = loadActions.length;

		var versionShit:FlxText = new FlxText(2, 2, 0, 'Loading...', 18);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		actionTxt = new FlxText(2, 22, 0, 'Getting Saves and Paths and Stuff...', 18);
		actionTxt.scrollFactor.set();
		actionTxt.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(actionTxt);

		loadBar = new FlxBar(versionShit.x + versionShit.width + 32, 2, LEFT_TO_RIGHT, Std.int(FlxG.width - (versionShit.x + versionShit.width) - 34), 16, null, null, 0, 100);
		loadBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		add(loadBar);

		percentageTxt = new FlxText(loadBar.x, 720 - 68, loadBar.width, '100%', 18);
		percentageTxt.scrollFactor.set();
		percentageTxt.setFormat("VCR OSD Mono", 64, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(percentageTxt);

		#if BBTE_BURGERBALLS_SIGNATURE
		var downzi:FlxSprite = new FlxSprite();
		add(downzi);
		downzi.frames = Paths.getSparrowAtlas('loading/downzi');

		downzi.animation.addByPrefix('idle', 'walk', 12, true);
		downzi.animation.play('idle');
		downzi.scale.set(3,3);
		downzi.updateHitbox();
		downzi.setPosition(6, FlxG.height - downzi.height - 6);
		downzi.antialiasing = false;
		#end

		super.create();
	}


	private var step:Int = 0;
	private var loadingTime:Float = getTime();

	#if MULTICORE_LOADING
	private var loadingMutex:Null<Mutex> = null;
	#end

	var fadeTwn:FlxTween = null;
	override function update(elapsed:Float)
	{

		if (loadActions != [] && okay) {
			loadActions[0]();
			loadActions.shift();
			curLoad +=1;
			loadPercent = (curLoad / loadMax) * 100;
			loadBar.value = loadPercent;
			percentageTxt.text = Math.floor(loadPercent) + '%';
		}

		super.update(elapsed);
	}
}