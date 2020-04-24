# Heeps
An "advanced" Heaps extension library.

## Announcement
Library is in a state of migration due to multiple reasons. Changes are as follows:
* Structure will change from using same packages as Heaps to following: `ch2`, `ch3` and `cherry`, for `h2d`, `h3d`, and `hxd` respectively.
* Migration will be done over time and backward compatibility will be done via typedefs. Readme would be over time as well.
* Library itself going to be renamed as to produce less confusion, so keep that in mind.

## Ideology
* I looked at Heaps and found the lack of features and general spartan feature-list rather meh.
* I'd push some of that to main library, but I doubt they'll be accepted - too advanced.
* I do not blame or have a grudge against Heaps developers, it's their engine which they develop for their needs that arise internally. And they want it to be as simple and dumb as possible, avoiding anything too advanced. It's their right and their vision. And I do the same anyway.
* My vision is to have a **good and hopefully robust engine** that you can use and have many basic features out of the box. This is the purpose of this library. 
* Everyone free to PR features they want, I'm not picky.
* I also take feature requests, but don't expect me to jump right onto it. ;)
* **Flash is in the past**. I do not plan to support flash target. If it works - it's a miracle.
* Code style is all over the place, I'll fix it eventually.

## Structure
* `h2d`, `h3d` and `hxd` packages used in the same way as Heaps do - 2D, 3D and general stuff.
* `cherry.soup` package user for internal features, like macro functions and utility classes.
* `cherry.tools` designated for `using cherry.tools.NTools;` that would extend standard functionality of existing Heaps objects.
* `plugins` folder is for HIDE plugins.

## Features

For a list of additional classes see `docs`. Listing every single class here is just not feasible at this point.  
Below are specific remarks for some of the features or objects that I still have to document properly.

* `h2d.Tilemap` - Basic Tilemap renderer. NOT PERFECT. It does not care about render-order and shit. I'll fix and improve it eventually, but not now.
* `h3d.scene.S2DPlane` - A 2D plane that renders s2d objects on it. Uses texture rendering. For more primitive approach see `h3d.scene.TileSprite`.
* `cherry.res.GifImage` - Animated gif support with Res. Use `toAnimation` and `toFrames` to get animation data. `toImage` can be used to obtain spritesheet Image.
* `cherry.res.TiledMapFile` - when `format-tiled` library used, replaces `hxd.res.TiledMap` and provides better support for it.
* `ManifestFileSystem` - js-oriented alternative to stupid embedding into .js file. More tricky to operate, and requires preloading. See below.

### Type Patching
Library also uses ~~black magic~~ macros to patch some base classes.  
Can be disabled by `-D heeps_disable_patch_<path>`. E.g. `-D heaps_disable_patch_h2d_object` for `h2d.Object` patch. Note that some patches may rely on others. Alternatively `-D heeps_disable_patch` will disable all type patching.
* `h2d.Object` - Added `originX` and `originY` that control origin offset for transofmrations. `transform` and `absoluteTransform` for overriding transform matrix with custom one.
* `h2d.Layers` - Added `moveChild`, `addAt` and `getChildLayerIndex` for more control over children positioning.

### Tiled support

Library provides rudimentary Tiled map editor integration. It's integration far from complete, and may be improved.  
Tiled .tmx maps can be accessed via `hxd.Res` and parsed with `toMap()` function. Heeps will try to resolve all dependencies automatically, however it can be done manually afterwards.  
Returned object will contain parsed `format.tmx.TiledMap` and a list of loaded tilesets that can be used to get `h2d.Tile` instances with ease.

In future `h2d.tiled` will contain helper classes that would provide ability to visualise Tiled maps.
Currently there is only a draft version of layer renderer for Tiled utilizing `h2d.SpriteBatchExt`. But it is limited to 8 unique textures per layer as well as not supports render-order (uses default right-bottom) and orientation other than orthogonal.

### Manifest FS
Since we are sane people and don't want 50+MB js file that contains Base64-encoded game assets, we obviously want to load those files separately. Manifest-FS provides ability to load those files from a manifest file.  
This approach requires some prep-work to get it running, but beats embedding everything in JS.  
First, you have to generate manifest file with `cherry.fs.ManifestBuilder.create`, `generate` and `initManifest`. Last acts exactly the same as `Res.init*` functions and bakes manifest into the code. First just generates manifest FS in macro call and second one just does convert and optionally saves manifest to your res folder. I trust people here are smart enough to figure out how to utilize those two, so I'll focus on one I use, e.g. `initManifest` method.
> I should note that all docs about resource management make you believe that you have to initialize them in `main`. THIS. IS. WRONG. Instead, you need to initialize them by overriding `hxd.App.loadAssets` and call `onLoaded` after everything's loaded. We're good? Good. There's one downside to this, hovewer. During `loadAssets` - heaps is not running main loop, hence you can't render anything, and if you want to do preloaders, do it in `init()`

`initManifest` does not create typical `Loader` instance. Instead, it creates `cherry.res.ManifestLoader`, which you then should populate with progress handlers and call `loadManifestFiles`. Here's an example code of how you do this:
```haxe
override private function init() {
  var loader = cherry.fs.ManifestBuilder.initManifest();
  loader.onLoaded = () -> { trace("All loaded!"); startGame(); }
  loader.onFileLoadStarted = (f) -> trace("Started loading file: " + f.path);
  loader.onFileLoaded = (f) -> trace("Finished loading file: " + f.path);
  // This only happens when you use JS target, since sys target is synchronous.
  loader.onFileProgress = (f, loaded, total) -> trace("Loading file progress: " + f.path + ", " + loaded + "/" + total);
  loader.loadManifestFiles();
}

function startGame() {
  // Actual boot, now that all resources are loaded.
}
```
Additionally, if you want to visualize loading progress, but don't want anything fancy - there is `h2d.ui.ManifestProgress` with primitive progress-bar if you don't need any fancy mumbo-jumbo and just want your resources loaded while showing player that it actually loads.

## Extra flags
* `-D gif_disable_margin` - Disables 1px top/bottom margin that avoids pixel bleeding for gif spritesheet generation.