package;

import ru.stablex.ui.*;
import ru.stablex.ui.skins.*;
import ru.stablex.ui.events.*;
import ru.stablex.ui.widgets.*;

class CustomWidget extends Widget {
	public function new () {
		trace('Wgt costuctor');
		super();
		
		this.w = 200;
		this.h = 100;
		
		this.top = 10;
		this.left = 10;
		
		var skin:Paint = new Paint();
		skin.color = 0xC0C0C0;
		skin.border = 1;
		skin.borderColor = 0xFF00FF;
		
		this.skin = skin;
	}
	
	/*override public function onCreate() : Void {
		trace('Wgt onCreate');
		super.onCreate();
	}
	override public function free (recursive:Bool = true) : Void {
		trace('Wgt free');
		super.free(recursive);
	}*/
	override public function applySkin () : Void {
		//var d = null;
		//d.qwe();
		//trace('Wgt applySkin');
		trace(this.initialized);
		trace(this.skin != null);
		super.applySkin();
	}
	/*override public function applyLayout () : Void {
		trace('Wgt applyLayout');
		super.applyLayout();
	}
	override public function refresh() : Void {
		trace('Wgt refresh');
		super.refresh();
	}
	override public function onNewParent(newParent:Widget) : Void {
		trace('Wgt onNewParent');
		super.onNewParent(newParent);
	}
	override public function resize(width:Float, height:Float, keepPercentage:Bool = false) : Void {
		trace('Wgt resize');
		super.resize(width, height, keepPercentage);
	}
	override public function onResize() : Void {
		trace('Wgt onResize');
		super.onResize();
	}*/
}
