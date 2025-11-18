; This is a custom class that, unlike my original OBSBOTController, does not make use of OSC2AHK.dll due to LibreDeck defaulting to AHK32, here we use an exe so that it's language agnostic.
class OBSBOTController {
    __New(ip, port) {
        this.ip := ip
        this.port := port
    }

    ; Send Recording Start Command
    StartRecording() {
        addr := "/OBSBOT/WebCam/General/SetPCRecording"
        Run, % "./lib/osc-utility_0.3.0_windows_amd64.exe message --host " this.ip " --port " this.port " --address " addr " --int 1",, Hide
    }

    ; Send Recording Stop Command
    StopRecording() {
        addr := "/OBSBOT/WebCam/General/SetPCRecording"
        Run, % "./lib/osc-utility_0.3.0_windows_amd64.exe message --host " this.ip " --port " this.port " --address " addr " --int 0",, Hide
    }

    ; Take Camera Photo
    TakePhoto() {
        addr := "/OBSBOT/WebCam/General/PCSnapshot"
        Run, % "./lib/osc-utility_0.3.0_windows_amd64.exe message --host " this.ip " --port " this.port " --address " addr " --int 1",, Hide
    }

    ; Wake Camera
    Wake() {
        addr := "/OBSBOT/WebCam/General/WakeSleep"
        Run, % "./lib/osc-utility_0.3.0_windows_amd64.exe message --host " this.ip " --port " this.port " --address " addr " --int 1",, Hide
    }

    ; Sleep Camera
    Sleep() {
        addr := "/OBSBOT/WebCam/General/WakeSleep"
        Run, % "./lib/osc-utility_0.3.0_windows_amd64.exe message --host " this.ip " --port " this.port " --address " addr " --int 0",, Hide
    }

    ; Reset Camera Gimbal
    ResetGimbal() {
        addr := "/OBSBOT/WebCam/General/ResetGimbal"
        Run, % "./lib/osc-utility_0.3.0_windows_amd64.exe message --host " this.ip " --port " this.port " --address " addr " --int 0",, Hide
    }

    ; Set Zoom
    SetZoom(value) {
        addr := "/OBSBOT/WebCam/General/SetZoom"
        Run, % "./lib/osc-utility_0.3.0_windows_amd64.exe message --host " this.ip " --port " this.port " --address " addr " --int " value,, Hide
    }

; TODO FROM HERE
    ; Set Field of View
    SetFOV(value) {
        addr := "/OBSBOT/WebCam/General/SetView"
        Run, % "./lib/osc-utility_0.3.0_windows_amd64.exe message --host " this.ip " --port " this.port " --address " addr " --int " value,, Hide
    }

    ; Set Mirror Mode
    SetMirror(value) {
        addr := "/OBSBOT/WebCam/General/SetMirror"
        Run, % "./lib/osc-utility_0.3.0_windows_amd64.exe message --host " this.ip " --port " this.port " --address " addr " --int " value,, Hide
    }

    ; Set Tracking Mode
    SetTrackingMode(value) {
        addr := "/OBSBOT/WebCam/Tiny/SetTrackingMode"
        Run, % "./lib/osc-utility_0.3.0_windows_amd64.exe message --host " this.ip " --port " this.port " --address " addr " --int " value,, Hide
    }

    ; Set AI Lock
    SetAILock(value) {
        addr := "/OBSBOT/WebCam/Tiny/ToggleAILock"
        Run, % "./lib/osc-utility_0.3.0_windows_amd64.exe message --host " this.ip " --port " this.port " --address " addr " --int " value,, Hide
    }

    ; Set AI Mode
    SetAIMode(value) {
        addr := "/OBSBOT/WebCam/Tiny/SetAiMode"
        Run, % "./lib/osc-utility_0.3.0_windows_amd64.exe message --host " this.ip " --port " this.port " --address " addr " --int " value,, Hide
    }

    ; Set Gimbal (Float inputs)
    SetGimbal(speed, pan, pitch) {
        Run, % "./lib/osc-utility_0.3.0_windows_amd64.exe message --host " this.ip " --address /OBSBOT/WebCam/General/SetGimMotorDegree --port " this.port " --float " speed "," pan "," pitch,, Hide
    }
}
