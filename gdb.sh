#!/bin/bash

gnome-terminal -t "Bochs" -- bochs -q
gnome-terminal -t "GDB" -- gdb kernel