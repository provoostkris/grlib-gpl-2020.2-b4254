#------------------------------------------------------------------------------
#--  Makefile for LEON-3 <> Terrasic DE10 nano Cyclone 5 design
#--  rev. 1.0 : 2020 Provoost Kris
#------------------------------------------------------------------------------
#--  This program is free software: you can redistribute it and/or modify
#--  it under the terms of the GNU General Public License as published by
#--  the Free Software Foundation, either version 3 of the License, or
#--  (at your option) any later version.
#--  This program is distributed in the hope that it will be useful,
#--  but WITHOUT ANY WARRANTY; without even the implied warranty of
#--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#--  GNU General Public License for more details.
#--  You should have received a copy of the GNU General Public License
#--  along with this program.  If not, see <https://www.gnu.org/licenses/>. 
#------------------------------------------------------------------------------

GRLIB=../..

TOP=leon3mp
TECHNOLOGY=cyclone5
PART=5CSEBA6U23I7
PACKAGE=UFBGA
SPEED=-7
DEVICE=$(PART)-$(PACKAGE)$(SPEED)
BOARD=terasic-de10-nano
include $(GRLIB)/boards/$(BOARD)/Makefile.inc
QSF=$(GRLIB)/boards/$(BOARD)/$(TOP).qsf
SDCFILE=$(GRLIB)/boards/$(BOARD)/$(TOP).sdc
EFFORT=high

VHDLSYNFILES=config.vhd ahbrom.vhd leon3mp.vhd

VHDLSIMFILES=
SIMTOP=

CLEAN=soft-clean
TECHLIBS = altera altera_mf 

# Libraries, directories and files in GRLIB that should not be compiled for this design
LIBSKIP = core1553bbc core1553brm core1553brt gr1553 corePCIF \
          tmtc openchip ihp usbhc spw
DIRSKIP = b1553 pci/pcif leon2 leon2ft crypto satcan pci leon3ft ambatest can \
          usb grusbhc spacewire ascs slink hcan \
          leon4v0 l2cache pwm gr1553b iommu
FILESKIP = grcan.vhd

include $(GRLIB)/bin/Makefile 
include $(GRLIB)/software/leon3/Makefile

##################  project specific targets ##########################
