# HighSpace 

## (or High Fleet in Spaaace) 

### (name subject to change)

This project aims to create a total conversion mod for Freespace 2, which will be a mashup between it and High Fleet.

The code is based off the [SCPUI Test Mod](https://fsnebula.org/mod/SCPUI) (see also the `SCPUI/0.6.0` (works), and `SCPUI/0.9.0` (seems broken) branches)

## Installation

```
cd <FS2 Installation Directory>/FS2
git clone https://github.com/HighSpaceGame/highhpace.git highhpace-0.0.1
```

Hopefully the mod will be detected and can run through Knossos. If not:

```
cd <FS2 Installation Directory>/FS2
../bin/<FS2 executable> -mod highhpace-0.0.1/core
```

Or to run together with MVPS:

```
cd <FS2 Installation Directory>/FS2
../bin/<FS2 executable> -mod highspace-0.0.1/core,highspace-0.0.1/mvps_compat,MVPS-4.6.8
```

should do the trick