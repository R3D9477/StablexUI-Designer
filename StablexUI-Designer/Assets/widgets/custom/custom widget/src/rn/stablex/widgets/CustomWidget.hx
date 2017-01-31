package rn.stablex.widgets;

import ru.stablex.ui.*;
import ru.stablex.ui.skins.*;
import ru.stablex.ui.events.*;
import ru.stablex.ui.widgets.*;

class CustomWidget extends Widget {
	public function new () {
		trace("CustomWidget:new");
		
		super();
		
		this.w = 200;
		this.h = 100;
		
		this.top = 10;
		this.left = 10;
	}
	
	override public function onCreate() : Void {
		trace("CustomWidget:onCreate");
		
		super.onCreate();
	}
	
	override public function free (recursive:Bool = true) : Void {
		trace("CustomWidget:free");
		
		super.free(recursive);
	}
	
	override public function applySkin () : Void {
		trace("CustomWidget:applySkin");
		
		super.applySkin();
	}
	
	override public function applyLayout () : Void {
		trace("CustomWidget:applyLayout");
		
		super.applyLayout();
	}
	
	override public function refresh() : Void {
		trace("CustomWidget:refresh");
		
		super.refresh();
	}
	
	override public function onNewParent(newParent:Widget) : Void {
		trace("CustomWidget:onNewParent");
		
		super.onNewParent(newParent);
	}
	
	override public function resize(width:Float, height:Float, keepPercentage:Bool = false) : Void {
		trace("CustomWidget:resize");
		trace('width: $width');
		trace('height: $height');
		trace('keepPercentage: $keepPercentage');
		
		super.resize(width, height, keepPercentage);
	}
	
	override public function onResize() : Void {
		trace("CustomWidget:onResize");
		
		super.onResize();
	}
	
	override private function _onParentResize(e:WidgetEvent) : Void {
		trace("CustomWidget:onParentResize");
		trace('target: ${Type.getClassName(Type.getClass(e.currentTarget))}');
		
		// Warning, e.currentTarget can't be casted to <CustomWindget.n>.Widget!
		// Because for neko (ru.stablex.ui.widgets.Widget from module CustomWindget.n) != (ru.stablex.ui.widgets.Widget from module of object "e.currentTarget")
		
		super.applySkin();
		
		//...
		//...
		//...
	}
}
