# docker-pdi-xfce-vnc
Run Pentaho Data Integration in a container using VNC

Running:
docker run -d -p 5901:5901 -p 6901:6901 --name spoon usbrandon/docker-pdi-xfce-vnc

Building:
docker build --tag usbrandon/docker-pdi-xfce-vnc --file Dockerfile.ubuntu.xfce.vnc .