#NoEnv
#NoTrayIcon
#SingleInstance Force
SetWorkingDir, %A_WorkingDir%
#Include %A_WorkingDir%\plugins\spotify\Spotify.ahk
spoofy := new Spotify
RepeatMode := (PlaybackInfo.repeat_state = "context" ? 2 : PlaybackInfo.repeat_state = "track" ? 1 : 3)
RepeatMode := RepeatMode + (RepeatMode = 0 ? 1 : (RepeatMode = 1 ? 1 : (RepeatMode = 2 ? 1 : -2)))
spoofy.Player.SetRepeatMode(RepeatMode)
ExitApp