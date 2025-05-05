# <figure style="text-align: center;"><img src="Resources/splixel.png" alt="Splixel Logo."><figcaption style="text-align: center;">Splixel</figcaption></figure>

Splixel is a small CLI tool which allows creation of an image diff using base64 encoded images in and html page. The main use is convenient sharing of diffs using a single file, allowing for direct comparison.

## Installation

### Windows
Place the Splixel executable in a folder of your choice and add this folder to your path Variable.
```
setx path "%PATH%;C:\path\to\directory\"
```
Restart the commandline and use Splixel by entering the `splixel` command.

## Usage
Splixel supports 2 main modes folder mode and file mode.

### Folder Mode
Folder mode can be used for convenience in case the two images that should be diffed are in the same folder. Splixel will use the first 2 images in alphabetical order inside the provided folder.
```
splixel -idir Path\to\folder -o path\to\outputfile\file.html
```

### File Mode
In file mode one can specifie the paths to both files directly.
```
splixel -ifile Path\to\file1.png Path\to\file2.png -o path\to\outputfile\file.html
```

### Templates
By default Splixel will use its internal html template to generate the output file. This template can be written to a file using `-to`.
```
splixel -to path\to\templatefile.html
```
You can use this as a basis for your own templates, the only requirement for splixel to properly place the provided images into your template is the use of the `<img src="data:image/png;base64, <{img-left}>">` and `<img src="data:image/png;base64, <{img-right}>">` tags.

You can provide your own template in both file and folder mode.
```
splixel -ifile Path\to\file1.png Path\to\file2.png -o path\to\outputfile\file.html -t path\to\templatefile.html
splixel -idir Path\to\folder -o path\to\outputfile\file.html -t path\to\templatefile.html
```

### Arg list
* -h|-help|-?|?: prints arguments and help
* -idir [directory path]: input directory to fetch images from (cannot be used with -ifile)
* -ifile [filepath] [filepath]: images to use (cannot be used with -idir)
* -o [filepath]: output file to use (file will be created if it does not exist, missing directories will NOT be created)
* -t [filepath]: optional html template file to use, default will be used if none is provided
* -to [filepath]: generates a template file from the basetemplate, this can be used to start creating your own templates. Cannot be used with other arguments

### Example Results
![Example Page1](examples/Example.png)

## Build from Source
To build Splixle from source you need to first install zig: https://ziglang.org/learn/getting-started/

Afterwards navigate to the checked out root folder and call `zig build` this will build an x64-Windows executable by default. You can update build.zig to create builds for other targets.
