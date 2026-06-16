#NoEnv
#NoTrayIcon
#SingleInstance Force
SetWorkingDir, %A_WorkingDir%
#Include %A_WorkingDir%\plugins\spotify\Spotify.ahk
spoofy := new Spotify
PlaybackInfo := spoofy.Player.GetCurrentPlaybackInfo()
VolumePercentage := PlaybackInfo.Device.Volume
Increment := 10
if(VolumePercentage - Increment > 0)
  VolumePercentage := VolumePercentage - Increment
spoofy.Player.SetVolume(VolumePercentage)
ExitApp