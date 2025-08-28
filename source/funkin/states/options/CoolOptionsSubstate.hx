package funkin.states.options;

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
		"gameplay",
		"visuals",
		"ui",
		"modifiers",
		"advanced",
		"developer" // IE; F5 hot reloading, etc

		// "game",
		// "ui",
		// "video",
		// "controls",
		// "misc"
	];

	static var options:Map<String, Array<Dynamic>> = [
		// maps are annoying and dont preserve order so i have to do this
		"general" => [
			["general", ["customizeKeybinds", "discordRPC"]],
			[
				"audio",
				[
					"masterVolume",
					"songVolume",
					'sfxVolume',
					"missVolume",
					"hitsoundBehaviour",
					"hitsoundVolume"
				]
			],
			[
				"accessibility",
				[
					"autoPause",
					"countUnpause",
					"flashing",
					"camShakeP",
					"camZoomP",
				]
			]
		],
		"gameplay" => [
			[
				"gameplay", 
				[
					#if USE_EPIC_JUDGEMENT
					"useEpics",
					#end
					"downScroll",
					"midScroll",
					"ghostTapping", 
					"noteOffset", 
					"ratingOffset",
				]
			]
		],
		"advanced" => [
			[
				"gameplay",
				[
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
				]
			],
			[
				"ui",
				[
					"etternaHUD", 
					"gradeSet",
					"showWifeScore"
				]
			]
		],
		"ui" => [
			[
				"notes",
				[
					"noteOpacity",
					"downScroll",
					"midScroll",
					"midScrollType",
					"noteSplashes",
					"noteSkin",
					"styledNoteSkins",
					"indicateNear",
					"customizeColours"
				]
			],
			[
				"hud",
				[
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
					'worldCombos',
					"simpleJudge",
					"judgeCounter",
					'hudPosition', 
					"botplayMarker", 
					"customizeHUD",
				]
			]
		],
		"visuals" => [
			[
				"visuals",
				[
					"lowQuality",
					"shaders",
					"globalAntialiasing",
					"multicoreLoading",
					"optimizeHolds",
					"holdSubdivs",
					"drawDistanceModifier", // apparently i forgot to add this in the new options thing lmao
					"svDetail"
				]
			]
		],
		"developer" => [["video", ["shaders", "showFPS", "fpsOpacity", "fpsBG", "fpsStyle"]],
			["display", ["framerate", #if FUNNY_ALLOWED "bread" #end]]]
	];

	public var changed:Array<String> = [];
	public var transCamera:FlxCamera = new FlxCamera();
	public var goBack:(Array<String>)->Void;
	var curSelected = [0,0];
	var curSelectedCategory(get, default):String;

	function get_curSelectedCategory() {
		return optionOrder[curSelected[0]];
	}


	var xmbCategories:Map<String, Array<FlxSprite>> = [];
	var xmbSelectables:Map<String, Array<FlxSprite>> = [];
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
		camera.follow(camFollow);


		makeOptions();
		super.create();
	}

	var marginValY = 24;
	var marginValX = 150;
	function makeOptions() {
		var it = 0;
		for (i in optionOrder) {
			var spriteArr = [];
			var optionSprite = new FlxSprite(it*marginValX + 36, marginValY).makeGraphic(75,75,0xFFFFFFFF);
			add(optionSprite);
			spriteArr.push(optionSprite);
			var cataText = new FlxText(0,0,0,i.toUpperCase());
			cataText.setFormat(Paths.font('quantico.ttf'), 22, 0xFFFFFFFF, 'left');
			cataText.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2);
			cataText.antialiasing = false;
			add(cataText);
			spriteArr.push(cataText);
			
			cataText.centerObjectInObject(optionSprite, X);
			cataText.y = optionSprite.y + optionSprite.height + 2;
			it++;
			xmbCategories.set(i, spriteArr);
		}
		for (category=>option in options) {
			break;
		}
	}

	override function update(elapsed:Float)
	{
		if (subState == null)
		{
			if (controls.BACK) {
				goBack(changed);
			}
		}

		camera.followLerp = elapsed * 8;
		trace(camFollow);
		camFollow.x = xmbCategories.get(curSelectedCategory)[0].x + 240;

		super.update(elapsed);
	}

	override function destroy()
	{
		super.destroy();
	}
}