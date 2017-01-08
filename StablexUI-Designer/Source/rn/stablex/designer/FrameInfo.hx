package rn.stablex.designer;

typedef FrameInfo = {
	var title:String;
	
	var xml:String;
	
	var width:Float;
	var height:Float;
	
	var background:Int;
	var fps:Int;
	var vsync:Bool;
	var borderless:Bool;
	var resizable:Bool;
	var fullscreen:Bool;
	var hardware:Bool;
	var allowShaders:Bool;
	var requireShaders:Bool;
	var depthBuffer:Bool;
	var stencilBuffer:Bool;
	
	var orientation:String;
}
