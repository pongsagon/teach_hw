![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

## What is it
- examples of Verilog projects and students' works on my 2026 Graphics Hardware course

## Examples code
- can be played on vga-playground.com: https://vga-playground.com/?repo=https://github.com/pongsagon/teach_hw
- vga-playground will read verilog file to load from info.yaml.
- This repo contain many example projects, try each example by commentting out a group of .v file of the other examples in info.yaml file
1. Display image
2. Text mode display
3. Picture Processing Unit (PPU)


## 1st Gen game consoles
- link to students' works, can be played on vga-playground.com

## 3rd-4th Gen game consoles
- link to students' works, can be played on vga-playground.com

## VGA Playground issue
1. When using $readmemh:
   - cannot change the filename on the web after the first load.
   - data that loaded from $readmemh must be used, if not used it will cause error: Invalid typed array length
