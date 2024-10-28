#!/bin/bash

echo "Starting Sons of the Forest Dedicated Server..."
xvfb-run -a wine64 SonsOfTheForestDS.exe -userdatapath 'Z:/server-data'
