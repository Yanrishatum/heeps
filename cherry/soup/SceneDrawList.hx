package cherry.soup;
#if hlimgui
import imgui.types.Renderer;
import imgui.ImGui;
import imgui.ImGuiUtils;

private class SceneDrawListImpl {
  
  public var dl: ImDrawList;
  public var scale: ImVec2;
  public var offset: ImVec2;
  
  public inline function new(dl: ImDrawList, s2d: h2d.Scene) {
    this.dl = dl;
    this.scale = imvec2(s2d.viewportScaleX, s2d.viewportScaleY);
    this.offset = imvec2(@:privateAccess s2d.offsetX, @:privateAccess s2d.offsetY);
  }
  
  inline function s(v: ImVec2) return v * scale + offset;
  
	public inline function pushClipRect(clipRectMin: ImVec2, clipRectMax: ImVec2, intersectWithCurrentClipRect: Bool = false) { dl.pushClipRect(clipRectMin*scale+offset, clipRectMax*scale+offset, intersectWithCurrentClipRect); }
	public inline function pushClipRectFullScreen() { dl.pushClipRectFullScreen(); }
	public inline function popClipRect() { dl.popClipRect(); }
	public inline function pushTextureId(textureId: ImTextureID) { dl.pushTextureId(textureId); }
	public inline function popTextureId() { dl.popTextureId(); }
	public inline function getClipRectMin(): ImVec2 { return (dl.getClipRectMin()-offset)/scale; }
	public inline function getClipRectMax(): ImVec2 { return (dl.getClipRectMax()-offset)/scale; }

	public inline function addLine( p1: ImVec2, p2: ImVec2, col: ImU32, thickness: Single = 1.0 ) { dl.addLine(s(p1), s(p2), col, thickness); }
	public inline function addRect( pMin: ImVec2, pMax: ImVec2, col: ImU32, rounding: Single = 0.0, roundingCorners: ImDrawFlags = ImDrawFlags.None, thickness: Single = 1.0 ) {
    dl.addRect(s(pMin), s(pMax), col, rounding, roundingCorners, thickness);
  }
	public inline function addRectFilled( pMin: ImVec2, pMax: ImVec2, col: ImU32, rounding: Single = 0.0, roundingCorners: ImDrawFlags = ImDrawFlags.None ) {
    dl.addRectFilled(s(pMin), s(pMax), col, rounding, roundingCorners);
  }
	public inline function addRectFilledMultiColor( pMin: ImVec2, pMax: ImVec2, col_upr_left: ImU32, col_upr_right: ImU32, col_bot_right: ImU32, col_bot_left: ImU32 ) {
    dl.addRectFilledMultiColor(s(pMin), s(pMax), col_upr_left, col_upr_right, col_bot_right, col_bot_left);
  }
	public inline function addQuad( p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, col: ImU32, thickness: Single = 1.0 ) {
    dl.addQuad(s(p1), s(p2), s(p3), s(p4), col, thickness);
  }
	public inline function addQuadFilled( p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, col: ImU32 ) {
    dl.addQuadFilled(s(p1), s(p2), s(p3), s(p4), col);
  }
	public inline function addTriangle( p1: ImVec2, p2: ImVec2, p3: ImVec2, col: ImU32, thickness: Single = 1.0 ) {
    dl.addTriangle(s(p1), s(p2), s(p3), col, thickness);
  }
	public inline function addTriangleFilled( p1: ImVec2, p2: ImVec2, p3: ImVec2, col: ImU32 ) {
    dl.addTriangleFilled(s(p1), s(p2), s(p3), col);
  }
	public inline function addCircle( center: ImVec2, radius: Single, col: ImU32, num_segments: Int = 0, thickness: Single = 1.0 ) {
    dl.addCircle(s(center), radius, col, num_segments, thickness); // TODO: Scaled version
  }
	public inline function addCircleFilled( center: ImVec2, radius: Single, col: ImU32, num_segments: Int = 0) {
    dl.addCircleFilled(s(center), radius, col, num_segments); // TODO: Scaled version
  }
	public inline function addNgon( center: ImVec2, radius: Single, col: ImU32, num_segments: Int, thickness: Single = 1.0 ) {
    dl.addNgon(s(center), radius, col, num_segments, thickness); // TODO: Scaled version
  }
	public inline function addNgonFilled( center: ImVec2, radius: Single, col: ImU32, num_segments: Int) {
    dl.addNgonFilled(s(center), radius, col, num_segments);
  }
	// public inline function addPolyLine( points: hl.NativeArray<ImVec2>, col: ImU32, closed: Bool, thickness: Single = 1.0 ) {}
	// public inline function addConvexPolyFilled( points: hl.NativeArray<ImVec2>, col: ImU32 ) {}
	
	// public inline function addBezierCubic( p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, col: ImU32, thickness: Single, num_segments: Int = 0 ) {}
	// public inline function addBezierQuadratic( p1: ImVec2, p2: ImVec2, p3: ImVec2, col: ImU32, thickness: Single, num_segments: Int = 0 ) {}
	
