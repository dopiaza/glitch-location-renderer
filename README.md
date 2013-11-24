# Glitch Location Renderer #

This is a Ruby script to render the [Glitch](http://www.glitchthegame.com) location XML files into their individual layers, and also generate a full street view image.

You'll need a bunch of other stuff in order for this to work:

- ImageMagick
- Two Ruby gems: 'nokogiri' and 'RMagick'
- Glitch location XML files. You can find these in Tiny Speck's [glitch-locations](https://github.com/tinyspeck/glitch-locations) repo, in the locations-xml.zip file. I've also included a copy of these in this repo.
- Glitch location assets, as PNG files. Note: these are *not* included in this repo. You can get these either from Dan Catt's [CAT422-glitch-location-viewer/](https://github.com/revdancatt/CAT422-glitch-location-viewer/) or you can generate your own from the .fla files in the Tiny Speck [glitch-locations](https://github.com/tinyspeck/glitch-locations) repo

To render a set of streets, you'll need three directories. One containing the XML files for the streets you want to render, one containing all the PNG files for the various assets, and one for the generated PNGs to be written to. Invoke the renderer like this:

	process-locations.rb location-data location-assets output-png
	
It's a bit clunky, I might get around to adding better command line options at some point.

One file will be generated for each layer in the Glitch Street. The file name will be of the format *&lt;Street TSID&gt;-&lt;Layer id>.png*. Two additional files are also generated, *&lt;Street TSID&gt;-gradient.png* which contains the background gradient for the street, and &lt;Street TSID&gt;.png which contains a image of the fully rendered street.

Note that the various layers are not all the same size. The layers that are further away on the z-axis are smaller to allow for the parallax effect as you move through the street.

The sample-png directory shows example output for a couple of locations.

If you want to generate the location asset PNGs for yourself, I've included a modified version of Dan's JSFL script to export these from Adobe Flash. This modified version resizes the image first before exporting as PNG, resulting in a better quality image. He may well continue to improve on his version, so you may want to check what he's been doing before trying to run this. Rendering the PNGs takes a *long* time.

Many thanks to [Tiny Speck](http://tinyspeck.com) for making the Glitch location data and assets freely available. 