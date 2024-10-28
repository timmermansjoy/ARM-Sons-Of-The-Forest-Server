wine wineboot && wine64 wineboot
xvfb-run sh -c "winetricks -q vcrun2019"
wine64 /steamcmd/steamcmd.exe +force_install_dir Z:/sonsoftheforest +login anonymous +app_update 2465200 validate +quit
exit 0