	public inline function addText( pos: ImVec2, col: ImU32, text: String ) {
    dl.addText(s(pos), col, text);
  }
	public inline function addText2( font: ImFont, fontSize: Single, pos: ImVec2, col: ImU32, text: String, wrapWidth: Single = 0.0, ?cpuFineClipRect: ImVec4 ) {
    dl.addText2(font, fontSize, s(pos), col, text, wrapWidth, cpuFineClipRect);
  }

	public inline function addImage( userTextureId: ImTextureID, pMin: ImVec2, pMax: ImVec2, ?uvMin: ImVec2, ?uvMax: ImVec2, col: Int = 0xffffffff ) {
    dl.addImage(userTextureId, s(pMin), s(pMax), uvMin, uvMax, col);
  }
	public inline function addImageQuad( userTextureId: ImTextureID, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, ?uv1: ImVec2, ?uv2: ImVec2, ?uv3: ImVec2, ?uv4: ImVec2, col: Int = 0xffffffff ) {
    dl.addImageQuad(userTextureId, s(p1), s(p2), s(p3), s(p4), uv1, uv2, uv3, uv4, col);
  }
	public inline function addImageRounded( userTextureId: ImTextureID, pMin: ImVec2, pMax: ImVec2, uvMin: ImVec2, uvMax: ImVec2, col: Int, rounding: Single, roundingCorners: ImDrawFlags = RoundCornersDefault_ ) {
    dl.addImageRounded(userTextureId, s(pMin), s(pMax), uvMin, uvMax, col, rounding, roundingCorners);
  }

	// Stateful path API, add points then finish with pathFillConvex() or pathStroke()

	public inline function pathClear() { dl.pathClear(); }
	public inline function pathLineTo(pos: ImVec2) { dl.pathLineTo(s(pos)); }
	public inline function pathLineToMergeDuplicate(pos: ImVec2) { dl.pathLineToMergeDuplicate(s(pos)); }
	public inline function pathFillConvex(col: Int) { dl.pathFillConvex(col); }
	public inline function pathStroke(col: Int, flags: ImDrawFlags = 0, thickness: Single = 1.0) { dl.pathStroke(col, flags, thickness); }
	public inline function pathArcTo(center: ImVec2, radius: Single, a_min: Single, a_max: Single, num_segments: Int = 0) { dl.pathArcTo(s(center), radius, a_min, a_max, num_segments); }
	/* Use precomputed angles for a 12 steps circle */
	// public inline function pathArcToFast(center: ImVec2, radius: Single, a_min_of_12: Int, a_max_of_12: Int) {}
	public inline function pathBezierCubicCurveTo(p2: ImVec2, p3: ImVec2, p4: ImVec2, num_segments: Int = 0) { dl.pathBezierCubicCurveTo(s(p2), s(p3), s(p4), num_segments); }
	public inline function pathBezierQuadraticCurveTo(p2: ImVec2, p3: ImVec2, num_segments: Int = 0) { dl.pathBezierQuadraticCurveTo(s(p2), s(p3), num_segments); }
	public inline function pathRect(rect_min: ImVec2, rect_max: ImVec2, rounding: Single = 0.0, flags: ImDrawFlags = 0) { dl.pathRect(s(rect_min), s(rect_max), rounding, flags); }
	
	// Advanced
	
	public inline function addCallback(callback: RenderCommandCallback, ?data: Dynamic) { dl.addCallback(callback, data); }
	public inline function addDrawCmd() { dl.addDrawCmd(); }
	// public inline function cloneOutput(): ImDrawList; // TODO
	
	public inline function addTile( tile: h2d.Tile, pMin: ImVec2, ?pMax: ImVec2, col: Int = 0xffffffff, honorDxDy = false) @:privateAccess {
    dl.addTile(tile, s(pMin), s(pMax), col, honorDxDy);
	}

	public inline function addTileQuad( tile: h2d.Tile, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, col: Int = 0xffffffff) @:privateAccess {
    dl.addTileQuad(tile, s(p1), s(p2), s(p3), s(p4), col);
	}

	public inline function addTileRounded( tile: h2d.Tile, pMin: ImVec2, ?pMax: ImVec2, col: Int, rounding: Single, roundingCorners: ImDrawFlags = -1, honorDxDy = false ) @:privateAccess {
    dl.addTileRounded(tile, s(pMin), s(pMax), col, rounding, roundingCorners, honorDxDy);
	}
}

@:forward
abstract SceneDrawList(SceneDrawListImpl) from SceneDrawListImpl {
	
  
  // @:from public static inline function fromDrawList(dl: ImDrawList): SceneDrawList {
  //   return new SceneDrawListImpl(dl, Main.i.s2d);
  // }
  public static inline function fromDrawList(dl: ImDrawList, s2d: h2d.Scene): SceneDrawList {
    return new SceneDrawListImpl(dl, s2d);
  }
  
}

#end