// Copyright (c) 2025 Josua Kucher All rights reserved.

//Compiletime Flags
const config = @import("config");

//std
const std = @import("std");

const fileTypes = @import("types.zig");
const perf = @import("perftimer.zig");
const fileUtils = @import("fileUtils.zig");
const replacement = @import("helpers.zig");

const baseTemplate = "<!DOCTYPE html>\n<html>\n<head>\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n<style>\n\nbody {\n  background-color: rgb(52, 57, 57);\n  margin: 0px;\n  height: 100%;\n}\n.wrapper {\n  display: flex;\n  top: 50px;\n  align-items: center;\n  justify-content: center;\n}\n.container {\n  position: absolute;\n  top: 50px;\n  border: 5px solid #ffcb70;\n  border-radius: 2%;\n  overflow: hidden;\n}\n\n.sliderHandle{\n  position: absolute;\n  z-index:9;\n  cursor: ew-resize;\n  width: 25px;\n  height: 25px;\n  background-color: #ffcb70;\n  border-radius: 50%;\n  opacity: 0.7;\n}\n\n.sliderLine {\n  position: absolute;\n  z-index:8;\n  cursor: ew-resize;\n  width: 3px;\n  background-color: #ffcb70;\n  opacity: 0.7;\n}\n\n.img {\n  position: absolute;\n  width: auto;\n  height: auto;\n  overflow:hidden;\n}\n\n.img .img-overlay{}\n\n.img img {\n  display:block;\n  vertical-align:middle;\n}\n\n</style>\n<script>\n\nvar x = 0, i =0;\nvar clicked = 0, w = 0, h = 0;\nvar sliderHandle, sliderLine, overlayImage, container;\n\n//{decodeFuncMarker}\n\nfunction ToCssDimensionPx(x) { return x + \"px\"; }\n\nfunction SetupSlider(w,h)\n{\n  \n  halfWidth = w/2;\n  halfHeight = h/2;\n  \n  /*create slider:*/\n  sliderHandle = document.getElementsByClassName(\"sliderHandle\")[0];\n  sliderLine = document.getElementsByClassName(\"sliderLine\")[0];\n\n  sliderLine.style.height =ToCssDimensionPx(h); \n\n  /*position the slider in the middle:*/\n  sliderHandle.style.top = ToCssDimensionPx(halfHeight - (sliderHandle.offsetHeight / 2));\n  sliderHandle.style.left = ToCssDimensionPx(halfWidth - (sliderHandle.offsetWidth / 2));\n\n  sliderLine.style.top = ToCssDimensionPx(halfHeight - (sliderLine.offsetHeight / 2));\n  sliderLine.style.left = ToCssDimensionPx(halfWidth - (sliderLine.offsetWidth / 2));\n\n  sliderHandle.addEventListener(\"mousedown\", slideReady);\n  sliderLine.addEventListener(\"mousedown\", slideReady);\n  sliderHandle.addEventListener(\"touchstart\", slideReady);\n  sliderLine.addEventListener(\"touchstart\", slideReady);\n}\n\nfunction SetupContainer(w, h)\n{\n  container = document.getElementsByClassName(\"container\")[0];\n  container.style.width = ToCssDimensionPx(w);\n  container.style.height = ToCssDimensionPx(h);\n}\n  \nfunction slideReady(e) {\n    /*prevent any other actions that may occur when moving over the image:*/\n    e.preventDefault();\n    /*the slider is now clicked and ready to move:*/\n    clicked = 1;\n    /*execute a function when the slider is moved:*/\n    window.addEventListener(\"mousemove\", slideMove);\n    window.addEventListener(\"touchmove\", slideMove);\n  }\n\n  function slideFinish() {\n    /*the slider is no longer clicked:*/\n    clicked = 0;\n  }\n\n  function slideMove(e) {\n    var pos;\n    /*if the slider is no longer clicked, exit this function:*/\n    if (clicked == 0) return false;\n    /*get the cursor's x position:*/\n    pos = getCursorPos(e)\n    /*prevent the slider from being positioned outside the image:*/\n    if (pos < 0) pos = 0;\n    if (pos > w) pos = w;\n    /*execute a function that will resize the overlay image according to the cursor:*/\n    slide(pos);\n  }\n\n  function getCursorPos(e) {\n    var a, x = 0;\n    e = (e.changedTouches) ? e.changedTouches[0] : e;\n    /*get the x positions of the image:*/\n    a = overlayImage.getBoundingClientRect();\n    /*calculate the cursor's x coordinate, relative to the image:*/\n    x = e.pageX - a.left;\n    /*consider any page scrolling:*/\n    x = x - window.pageXOffset;\n    return x;\n  }\n\n  function slide(x) {\n    overlayImage.style.width = ToCssDimensionPx(x);\n    sliderHandle.style.left = ToCssDimensionPx(overlayImage.offsetWidth - (sliderHandle.offsetWidth / 2));\n    sliderLine.style.left = ToCssDimensionPx(overlayImage.offsetWidth - (sliderLine.offsetWidth / 2));\n  }\n\n\nfunction Compare() {\n\n  var images = document.getElementsByClassName(\"img\");\n  for (i = 0; i < images.length; i++) {\n    w = Math.max(w,images[i].clientWidth);\n    h = Math.max(h,images[i].clientHeight);\n  };\n\n  overlayImage = document.getElementsByClassName(\"img-overlay\")[0];\n  overlayImage.style.width = ToCssDimensionPx(overlayImage.clientWidth);\n  \n  SetupContainer(w,h);\n  SetupSlider(w,h);\n\n  /*Window functions*/\n  window.addEventListener(\"mouseup\", slideFinish);\n  window.addEventListener(\"touchend\", slideFinish);\n\n  slide(w/2);\n}\n\n  window.onload = function() {\n    Compare();\n};\n</script>\n\n</script>\n</head>\n<body>\n<div class=\"wrapper\">\n  <div class=\"container\">\n    <div class=\"img\">\n      <img src=\"data:image/png;base64, <{img-left}>\">\n    </div>\n    <div class=\"sliderLine\"></div>\n    <div class=\"sliderHandle\"></div>\n    <div class=\"img img-overlay\">\n      <img src=\"data:image/png;base64, <{img-right}>\">\n    </div>\n  </div>\n</div>\n</body>\n</html>\n";

