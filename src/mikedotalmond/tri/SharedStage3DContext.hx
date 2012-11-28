package mikedotalmond.tri;
import flash.display.Stage;
import flash.display.Stage3D;
import flash.display3D.Context3D;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.Context3DCompareMode;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.textures.RectangleTexture;
import flash.events.Event;
import flash.events.FullScreenEvent;
import flash.geom.Rectangle;
import flash.system.Capabilities;
import hxs.Signal;
import hxs.Signal2;

/**
 * ...
 * @author Mike Almond - https://github.com/mikedotalmond
 */


@:final class SharedStage3DContext {
	
	#if debug
	public static inline var Debug  = true;
	public static inline var AA 	= 0;
	#else
	public static inline var Debug 	= false;
	public static inline var AA		= 8;
	#end
	
	public static var CPUArchitecture	:String = Capabilities.cpuArchitecture;
	public static var isMobile			:Bool 	= CPUArchitecture == "ARM";
	
	public var stage(default,null):Stage;
	public var stage3D(default,null):Stage3D;
	public var context3D(default,null):Context3D;
	
	public var ready(default,null):Signal;
	public var resize(default, null):Signal2<Int,Int>;
	public var requestDraw(default,null):Signal2<Float,Float>;
	
	public var stageWidth(default, null):Int;
	public var stageHeight(default, null):Int;
	
	public var halfStageWidth(default, null):Int;
	public var halfStageHeight(default, null):Int;
	
	public var fullViewport(default, null):Rectangle;
	
	public function new(stage:Stage, stage3D:Stage3D = null) {
		
		ready 		= new Signal();
		resize 		= new Signal2<Int,Int>();
		requestDraw = new Signal2<Float,Float>();
		fullViewport = new Rectangle();
		
		this.stage = stage;
		this.stage3D = stage3D != null ? stage3D : stage.stage3Ds[0];
		this.stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextReady, false, 1000);
		this.stage3D.requestContext3D();
	}
	
	private function onContextReady( _ ) {
		//trace("Context ready", "info");
		//trace("CPUArchitecture:" + CPUArchitecture, "info");
		
		context3D = stage3D.context3D;
		
		stage.addEventListener(Event.RESIZE, onResize);
		stage.addEventListener(FullScreenEvent.FULL_SCREEN, onResize);
		
		onResize(null);
		
		ready.dispatch();
	}
	
	
	private function onResize(e:Event):Void {
		
		if (isMobile) {
			stageWidth 	= stage.fullScreenWidth;
			stageHeight = stage.fullScreenHeight;
		} else {
			stageWidth 	= stage.stageWidth;
			stageHeight = stage.stageHeight;
		}
		
		fullViewport.width  = stageWidth;
		fullViewport.height = stageHeight;
		halfStageWidth 		= Std.int(stageWidth * .5);
		halfStageHeight 	= Std.int(stageHeight * .5);
		
		// set the backbuffer size
		context3D.enableErrorChecking = Debug;
		context3D.configureBackBuffer(stageWidth, stageHeight, AA, false);
		
		// allow alpha blending
		 context3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
		
		// no depth test for now...
		context3D.setDepthTest(false, Context3DCompareMode.LESS_EQUAL);
		
		// don't draw back-faces
		context3D.setCulling(Context3DTriangleFace.BACK);
		
		if (e != null) resize.dispatch(stageWidth, stageHeight);
	}
	
	
	
	public function update(delta:Float, time:Float) {
		if (null == stage3D) return;
		
		context3D.clear();
		
		requestDraw.dispatch(delta, time);
		
		context3D.present();
	}
	
}