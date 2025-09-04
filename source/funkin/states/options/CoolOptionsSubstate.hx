package funkin.states.options;

import flixel.ui.FlxBar;
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
			"midScrollType",
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
			"holdSubdivs",
			"drawDistanceModifier", // apparently i forgot to add this in the new options thing lmao
			"svDetail"
		],
		"developer" => ["showFPS", "fpsOpacity", "fpsBG", "fpsStyle", #if FUNNY_ALLOWED "bread" #end],
	];

	public var valueTexts:Map<String, FlxText> = [];

	public var choicesOption:String = '';
	public var choices:Array<Dynamic> = [];
	public var choicesGrp:FlxSpriteGroup;
	public var optData:OptionData;

	public var changed:Array<String> = [];
	public var transCamera:FlxCamera = new FlxCamera();
	public var goBack:(Array<String>)->Void;

	public var styleValueSetNumber:(text:FlxText)->Void;
	public var styleValueSetChoiceText:(text:FlxText)->Void;
	public var styleText:(text:FlxText)->Void;
	public var styleMiniText:(text:FlxText)->Void;
	public var styleCategoryText:(text:FlxText)->Void;

	public var styleCategoryIcon:(spr:FlxSprite, category:String)->Void;
	public var styleValueSetBar:(spr:FlxSprite)->Void;
	public var styleValueSetBG:(spr:FlxSprite)->Void;


	public var valueSetBar:FlxBar;
	public var valueSetNumberText:FlxText;
	public var numberMode = false;
	public var numberVal:Float = 240;

	public var styleValueSetBarUp:(spr:FlxSprite, text:FlxText)->Void;
	public var styleValueSetBarDown:(spr:FlxSprite, text:FlxText)->Void;


	var curSelected = 0;
	var curSelectedY = [0,0,0,0,0,0];
	public var curSelectedChoice:Int = 0;

	var xmbCategories:Map<String, FlxSpriteGroup> = [];
	var xmbSelectables:Map<String, Array<FlxSpriteGroup>> = [];
	public var optState = false;

	var mainCamera:FlxCamera;
	var valSetCamera:FlxCamera;
	public function new(state:Bool=false){
		optState=state;
		super();
	}

	var whitePixel = FlxGraphic.fromRectangle(1, 1, 0xFFFFFFFF, false, 'whitePixel');

	public var camerasToRemove:Array<FlxCamera> = [];
	var color1 = 0xFF000000;
	var color2 = 0xFF000000;
	var camFollow:FlxObject;
	var valueSetSprite:FlxSprite;
	var valueSetBG:FlxSprite;

	override function create()
	{
		persistentDraw = true;
		persistentUpdate = true;
		mainCamera = new FlxCamera();
		valSetCamera = new FlxCamera();
		mainCamera.bgColor.alpha = 0;
		valSetCamera.bgColor.alpha = 0;
		transCamera.bgColor.alpha = 0;
		if(optState){
			FlxG.cameras.reset(mainCamera);
			FlxG.cameras.add(valSetCamera, false);
			FlxG.cameras.add(transCamera, false);
			camerasToRemove.push(mainCamera);

		}else{
			FlxG.cameras.add(mainCamera, false);
			FlxG.cameras.add(valSetCamera, false);
			FlxG.cameras.add(transCamera, false);
		}
		camerasToRemove.push(valSetCamera);
		camerasToRemove.push(transCamera);

		valSetCamera.x += 480;

		cameras = [mainCamera];
		camFollow = new FlxObject(0,240);
		add(camFollow);


		makeOptions();

		var valueSetBG = new FlxSprite(800, 0).makeGraphic(1280 - 800, 720, 0xFF000000);
		add(valueSetBG);

		valueSetSprite = new FlxSprite(0, 0).makeGraphic(30, 30, 0xFFFFFFFF);
		add(valueSetSprite);
		choicesGrp = new FlxSpriteGroup(800);
		add(choicesGrp);
		choicesGrp.cameras = [valSetCamera];
		valueSetSprite.cameras = [valSetCamera];
		valueSetBG.cameras = [valSetCamera];

		valueSetBar = new FlxBar(0,0, BOTTOM_TO_TOP, 70, 480, null, '', 0, 1);
		valueSetBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		valueSetBar.numDivisions = 480;
		valueSetBar.scrollFactor.set();
		add(valueSetBar);
		valueSetBar.value = 0.5;
		valueSetBar.centerObjectInObject(valueSetBG, XY);
		valueSetBar.cameras = [valSetCamera];

		valueSetNumberText = new FlxText(800,0,480,'240 FPS');
		valueSetNumberText.setFormat(Paths.font('helveticaib.ttf'), 36, 0xFFFFFFFF, 'center');
		valueSetNumberText.antialiasing = false;
		add(valueSetNumberText);
		valueSetNumberText.cameras = [valSetCamera];
		valueSetNumberText.y = valueSetBar.y + valueSetBar.height + 32;




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
				
				var cataText = new FlxText(0,24,1280,optdefs.get(option).desc);
				cataText.setFormat(Paths.font('helveticaib.ttf'), 12, 0xFFFFFFFF, 'left');
				cataText.antialiasing = false;
				sprites.add(cataText);
				cataText.x = 0;

				var cataText = new FlxText(0,4,480,"Placeholder");
				cataText.setFormat(Paths.font('helveticaib.ttf'), 16, 0xFFFFFFFF, 'right');
				cataText.antialiasing = false;
				sprites.add(cataText);
				valueTexts.set(option, cataText);
				cataText.x = 0;
				optionsTuff.push(sprites);

				sprites.setPosition(it*marginValX + 36, marginValY + 90);
			}
			it++;
			xmbSelectables.set(i, optionsTuff);
		}
		refreshAllTexts();
	}

	function refreshAllTexts() {
		var optdefs = ClientPrefs.getOptionDefinitions();
		for (option=>text in valueTexts) {
			var optiond = optdefs.get(option);
			if (optiond != null) {
				switch (optiond.type) {
					case Button:
						text.text = 'Press ACCEPT';
					case Dropdown:
						text.text = Reflect.getProperty(ClientPrefs, option);
					case Number:
						var val:Float = Reflect.getProperty(ClientPrefs, option);

						if (optiond.data.exists("type")) {
							if (optiond.data.get("type") == 'percent') {
								val *= 100.0;
							}
						}
						text.text = '';
						if (optiond.data.exists("prefix"))
							text.text += optiond.data.get("prefix");
						text.text += val;
						if (optiond.data.exists("suffix"))
							text.text += optiond.data.get("suffix");
					case Toggle:
						text.text = Reflect.getProperty(ClientPrefs, option) ? 'Yes' : 'No'; 
				}
			} else {
				text.text = '';
			}
		}
	}

	function changeSelectionChoice(mod:Int) {
		curSelectedChoice = FlxMath.wrap(curSelectedChoice + mod, 0, choices.length-1);
	}

	function changeSelectionX(mod:Int) {
		FlxG.sound.play(Paths.sound('options/select'));
		curSelected = FlxMath.wrap(curSelected + mod, 0, optionOrder.length-1);
	}

	function changeSelectionY(mod:Int) {
		FlxG.sound.play(Paths.sound('options/select'));
		curSelectedY[curSelected] = FlxMath.wrap(curSelectedY[curSelected] + mod, 0, options.get(optionOrder[curSelected]).length-1);
	}

	function generateChoices() {
		curSelectedChoice = choices.indexOf(Reflect.getProperty(ClientPrefs, choicesOption));
		choicesGrp.clear();
		var it = 0;
		for (i in choices) {
			var cataText = new FlxText(12,(it - (choices.length / 2)) * 36 + 360,0,i == true ? 'Yes' : i == false ? 'No' : i);
			cataText.setFormat(Paths.font('helveticaib.ttf'), 32, 0xFFFFFFFF, 'left');
			cataText.antialiasing = false;
			choicesGrp.add(cataText);
			it++;
		}
	}

	function valueSetMenuBool(option:String, data:OptionData) {
		numberMode = false;
		notInValueSet = false;
		FlxTween.tween(mainCamera, {x: -480}, 0.25, {ease: FlxEase.circOut});
		FlxTween.tween(valSetCamera, {x: 0}, 0.25, {ease: FlxEase.circOut});
		choices = [true, false];
		optData = data;
		choicesOption = option;
		generateChoices();
	}

	function valueSetMenuChoices(option:String, data:OptionData) {
		notInValueSet = false;
		numberMode = false;
		FlxTween.tween(mainCamera, {x: -480}, 0.25, {ease: FlxEase.circOut});
		FlxTween.tween(valSetCamera, {x: 0}, 0.25, {ease: FlxEase.circOut});
		choicesOption = option;
		optData = data;
		choices = data.data.get("options");
		generateChoices();
	}
	
	function valueSetMenuNumber(option:String, data:OptionData) {
		notInValueSet = false;
		numberMode = true;
		FlxTween.tween(mainCamera, {x: -480}, 0.25, {ease: FlxEase.circOut});
		FlxTween.tween(valSetCamera, {x: 0}, 0.25, {ease: FlxEase.circOut});
		choicesOption = option;
		choices = [];
		choicesGrp.clear();
		optData = data;
		numberVal = Reflect.getProperty(ClientPrefs, choicesOption);
	}

    function acceptFunction() {
		var optdefs = ClientPrefs.getOptionDefinitions();
		var dataName = options.get(optionOrder[curSelected])[curSelectedY[curSelected]];
		var optiond = optdefs.get(dataName);
		switch (optiond.type) {
			case Button:
				switch (dataName) {
					default:
						return;
				}
			case Dropdown:
				valueSetMenuChoices(dataName, optiond);
			case Number:
				valueSetMenuNumber(dataName, optiond);
			case Toggle:
				valueSetMenuBool(dataName, optiond);
		}
	}

	var notInValueSet = true;
	var holdTimer = 0.0;
	var holderTimer = 0.0;
	var firstFrame = true;
	override function update(elapsed:Float)
	{
		if (notInValueSet) {
			if (subState == null)
			{
				if (controls.BACK) {
					goBack(changed);
				}
			}

			if (controls.ACCEPT) {
				acceptFunction();
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
		} else {
			if (controls.BACK) {
				notInValueSet = true;
				FlxTween.tween(mainCamera, {x: 0}, 0.25, {ease: FlxEase.circOut});
				FlxTween.tween(valSetCamera, {x: 480}, 0.25, {ease: FlxEase.circOut});
			}

			if (controls.ACCEPT) {
				Reflect.setProperty(ClientPrefs, choicesOption, numberMode ? numberVal : choices[curSelectedChoice]);
				refreshAllTexts();
				notInValueSet = true;
				FlxTween.tween(mainCamera, {x: 0}, 0.25, {ease: FlxEase.circOut});
				FlxTween.tween(valSetCamera, {x: 480}, 0.25, {ease: FlxEase.circOut});
			}
			if (!numberMode) {
				if (controls.UI_UP_P) {
					changeSelectionChoice(-1);
				} else if (controls.UI_DOWN_P) {
					changeSelectionChoice(1);
				}
			} else {
				function isPercent(data) {
					return data.exists('type') && data.get('type') == 'percent';
				}
				var justUp = controls.UI_UP_P;
				var justDown = controls.UI_DOWN_P;
				var up = justUp || controls.UI_UP;
				var down = justDown || controls.UI_DOWN;
				if (up || down){
					holderTimer += elapsed;
					var mod:Float = 0;
					if (justUp){
						holderTimer = 0.0;
						mod = 1;
						holdTimer = 0.0;
					}
					else if (up){
						if (holdTimer < -0.25){
							holdTimer += 0.05 - FlxMath.bound(holderTimer / 100, 0, 0.03);
							mod = 1;
						}
						holdTimer -= elapsed;
					}

					if (justDown){
						mod = -1;
						holderTimer = 0.0;
						holdTimer = 0.0;
					}
					else if (down){
						if (holdTimer > 0.25){
							holdTimer -= 0.05 - FlxMath.bound(holderTimer / 100, 0, 0.03);
							mod = -1;
						}
						holdTimer += elapsed;
					}
					if (isPercent(optData.data)) {
							mod /= 100;
					}
					if (mod != 0) {
						FlxG.sound.play(Paths.sound('options/select'));
					}
					var step = optData.data.get('step') / (isPercent(optData.data) ? 100.0 : 1);
					numberVal = numberVal + (Math.fround(((FlxG.keys.pressed.SHIFT ? 5 : 1) * (mod*optData.data.get('step'))) / step) * step);
					if (numberVal < optData.data.get('min') / (isPercent(optData.data) ? 100.0 : 1)) numberVal = optData.data.get('min') / (isPercent(optData.data) ? 100.0 : 1);
					if (numberVal > optData.data.get('max') / (isPercent(optData.data) ? 100.0 : 1)) numberVal = optData.data.get('max') / (isPercent(optData.data) ? 100.0 : 1);
				}
				
				valueSetNumberText.text = '';
				if (optData.data.exists("prefix"))
					valueSetNumberText.text += optData.data.get("prefix");
				valueSetNumberText.text += numberVal * (isPercent(optData.data) ? 100.0 : 1);
				if (optData.data.exists("suffix"))
					valueSetNumberText.text += optData.data.get("suffix");

				if (isPercent(optData.data))
					valueSetBar.value = numberVal;
				else
					valueSetBar.value = FlxMath.remapToRange(numberVal * 1.0, optData.data.get('min'),optData.data.get('max'),0.0,1.0);
				
			}
		}

		mainCamera.followLerp = elapsed * 8;
		camFollow.x = FlxMath.lerp(camFollow.x, xmbCategories.get(optionOrder[curSelected]).x + 240, elapsed * 9);
		mainCamera.follow(camFollow);
		
		if (choicesGrp.members.length != 0 && choicesGrp.members != []) {
			var ins = [
				choicesGrp.members[curSelectedChoice].x + choicesGrp.members[curSelectedChoice].width + 16,
				choicesGrp.members[curSelectedChoice].y + ((choicesGrp.members[curSelectedChoice].height - valueSetSprite.height)/2)
			];
			valueSetSprite.x = ins[0];
			valueSetSprite.y = ins[1];
		}
		valueSetSprite.alpha = numberMode ? 0:1;
		for (opt=>groups in xmbSelectables) {
			var it = 0;
			for (group in groups) {
				var intendedAlpha:Float = 1;
				if (opt == optionOrder[curSelected]) {
					if (it - curSelectedY[optionOrder.indexOf(opt)] != 0) {
						intendedAlpha = 0.5;
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

