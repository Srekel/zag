@echo off
cls

REM mkdir build

REM Taken from https://github.com/rivten/carbon/blob/master/code/build.bat
REM clang++ -c -g -gcodeview -Wno-deprecated-declarations -Wno-return-type-c-linkage external\cimgui\imgui\imgui.cpp -I external\cimgui -o build/imgui.obj
REM clang++ -c -g -gcodeview -Wno-deprecated-declarations -Wno-return-type-c-linkage external\cimgui\imgui\imgui_demo.cpp -I external\cimgui -o build/imgui_demo.obj
REM clang++ -c -g -gcodeview -Wno-deprecated-declarations -Wno-return-type-c-linkage external\cimgui\imgui\imgui_draw.cpp -I external\cimgui -o build/imgui_draw.obj
REM clang++ -c -g -gcodeview -Wno-deprecated-declarations -Wno-return-type-c-linkage external\cimgui\imgui\imgui_widgets.cpp -I external\cimgui -o build/imgui_widgets.obj
REM clang++ -c -g -gcodeview -Wno-deprecated-declarations -Wno-return-type-c-linkage external\cimgui\cimgui.cpp -I external\cimgui -o build/cimgui.obj

zig build --verbose