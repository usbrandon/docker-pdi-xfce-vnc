# docker-pdi-xfce-vnc
Run Pentaho Data Integration in a container using VNC

Running:
docker run -d -p 5901:5901 -p 6901:6901 --name spoon usbrandon/docker-pdi-xfce-vnc

Building:
docker build --tag usbrandon/docker-pdi-xfce-vnc .

Todo:
There are still some issues with the build approach as it relates to size. The last step fixes file permissions, which adds another layer of equal size to the files being updated (1gb in this case). Fortunately, using docker-squash
can eliminate the effects of this before going to the registry.  There must be a better way.

Example:
docker-squash -t usbrandon/docker-pdi-xfce-vnc:7.1.0.4 usbrandon/docker-pdi-xfce-vnc:latest