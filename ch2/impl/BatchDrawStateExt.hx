package ch2.impl;

import hxsl.ShaderList;
import hxsl.Shader;
import h3d.Indexes;
import ch3.shader.MultiTexture2;
import h3d.Buffer;
import h2d.RenderContext;
import h3d.mat.Texture;

// Since I fucked up and marked StateEntry as private, I can't just extend it - have to copy entire class, yay.
@:access(h2d.RenderContext)
class BatchDrawStateExt {

	/**
		Current active texture of the BatchDrawState.
		Represents the most recent texture that was set with `setTile` or `setTexture`.
		Always null after state initialization or after `clear` call.
	**/
	public var currentTexture(get, never) : h3d.mat.Texture;
	
	public var currentShader(get, never): hxsl.ShaderList;
	/**
		A total amount of vertices added to the BatchDrawState.
	**/
	public var totalCount(default, null) : Int;

	var head : StateEntry;
	var tail : StateEntry;

	/**
		Create a new BatchDrawState instance.
	**/
	public function new() {
		this.head = this.tail = new StateEntry(null, null);
		this.totalCount = 0;
	}

	/**
		Switches currently active texture to one in the given `tile` if it differs and splits the render state.
		@param tile A Tile containing a texture that should be used for the next set of vertices. Does nothing if `null`.
	**/
	public inline function setTile( tile : h2d.Tile ) {
		if ( tile != null ) setTexture(tile.getTexture());
		return 0;
	}

	/**
		Switches currently active texture to the given `texture` if it differs and splits the render state.
		@param texture The texture that should be used for the next set of vertices. Does nothing if `null`.
	**/
	public function setTexture( texture : h3d.mat.Texture ) {
		if ( texture != null ) {
			if (tail.texture == null || tail.count == 0) {
				tail.texture = texture;
			} else if (tail.texture != texture) {
				var cur = tail;
				if ( cur.next == null ) cur.next = tail = new StateEntry(texture, cur.shader);
				else tail = cur.next.set(texture, cur.shader);
			}
		}
	}
	
	public function setShader(shader: ShaderList) {
		if (tail.shader != shader) {
			var cur = tail;
			if (cur.count == 0) cur.shader = shader;
			else if (cur.next == null) cur.next = tail = new StateEntry(cur.texture, shader);
			else tail = cur.next.set(cur.texture, shader);
		}
	}

	/**
		Add vertices to the state using currently active texture.
		Should be called when rendering buffers add more data in order to properly render the geometry.
		@param count The amount of vertices to add.
	**/
	public inline function add( count : Int ) {
		tail.count += count;
		totalCount += count;
	}

	/**
		Resets the BatchDrawState by removing all texture references and zeroing vertex counter.
	**/
	public function clear() {
		var state = head;
		do {
			state.shader = null;
			state = state.next;
		} while ( state != null );
		tail = head;
		tail.count = 0;
		totalCount = 0;
	}

	/**
		Renders given buffer as a set of quads. Buffer data should be in groups of 4 vertices per quad.
		@param ctx The render context which performs the rendering. Rendering object should call `h2d.RenderContext.beginDrawBatchState` before calling `drawQuads`.
		@param buffer The quad buffer used to render the state.
		@param offset An optional starting offset of the buffer to render in triangles (2 per quad).
		@param length An optional maximum limit of triangles to render.

		When `offset` and `length` are not provided or are default values, slightly faster rendering routine is used.
	**/
	public function drawQuads( ctx : RenderContext, buffer : Buffer, offset = 0, length = -1 ) {
		var state = head;
		var last = tail.next;
		var engine = ctx.engine;
		var stateLen : Int;
		inline function toQuads( count : Int ) return count >> 1;
		var topShader = ctx.baseShaderList;
		while (topShader.next != null) topShader = topShader.next;
		if ( offset == 0 && length == -1 ) {
			// Skip extra logic when not restraining rendering
			do {
				if (state.shader != topShader.next) {
					topShader.next = state.shader;
					ctx.initShaders(ctx.baseShaderList);
				}
				ctx.swapTexture(state.texture);
				stateLen = toQuads(state.count);
				engine.renderQuadBuffer(buffer, offset, stateLen);
				offset += stateLen;
				state = state.next;
			} while ( state != last );
		} else {
			if ( length == -1 ) length = toQuads(totalCount) - offset;
			var caret = 0;
			do {
				stateLen = toQuads(state.count);
				if ( caret + stateLen >= offset ) {
					var stateMin = offset >= caret ? offset : caret;
					var stateLen = length > stateLen ? stateLen : length;
					if (state.shader != topShader.next) {
						topShader.next = state.shader;
						ctx.initShaders(ctx.baseShaderList);
					}
					ctx.swapTexture(state.texture);
					engine.renderQuadBuffer(buffer, stateMin, stateLen);
					length -= stateLen;
					if ( length == 0 ) break;
				}
				caret += stateLen;
				state = state.next;
			} while ( state != last );
		}
	}

