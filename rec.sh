#!/bin/bash

## Run with any argument to enable sound recording /rec.sh s 


GST="gst-launch-1.0"
GSTIN="gst-inspect-1.0"
##FPS 
FPSIN="30/1"
#FPSOUT="25/1"
TIME=$(date +"%Y-%m-%d_%H%M%S")
FILEMANE="/disk/tmp/rec_$TIME.mkv"
MUX=" matroskamux name="muxer" "
FOUT=" ! progressreport  ! filesink location=$FILEMANE"
REC=""
#FORMAT I420 or NV12
FORMAT="I420"
##Software
ENCODER="! x264enc  speed-preset=faster qp-min=30 tune=zerolatency "
##OMX
OMX="! omxh264enc ! h264parse "
##VAAPI
VAAPI="! vaapiencode_h264 ! h264parse "

#SOUND SOURCE
##pactl list | grep -A2 'Source #' | grep 'Name: ' | cut -d" " -f2
##alsa_output.pci-0000_00_1b.0.analog-stereo.monitor
##alsa_input.usb-Sonix_Technology_Co.__Ltd._Trust_Webcam-02-Webcam.analog-mono
SINPUT="alsa_output.pci-0000_00_1b.0.analog-stereo.monitor"
##SOUND
if [ $# -gt 0 ]; then
SOUND=" pulsesrc device=$SINPUT ! queue ! voaacenc bitrate=128000 ! aacparse ! queue ! muxer."
echo "Sound ON"
else
SOUND=" "
echo "Sound Off"
fi

function ENC {
DI=`kdialog --menu "CHOOSE ENCODER:" 1 "Radeon OMX" 2 "Intel VAAPI" 3 "SOFTWARE";`

if [ "$?" = 0 ]; then
case "$DI" in 
	1)
	/usr/bin/omxregister-bellagio
	   if  [[ '$GSTIN | grep omxh264enc >/dev/null'  ]]
	      then ENCODER="$OMX"
	      FORMAT="NV12"
	      echo "Using omxh264enc encoder"
	      else echo "Gstreamer omxh264enc not found"
	   fi;;
       2)
	   if  [[ '$GSTIN | grep vaapiencode_h264 >/dev/null'  ]]
	     then ENCODER="$VAAPI "
	     echo "Using vaapiencode_h264 encoder"
	     else echo "Gstreamer vaapiencode_h264 not found"
	   fi;;
	3)
	     ENCODER="!  x264enc  speed-preset=faster qp-min=30 tune=zerolatency "
	     echo "Using software encoder";;
	*)
	     #ENCODER="! x264enc speed-preset=superfast"
	     echo "Using software encoder"
	     ;;
	     esac
fi
}



function DIAL {
VID=`kdialog --menu "CHOOSE RECORD MODE:" A "FULL SCREEN REC" B "WINDOW REC";`

if [ "$?" = 0 ]; then
	if [ "$VID" = A ]; then
		REC="$GST -e   ximagesrc  use-damage=0 ! queue ! video/x-raw,format=BGRx ! videoconvert ! video/x-raw,format=$FORMAT,framerate=$FPSIN  ! queue leaky=downstream   $ENCODER ! queue ! $MUX  $SOUND  muxer. $FOUT"
	elif [ "$VID" = B ]; then
	        XID=`xwininfo |grep 'Window id' | awk '{print $4;}'`
		REC="$GST -e    ximagesrc  xid=$XID  use-damage=0 ! queue ! video/x-raw,format=BGRx ! videoconvert ! video/x-raw,format=$FORMAT,framerate=$FPSIN  ! queue leaky=downstream   $ENCODER ! queue ! $MUX  $SOUND  muxer. $FOUT"
	else
		echo "ERROR";
	fi;
fi;
}

ENC
DIAL
echo $REC
exec $REC