const baseTemplatebaseOffset = replacement.gatherReplacementAccelerationData(
    u8,
    baseTemplate,
    leftImageMarker,
    "stub",
    0,
).replacementLocation;

const leftImageMarker = "<{img-left}>";
const rightImageMarker = "<{img-right}>";

pub fn CreateHTMLPage(allocator: std.mem.Allocator, outputfile: fileTypes.OutputFile, template: []const u8, encodedImage1: []const u8, encodedImage2: []const u8, startingOffset: usize) !void {
    var timer = if (comptime config.profiling) perf.StartTimer("CreateHTMLPage");
    defer if (comptime config.profiling) perf.StopTimer(&timer);

    const leftImgReplacementInfo = replacement.gatherReplacementAccelerationData(
        u8,
        template,
        leftImageMarker,
        encodedImage1,
        startingOffset,
    );

    const templateWithImg1 = try replacement.replaceOwned(
        u8,
        allocator,
        template,
        leftImageMarker.len,
        encodedImage1,
        leftImgReplacementInfo.replacementLocation,
        leftImgReplacementInfo.size,
    );

    const rightImgReplacementInfo = replacement.gatherReplacementAccelerationData(
        u8,
        templateWithImg1,
        rightImageMarker,
        encodedImage2,
        leftImgReplacementInfo.replacementLocation + encodedImage1.len,
    );
    const completedFile = try replacement.replaceOwned(
        u8,
        allocator,
        templateWithImg1,
        rightImageMarker.len,
        encodedImage2,
        rightImgReplacementInfo.replacementLocation,
        rightImgReplacementInfo.size,
    );

    if (fileUtils.TryCreateFileFromPath(outputfile.File).value) |file| {
        try file.writeAll(completedFile);
    } else {
        if (fileUtils.TryOpenFileFromPath(outputfile.File, .{}).value) |file| {
            try file.writeAll(completedFile);
        }
    }
}

pub fn CreateHTMLPageFromIncludedTemplate(allocator: std.mem.Allocator, outputFile: fileTypes.OutputFile, encodedImage1: []const u8, encodedImage2: []const u8) !void {
    var timer = if (comptime config.profiling) perf.StartTimer("CreateHTMLPageFromTemplate");
    defer if (comptime config.profiling) perf.StopTimer(&timer);
    try CreateHTMLPage(allocator, outputFile, baseTemplate, encodedImage1, encodedImage2, baseTemplatebaseOffset);
}

pub fn CreateHTMLPageFromTemplate(allocator: std.mem.Allocator, template: std.fs.File, outputFile: fileTypes.OutputFile, encodedImage1: []const u8, encodedImage2: []const u8) !void {
    var timer = if (comptime config.profiling) perf.StartTimer("CreateHTMLPageFromTemplate");
    defer if (comptime config.profiling) perf.StopTimer(&timer);

    const filesize = try template.getEndPos();
    const templateContent = try template.readToEndAlloc(allocator, filesize);
    try CreateHTMLPage(allocator, outputFile, templateContent, encodedImage1, encodedImage2, 0);
}

pub fn GenerateTemplateFile(outputFile: fileTypes.OutputFile) !void {
    var timer = if (comptime config.profiling) perf.StartTimer("CreateHTMLPageFromTemplate");
    defer if (comptime config.profiling) perf.StopTimer(&timer);

    if (fileUtils.TryCreateFileFromPath(outputFile.File).value) |file| {
        try file.writeAll(baseTemplate);
    } else {
        if (fileUtils.TryOpenFileFromPath(outputFile.File, .{}).value) |file| {
            try file.writeAll(baseTemplate);
        }
    }
}
