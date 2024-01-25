; Copyright (C) 2023 mesvam
; 
; This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

; This script prevents multiple keypresses from being registered when a buggy key rapidly bounces up and down after a keydown or keyup
; When key is released, it can not be activated again within `releasetime` of the initial key release
; When key is pressed, it can not be released within `holdtime` of the initial press

; How this script works:
; Records time of last key up sent to the OS. If keydown within `releasetime` is detected from hardware, then it is silenced

#Requires AutoHotkey v2.0

class Debounce {
	__New(key, releasetime := 33.3, holdtime := 33.3) {
		this.key := key
		this.keydown_action := "{" key " down}"
		this.keyup_action := "{" key " up}"
		this.releasetime := releasetime  ; minimum key released time
		this.holdtime := holdtime  ; minimum key hold time
		this.timeup := -1  ; time of last key up was sent
		this.timedown := -1  ; time of last key down was sent
		
		; requires Bind(), otherwise this = Hotkeyname in the function
		Hotkey(this.key      , this.down.Bind(this))
		Hotkey(this.key " Up", this.up.Bind(this))
	}
	
	down(*) {
		if((time() - this.timeup) > this.releasetime || this.timeup = -1) {
			; cooldown has elapsed
			if(!GetKeyState(this.key))  ; key released, reset timer
				this.timedown := time()
			SendInput this.keydown_action
		}
	}
	
	up(*) {
		if((time() - this.timedown) > this.holdtime || this.timedown = -1) {
			; cooldown has elapsed
			if(GetKeyState(this.key))  ; key held, reset timer
				this.timeup := time()
			SendInput this.keyup_action
		}
	}
}

; calculate time interval using Windows high resolution timestamps
DllCall("QueryPerformanceFrequency", "Int64*", &frequency := 0) ; get timer frequency. usually microsecond resolution
time() {
	; returns time in miliseconds
	; A_TickCount only gives 10ms resolution up to ~50 days, so we use QueryPerformanceCounter instead https://www.autohotkey.com/docs/v2/lib/DllCall.htm#ExQPC
	; QueryPerformanceCounter should not overflow for 100 years, so we don't need to worry about that
	; https://stackoverflow.com/a/70987823/823633
	;  https://learn.microsoft.com/en-us/windows/win32/sysinfo/acquiring-high-resolution-time-stamps#general-faq-about-qpc-and-tsc
	DllCall("QueryPerformanceCounter", "Int64*", &counter := 0)
	return counter / frequency * 1000
}


; ==============================
; ADD KEYS TO DEBOUCE BELOW HERE
; Example: debounce the g key using default interval of 33.3 ms
; Debounce("g")

; Example: debounce Space key using a minimum key release time of 50 ms, and minimum key hold time of 10 ms
; db := Debounce("Space", 50, 10)

; WARNING: debouncing the key press for modifier keys (Ctrl, Alt, etc.) may be confusing or even dangerous if a key gets unexpectedly stuck down. Recommend setting the holdtime to 0 to disable debounce for the key press so a key release is never blocked
; Debounce("LCtrl", 33.3, 0)

