# grlib-gpl-2020.2-b4254
 grlib-gpl-2020.2-b4254
 Original download and GRLIB from Gaisler research

# Introduction
The purpose is to add support for the LEON3 in relative inexpensive hardware.
The aim is to target setups that cost less then 100 € , and contain at least on CPU core
and some basic peripherals.
In addition an attempt is made to make use of common hardware. A normal laptop , running windows
and two USB ports, should be sufficient.


# Adding support for the Terrasic DE-10 kit
The DE10 nano specifications can be found on the website
https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=1046
A common usb<>serial board is added to support the debug interface.

Full tech support has been added for the cyclone 5 device. Design is based on the LEON3 minimal design.

Image - de10-nano setup :
![DE-10](de10-nano.jpg)

# Adding support for the Terrasic DE-0 kit
The DE0 nano specifications can be found on the website
https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=139&No=593
A common usb<>serial board is added to support the debug interface.

The existing design was updated to use the serial debug link, such that more recent versions of the quartus tool can be used.

Image - de0-nano setup :
![DE-0](de0-nano.jpg)