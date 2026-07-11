--[[
    recording_alert.lua
    Plays chimes and/or speech announcements when recording starts, stops,
    pauses, or resumes. While paused, replays the pause chime every 2
    seconds as a reminder until you resume or stop.

    macOS only — uses the built-in `afplay` and `say` command-line tools,
    no extra dependencies required.
]]

local obs = obslua

----------------------------------------------------------------------------
-- Configurable toggles for chimes and speech
----------------------------------------------------------------------------
local enable_chimes = true   -- change this to to false to disable the chimes
local enable_tts    = false   -- change this to true to enable spoken announcements

----------------------------------------------------------------------------
-- How often (ms) to repeat the pause chime while recording is paused
----------------------------------------------------------------------------
local pause_repeat_interval_ms = 2000

----------------------------------------------------------------------------
-- If you'd like to use your own audio files, just add their paths here.
-- afplay handles .wav/.aiff/.caf/.mp3.
----------------------------------------------------------------------------
local start_chime  = "/System/Library/Sounds/Glass.aiff"
local stop_chime   = "/System/Library/Sounds/Basso.aiff"
local pause_chime  = "/System/Library/Sounds/Pop.aiff"
local resume_chime = "/System/Library/Sounds/Blow.aiff"

----------------------------------------------------------------------------
-- Helper function to play a sound file with no popup
----------------------------------------------------------------------------
local function play_sound(path)
    os.execute(('afplay "%s" &'):format(path))
end

----------------------------------------------------------------------------
-- speak() via macOS's built-in `say` command
----------------------------------------------------------------------------
local function speak(text)
    if not enable_tts then return end
    local safe = text:gsub('"', '\\"')
    os.execute(('say "%s" &'):format(safe))
end

----------------------------------------------------------------------------
-- Repeating pause reminder
----------------------------------------------------------------------------
local function repeat_pause_alert()
    if enable_chimes then play_sound(pause_chime) end
end

local function stop_pause_repeat()
    obs.timer_remove(repeat_pause_alert)
end

----------------------------------------------------------------------------
-- OBS event callback
----------------------------------------------------------------------------
function on_event(event)
    if     event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTED then
        if enable_chimes then play_sound(start_chime) end
        speak("Recording started")

    elseif event == obs.OBS_FRONTEND_EVENT_RECORDING_STOPPED then
        stop_pause_repeat()
        if enable_chimes then play_sound(stop_chime) end
        speak("Recording stopped")

    elseif event == obs.OBS_FRONTEND_EVENT_RECORDING_PAUSED then
        if enable_chimes then play_sound(pause_chime) end
        speak("Recording paused")
        obs.timer_add(repeat_pause_alert, pause_repeat_interval_ms)

    elseif event == obs.OBS_FRONTEND_EVENT_RECORDING_UNPAUSED then
        stop_pause_repeat()
        if enable_chimes then play_sound(resume_chime) end
        speak("Recording resumed")
    end
end

----------------------------------------------------------------------------
-- Called by OBS when the script is loaded
----------------------------------------------------------------------------
function script_load(settings)
    obs.obs_frontend_add_event_callback(on_event)
end

----------------------------------------------------------------------------
-- Called by OBS when the script is unloaded
----------------------------------------------------------------------------
function script_unload()
    stop_pause_repeat()
end

function script_description()
    return [[
Plays chimes and/or spoken announcements on:
  • start
  • stop
  • pause (repeats every ]] .. (pause_repeat_interval_ms / 1000) .. [[ seconds while paused)
  • resume

Toggle chimes vs. speech via the booleans at the top of this script.]]
end
