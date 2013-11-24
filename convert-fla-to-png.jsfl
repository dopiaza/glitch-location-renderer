// Based on Dan Catt's https://github.com/revdancatt/CAT422-glitch-location-viewer/blob/master/tools/convert-fla-to-png.jsfl
// Updated by David Wilkinson (@dopiaza):
// - scale fla before exporting as png
// - close file if exception thrown

//  Open a folder of fla files, and then output them in a parallel
//  folder called "output"
//
//  This is very rough and ready and needs babysitting for the files
//  that don't work.
//
//  Good luck!

var scale = 2.0
var folder = fl.browseForFolderURL("Choose a folder to publish:");
var files = FLfile.listFolder(folder + "/*.fla", "files");
for (file in files) {
        var curFile = files[file];

        // Keep track of which document is open so we can close it if exception
        var openDom = null;

        // open document, export, and close
        try {
            fl.openDocument(folder + "/" + curFile);
            var exportFileName = folder + '/../png/' + fl.getDocumentDOM().name.replace('.fla','.png');
            var originalDom = fl.getDocumentDOM();
            openDom = originalDom;
            originalDom.selectAll();
            originalDom.clipCopy();
            var w = originalDom.width;
            var h = originalDom.height;
            fl.closeDocument(originalDom);
            openDom = null;

            fl.createDocument();
            dom = fl.getDocumentDOM();
            openDom = dom;
            dom.width = w * scale;
            dom.height = h * scale;
            dom.clipPaste();
            dom.selectAll();
            dom.group();
            dom.scaleSelection(scale, scale);
            dom.align("vertical center", true);
            dom.align("horizontal center", true);
            dom.exportPNG(exportFileName, true, true);
            dom.close(false);
            openDom = null;
        } catch(er) {
            fl.trace(curFile);
            fl.trace(er);
            fl.trace('----------------');
            if (openDom != null) {
                openDom.close(false);
            }
        }
}
