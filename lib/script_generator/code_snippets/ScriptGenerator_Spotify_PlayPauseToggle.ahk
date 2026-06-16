#NoEnv
#NoTrayIcon
#SingleInstance Force
SetWorkingDir, %A_WorkingDir%
#Include %A_WorkingDir%\plugins\spotify\Spotify.ahk
spoofy := new Spotify
spoofy.Player.PlayPause()
ExitApp