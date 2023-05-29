package flixel.addons.ui;

import flixel.addons.ui.FlxUI.NamedBool;
import flixel.addons.ui.interfaces.*;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxTimer;

/**
 * @author Lars Doucet
 */
class FlxUICheckBox extends FlxUIGroup implements ILabeled implements IFlxUIClickable implements IHasParams implements ICursorPointable
{
	public var box:FlxSprite;
	public var mark:FlxSprite;
	public var button:FlxUIButton;
	public var max_width:Float = -1;

	public var checked(default, set):Bool = false;
	public var params(default, set):Array<Dynamic>;

	// Set this to false if you just want the checkbox itself to be clickable
	public var textIsClickable:Bool = true;

	public var checkbox_dirty:Bool = false;

	public var textX(default, set):Float = 0;
	public var textY(default, set):Float = 0;

	public var box_space:Float = 2;

	public var skipButtonUpdate(default, set):Bool = false;

	public var callback:Void->Void;

    public var clickable(default, set):Bool = true;

	public static inline var CLICK_EVENT:String = "click_check_box";

	private function set_skipButtonUpdate(b:Bool):Bool
	{
		skipButtonUpdate = b;
		button.skipButtonUpdate = skipButtonUpdate;
		return skipButtonUpdate;
	}

	private function set_params(p:Array<Dynamic>):Array<Dynamic>
	{
		params = (p == null) ? [] : p;
		var nb:NamedBool = {name: "checked", value: false};
		params.push(nb);
		return params;
	}

	private override function set_color(Value:Int):Int
	{
		if (button != null) button.label.color = Value;
		return super.set_color(Value);
	}

	public function new(X:Float = 0, Y:Float = 0, ?Box:Dynamic, ?Check:Dynamic, ?Label:String, ?LabelW:Int = 100, ?Params:Array<Dynamic>, ?Callback:Void->Void)
	{
		super();

		callback = Callback;
		params = Params;

        // if null create a simple checkbox outline
		if (Box == null) Box = FlxUIAssets.IMG_CHECK_BOX;
        box = (Box is FlxSprite) ? cast Box : new FlxSprite().loadGraphic(Box, true);

		button = new FlxUIButton(0, 0, Label, _clickCheck);

		// set default checkbox label format
		button.label.setFormat(null, 8, 0xffffff, "left", OUTLINE);
		button.label.fieldWidth = LabelW;
		button.up_color = 0xffffff;
		button.down_color = 0xffffff;
		button.over_color = 0xffffff;
		button.up_toggle_color = 0xffffff;
		button.down_toggle_color = 0xffffff;
		button.over_toggle_color = 0xffffff;

		button.loadGraphicSlice9(["", "", ""], Std.int(box.width + box_space + LabelW), Std.int(box.height));

		max_width = Std.int(box.width + box_space + LabelW);

		button.onUp.callback = _clickCheck; // for internal use, check/uncheck box, bubbles up to _externalCallback

        // if null load from default assets:
		if (Check == null) Check = FlxUIAssets.IMG_CHECK_MARK;
        mark = (Check is FlxSprite) ? cast Check : new FlxSprite().loadGraphic(Check);

		add(box);
		add(mark);
		add(button);

		anchorLabelX();
		anchorLabelY();

		checked = false;

		// set all these to 0
		button.setAllLabelOffsets(0, 0);

		x = X;
		y = Y;

		textX = textY = 0; // forces anchorLabel() to be called and upate correctly
	}

    /**
     * Variable to dictate whetever or not the clickability of `this` checkbox affects the alpha.
     * 
     * If true will set alpha lower if `clickable` is set to `false`.
     */
    public var lowerAlphaLock:Null<Bool> = null;
    private var oldAlpha:Float = 1; //Store the old alpha value
    /**
     * A convenience function for quickly changing the clickability and alphalock value.
     * @param canClick New value for `clickable`
     * @param affectAlpha New value for `lowerAlphaLock`
     * @return The new state of `clickable`
     */
    public function setClickable(canClick:Bool, ?affectAlpha:Null<Bool> = null):Bool {
        lowerAlphaLock = (affectAlpha != null) ? affectAlpha : lowerAlphaLock;
        clickable = canClick;
        return canClick;
    }

    function set_clickable(newVal:Bool):Bool {
        if(visible && lowerAlphaLock) {
            oldAlpha = (clickable && !newVal) ? alpha : oldAlpha;
            alpha = newVal ? oldAlpha : oldAlpha / 2;
        }
        clickable = newVal;
        return clickable;
    }

	/*
		public function copy(?Params:Array<Dynamic>,?Callback:Void->Void):FlxUICheckBox {
			var boxAsset:String = box != null ? box.cachedGraphics.key : null;
			var checkAsset:String = mark != null ? mark.cachedGraphics.key : null;
			var label:String = (button != null && button.label != null) ? button.label.text : null;
			var labelW:Int = (label != null) ? Std.int(button.label.width) : 100;
			return new FlxUICheckBox(x, y, boxAsset, checkAsset, label, labelW, Params, Callback);
	}*/
	/**For ILabeled:**/
	public function setLabel(t:FlxUIText):FlxUIText
	{
		if (button == null) return null;

		button.label = t;
		return button.label;
	}

	public function getLabel():FlxUIText
	{
        return (button == null ? null : button.label);
	}

	private override function set_visible(Value:Bool):Bool
	{
		// don't cascade to my members
		visible = Value;
		return visible;
	}

	private function anchorTime(f:FlxTimer):Void
	{
		anchorLabelY();
	}

	private function set_textX(n:Float):Float
	{
		textX = n;
		anchorLabelX();
		return textX;
	}

	private function set_textY(n:Float):Float
	{
		textY = n;
		anchorLabelY();
		return textY;
	}

	public function anchorLabelX():Void
	{
		if (button != null) button.label.offset.x = -((box.width + box_space) + textX);
	}

	public function anchorLabelY():Void
	{
		if (button != null) button.y = box.y + (box.height - button.height) / 2 + textY;
	}

	public override function destroy():Void
	{
		super.destroy();

        for(sprite in [mark, box, button]) {
            if((sprite is FlxUIButton ? cast(sprite, FlxUIButton) : cast(sprite, FlxSprite)) != null) {
                sprite.destroy();
                sprite = null;
            }
        }
	}

	public var text(get, set):String;

	private function get_text():String
	{
		return button.label.text;
	}

	private function set_text(value:String):String
	{
		button.label.text = value;
		checkbox_dirty = true;
		return value;
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

        if (!checkbox_dirty || button.label == null) return;

        if ((button.label is FlxUIText))
            cast(button.label, FlxUIText).drawFrame();
        anchorLabelX();
        anchorLabelY();
        button.width = box.frameWidth + box_space +
            button.label.textField.textWidth; // makes the clickable size exactly match the visible size of checkbox+label
        checkbox_dirty = false;
	}

	/*****GETTER/SETTER***/
	private function set_checked(b:Bool):Bool
	{
		mark.visible = b;
		return checked = b;
	}

	/*****PRIVATE******/
	private function _clickCheck():Void
	{
		if (!visible || !clickable) return;

		checked = !checked;
		if (callback != null) callback();
		if (broadcastToFlxUI) FlxUI.event(FlxUICheckBox.CLICK_EVENT, this, checked, params);
	}
}
