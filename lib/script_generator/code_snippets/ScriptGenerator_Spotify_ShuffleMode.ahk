#NoEnv
#NoTrayIcon
#SingleInstance Force
SetWorkingDir, %A_WorkingDir%
#Include %A_WorkingDir%\plugins\spotify\Spotify.ahk
spoofy := new Spotify
ShuffleMode := PlaybackInfo.shuffle_state
ShuffleMode := !ShuffleMode
spoofy.Player.SetShuffle(ShuffleMode)
ExitApp