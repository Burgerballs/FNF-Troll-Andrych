package funkin.states.options;

import flixel.group.FlxSpriteGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import funkin.CoolUtil.overlapsMouse as overlaps;
import funkin.states.options.*;
import funkin.ClientPrefs;

import flixel.graphics.FlxGraphic;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxUI9SliceSprite;
import openfl.geom.Rectangle;

using funkin.data.FlxTextFormatData;
using funkin.AlignmentUtil;

#if DISCORD_ALLOWED
import funkin.api.Discord;
#end

// for anybody reading this notbilly is a nonce for not banning lily off the haxe server
class CoolOptionsSubstate extends MusicBeatSubstate
{
	// for scripting
	public static final requiresRestart:Map<String, Bool> = [];
	public static final recommendsRestart:Map<String, Bool> = [];

	static var optionOrder:Array<String> = [
		"general",
		"accessibility",
		"gameplay",
		"visuals",
		"ui",
		"hud",
		"advanced",
		"developer" // IE; F5 hot reloading, etc

		// "game",
		// "ui",
		// "video",
		// "controls",
		// "misc"
	];

	static var options:Map<String, Array<String>> = [
		// maps are annoying and dont preserve order so i have to do this
		"general" => ["customizeKeybinds", "discordRPC",
					"masterVolume",
					"songVolume",
					'sfxVolume',
					"missVolume",
					"hitsoundBehaviour",
					"hitsoundVolume",
		],
		"accessibility" => [
			"autoPause",
			"countUnpause",
			"flashing",
			"camShakeP",
			"camZoomP"
		],
		"gameplay" => [
			#if USE_EPIC_JUDGEMENT
			"useEpics",
			#end
			"downScroll",
			"midScroll",
			"ghostTapping", 
			"noteOffset", 
			"ratingOffset",
		],
		"advanced" => [
			"songSyncMode",
			"accuracyCalc",
			"judgePreset",
			#if USE_EPIC_JUDGEMENT
			"epicWindow",
			#end
			"sickWindow",
			"goodWindow",
			"badWindow",
			"hitWindow",
			"judgeDiff", // fuck you pedophile
			"etternaHUD", 
			"gradeSet",
			"showWifeScore",
		],
		"ui" => [
			"noteOpacity",
			"downScroll",
			"midScroll",
			"midScrollType",
			"noteSplashes",
			"noteSkin",
			"styledNoteSkins",
			"indicateNear",
			"customizeColours",
		],
		"hud" => [
			"timeBarType", 
			"hudOpacity", 
			"hpOpacity", 
			"timeOpacity", 
			"judgeOpacity",
			"stageOpacity", 
			"scoreZoom", 
			"npsDisplay", 
			"hitbar", 
			"showMS", 
			"coloredCombos",
			"simpleJudge",
			"judgeCounter",
			'hudPosition', 
			"botplayMarker", 
			"customizeHUD",
		],
		"visuals" => [
			"framerate",
			"lowQuality",
			"shaders",
			"globalAntialiasing",
			"multicoreLoading",
			"holdSubdivs",
			"drawDistanceModifier", // apparently i forgot to add this in the new options thing lmao
			"svDetail"
		],
		"developer" => ["showFPS", "fpsOpacity", "fpsBG", "fpsStyle", #if FUNNY_ALLOWED "bread" #end],
	];

	public var valueTexts:Map<String, FlxText> = [];

	public var changed:Array<String> = [];
	public var transCamera:FlxCamera = new FlxCamera();
	public var goBack:(Array<String>)->Void;

	public var styleText:(text:FlxText)->Void;
	public var styleMiniText:(text:FlxText)->Void;
	public var styleCategoryText:(text:FlxText)->Void;

	public var styleCategoryIcon:(spr:FlxSprite, category:String)->Void;

	var curSelected = 0;
	var curSelectedY = [0,0,0,0,0,0];

	var xmbCategories:Map<String, FlxSpriteGroup> = [];
	var xmbSelectables:Map<String, Array<FlxSpriteGroup>> = [];
	public var optState = false;

	var mainCamera:FlxCamera;
	public function new(state:Bool=false){
		optState=state;
		super();
	}

	var whitePixel = FlxGraphic.fromRectangle(1, 1, 0xFFFFFFFF, false, 'whitePixel');

	public var camerasToRemove:Array<FlxCamera> = [];
	var color1 = 0xFF000000;
	var color2 = 0xFF000000;
	var camFollow:FlxObject;
	override function create()
	{
		persistentDraw = true;
		persistentUpdate = true;
		mainCamera = new FlxCamera();
		mainCamera.bgColor.alpha = 0;
		
		transCamera.bgColor.alpha = 0;
		if(optState){
			FlxG.cameras.reset(mainCamera);
			FlxG.cameras.add(transCamera, false);
			camerasToRemove.push(mainCamera);

		}else{
			FlxG.cameras.add(mainCamera, false);
			FlxG.cameras.add(transCamera, false);
		}
		camerasToRemove.push(transCamera);

		cameras = [mainCamera];
		camFollow = new FlxObject(0,240);
		add(camFollow);


		makeOptions();
		super.create();
	}

	var marginValY = 24;
	var marginValX = 150;
	function makeOptions() {
		var optdefs = ClientPrefs.getOptionDefinitions();
		var it = 0;
		for (i in optionOrder) {
			// Make Icon BS
			var sprites = new FlxSpriteGroup();
			add(sprites);
			var optionSprite = new FlxSprite(0, 0).makeGraphic(75,75,0xFFFFFFFF);
			sprites.add(optionSprite);
			var cataText = new FlxText(0,0,0,i.toUpperCase());
			cataText.setFormat(Paths.font('helveticaib.ttf'), 16, 0xFFFFFFFF, 'left');
			cataText.antialiasing = false;
			sprites.add(cataText);
			
			sprites.setPosition(it*marginValX + 36, marginValY);
			cataText.centerObjectInObject(optionSprite, X);
			cataText.y = optionSprite.y + optionSprite.height + 2;
			xmbCategories.set(i, sprites);

			// Make Not Icon BS also notbilly needs to get his hard drive checked
			var optBalls:Array<String> = options.get(i); // lily is a nonce
			trace(optBalls);
			var optionsTuff = [];
			for (option in optBalls) { // george is complicit
				trace(optdefs.get(option));
				var sprites = new FlxSpriteGroup(); // the funkin crew is complicit
				add(sprites); // karam akira is complicit
				var cataText = new FlxText(0,0,1280,optdefs.get(option).display); // DNI if you support the funkin crew
				cataText.setFormat(Paths.font('helveticaib.ttf'), 24, 0xFFFFFFFF, 'left');
				cataText.antialiasing = false;
				sprites.add(cataText);
				cataText.x = 0;
				
				var cataText = new FlxText(0,24,640,optdefs.get(option).desc);
				cataText.setFormat(Paths.font('helveticaib.ttf'), 12, 0xFFFFFFFF, 'left');
				cataText.antialiasing = false;
				sprites.add(cataText);
				cataText.x = 0;

				var cataText = new FlxText(0,0,640,Reflect.getProperty(ClientPrefs, option));
				cataText.setFormat(Paths.font('helveticaib.ttf'), 12, 0xFFFFFFFF, 'right');
				cataText.antialiasing = false;
				sprites.add(cataText);
				cataText.x = 0;
				optionsTuff.push(sprites);
				sprites.setPosition(it*marginValX + 36, marginValY + 90);
			}
			it++;
			xmbSelectables.set(i, optionsTuff);
		}
	}

	function changeSelectionX(mod:Int) {
		curSelected = FlxMath.wrap(curSelected + mod, 0, optionOrder.length-1);
	}

	function changeSelectionY(mod:Int) {
		curSelectedY[curSelected] = FlxMath.wrap(curSelectedY[curSelected] + mod, 0, options.get(optionOrder[curSelected]).length-1);
	}

	var firstFrame = true;
	override function update(elapsed:Float)
	{
		if (subState == null)
		{
			if (controls.BACK) {
				goBack(changed);
			}
		}
		if (controls.UI_LEFT_P) {
			changeSelectionX(-1);
		} else if (controls.UI_RIGHT_P) {
			changeSelectionX(1);
		}

		if (controls.UI_UP_P) {
			changeSelectionY(-1);
		} else if (controls.UI_DOWN_P) {
			changeSelectionY(1);
		}

		mainCamera.followLerp = elapsed * 8;
		camFollow.x = FlxMath.lerp(camFollow.x, xmbCategories.get(optionOrder[curSelected]).x + 240, elapsed * 9);
		mainCamera.follow(camFollow);
		
		for (opt=>groups in xmbSelectables) {
			var it = 0;
			for (group in groups) {
				var intendedAlpha:Float = 1;
				if (opt == optionOrder[curSelected]) {
					if (it - curSelectedY[optionOrder.indexOf(opt)] != 0) {
						intendedAlpha = 0.77;
					}
				} else {
					intendedAlpha = 0;
				}

				if (firstFrame) {
					group.y = (it - curSelectedY[optionOrder.indexOf(opt)]) * 76 + 194;
					group.alpha = intendedAlpha;
				} else {
					group.y = FlxMath.lerp(group.y, (it - curSelectedY[optionOrder.indexOf(opt)]) * 76 + 194, elapsed * 8);
					group.alpha = FlxMath.lerp(group.alpha, intendedAlpha, elapsed * 16);
				}
				it++;
			}
		}
		if (firstFrame)
			firstFrame = false;

		super.update(elapsed);
	}

	override function destroy()
	{
		super.destroy();
	}
}

