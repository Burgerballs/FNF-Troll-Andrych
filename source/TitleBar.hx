import openfl.ui.Mouse;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Sprite;

import openfl.events.MouseEvent;

class TitleBar extends Sprite {
    var underlay:Bitmap;
    var text:TextField;
    public function new()
	{
        super();
        underlay = new Bitmap();
		underlay.bitmapData = new BitmapData(1280, 36, true, 0x66000000);
		addChild(underlay);

        text = new TextField();
        text.x = 9;
        text.y = 9;
        text.text = "Fun Title Bar!";

        addChild(text);
        text.selectable = false;
        text.mouseEnabled = false;
        var textFormat = new TextFormat(null, 16, 0xFFFFFFFF);
		text.embedFonts = true;
		textFormat.font = 'Helvetica';
		text.defaultTextFormat = textFormat;

        addEventListener(MouseEvent.MOUSE_DOWN, onMousePress);
    }
}