	/**
		Renders given indices as a set of triangles. Index data should be in groups of 3 vertices per quad.
		@param ctx The render context which performs the rendering. Rendering object should call `h2d.RenderContext.beginDrawBatchState` before calling `drawQuads`.
		@param buffer The vertex buffer used to render the state.
		@param indices Vertex indices used to render the state.
		@param offset An optional starting offset of the buffer to render in triangles.
		@param length An optional maximum limit of triangles to render.

		When `offset` and `length` are not provided or are default values, slightly faster rendering routine is used.
	**/
	public function drawIndexed( ctx : RenderContext, buffer : Buffer, indices : Indexes, offset : Int = 0, length : Int = -1 ) {
		var state = head;
		var last = tail.next;
		var engine = ctx.engine;
		var stateLen : Int;
		inline function toTris( count : Int ) return Std.int(count / 3);
		var topShader = ctx.baseShaderList;
		while (topShader.next != null) topShader = topShader.next;

		if ( offset == 0 && length == -1 ) {
			// Skip extra logic when not restraining rendering
			do {
				if (state.shader != topShader.next) {
					topShader.next = state.shader;
					ctx.initShaders(ctx.baseShaderList);
				}
				ctx.swapTexture(state.texture);
				stateLen = toTris(state.count);
				engine.renderIndexed(buffer, indices, offset, stateLen);
				offset += stateLen;
				state = state.next;
			} while ( state != last );
		} else {
			if ( length == -1 ) length = toTris(totalCount);
			var caret = 0;
			do {
				stateLen = toTris(state.count);
				if ( caret + stateLen >= offset ) {
					var stateMin = offset >= caret ? offset : caret;
					var stateLen = length > stateLen ? stateLen : length;
					if (state.shader != topShader.next) {
						topShader.next = state.shader;
						ctx.initShaders(ctx.baseShaderList);
					}
					ctx.swapTexture(state.texture);
					engine.renderIndexed(buffer, indices, stateMin, stateLen);
					length -= stateLen;
					if ( length == 0 ) break;
				}
				caret += stateLen;
				state = state.next;
			} while ( state != last );
		}
	}


	inline function get_currentTexture() return tail.texture;
	inline function get_currentShader() return tail.shader;

}

private class StateEntry {

	/**
		Texture associated with draw state instance.
	**/
  public var texture:Texture;
	
	public var shader: ShaderList;
	/**
		A size of batch state.
	**/
	public var count : Int;
	

	public var next:StateEntry;

	public function new( texture : Texture, shader: ShaderList ) {
		// this.textures = [];
		// inline set(texture, extras, extrasCount);
		inline set(texture, shader);
	}

	public function set( texture : Texture, shader: ShaderList ) : StateEntry {
    this.texture = texture;
		// for (i in 0...extrasCount) textures[i] = extras[i];
		// this.textureCount = extrasCount;
		this.count = 0;
		this.shader = shader;
		return this;
	}
  
  // public function fill(shader:MultiTexture2) {
  //   // shader.TEXTURE_COUNT = textures.length;
  //   // shader.textures = textures;
	// 	var filter = texture.filter;
	// 	var wrap = texture.wrap;
	// 	for (i in 0...textureCount) {
	// 		var tex = textures[i];
	// 		tex.filter = filter;
	// 		tex.wrap = wrap;
	// 		shader.textures[i] = tex;
	// 	}
  // }

}