# RMPBUploadr
Swift version of the RMPB Uploadr tools

This tool takes a photobooth event image folder, an event album password, an event album badge image (for the website), uploads the images to Flickr and creates an entry in the business website admininstrative database so that the album shows up on the business [website](http://www.rmpb.pics).

The event image folder contains a subfolder called `prints/` which contains the printed photostrips, a 4x6 image with duplicate 2x6 images side-by-side on it.

See the example:![example 4x6 image](https://github.com/williatf/rmpb-uploader/raw/master/testEventFolder/TestEventImagesFolder/prints/20170325_100553.jpg)

The event image folder also contains XML files that detail which images in the folder belong to which photostrip in the `prints/` folder.

Example XML:
```
<?xml version="1.0" ?>
<breeze_systems_photobooth version="1.1">
<photo_information>
<date>2017/03/23</date>
<time>18:10:32</time>
<user_data></user_data>
<prints>2</prints>
<photobooth_images_folder>C:\Users\RMPB\Google Drive\RMPB\Events\!Confirmed\E20170318</photobooth_images_folder>
<caption1></caption1>
<caption2></caption2>
<photos>
<photo image="1">RMPB_0001.jpg</photo>
<photo image="2">RMPB_0002.jpg</photo>
<photo image="3">RMPB_0003.jpg</photo>
<photo image="4">RMPB_0004.jpg</photo>
<output>prints\20170323_181032.jpg</output>
</photos>
</photo_information>
</breeze_systems_photobooth>
```

The tool will crop the 4x6 to a single 2x6 photo strip, based on parameters it gets from the user. These parameters are captured by the tool when the user opens the "Set Crop Parameters" window and adjusts the crop bars.

The cropped images are put into a new `_strips/` folder.

For photobooth events that use the greenscreen settings, a `greenscreen/` folder will exist that has the rendered individual images.  If this folder exists and contains at least 5 images, the tool will use it as the source for the individual images, and not the main event image folder, where all of the images are the raw camera images before greenscreen processing.

Written by: Todd Williams
Date: 6/8/2017
