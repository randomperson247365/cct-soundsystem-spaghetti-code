local dfpwm = require("cc.audio.dfpwm")

-- Function to detect and list speakers
local function detectSpeakers()
  local peripherals = peripheral.getNames()
  local detectedSpeakers = {}

  for _, peripheralName in ipairs(peripherals) do
    if peripheral.getType(peripheralName) == "speaker" then
      local speaker = peripheral.wrap(peripheralName)
      table.insert(detectedSpeakers, speaker)
      print(peripheralName .. " detected as a speaker")
    end
  end

  return detectedSpeakers
end

-- Detect speakers and store them in a table
local speakers = detectSpeakers()

if not speakers or #speakers == 0 then
  print("No speakers detected.")
  return
end

-- Command-line argument for audio file path
local args = { ... }

local audioFilePath

if #args < 1 then
  local files = fs.list("disk/")
  local audioFiles = {}
  for _, file in ipairs(files) do
    if not fs.isDir("disk/" .. file) and file:match("%.dfpwm$") then
      table.insert(audioFiles, file)
    end
  end

  -- Sort the audio files by file size in ascending order
  table.sort(audioFiles, function(a, b)
    return fs.getSize("disk/" .. a) < fs.getSize("disk/" .. b)
  end)

  local selectedFileIndex = 1
  local topVisibleIndex = 1

  while true do
    term.clear()
    term.setCursorPos(1, 1)
    print("Select an audio file:")
    for i = topVisibleIndex, math.min(topVisibleIndex + 4, #audioFiles) do
      if i == selectedFileIndex then
        print("> " .. audioFiles[i])
      else
        print("  " .. audioFiles[i])
      end
    end
    print("Arrow keys (Up/Down) to navigate, Enter to select")

    local event, key = os.pullEvent("key")
    if key == keys.enter then
      audioFilePath = "disk/" .. audioFiles[selectedFileIndex]
      break
    elseif key == keys.up and selectedFileIndex > 1 then
      selectedFileIndex = selectedFileIndex - 1
      if selectedFileIndex < topVisibleIndex then
        topVisibleIndex = selectedFileIndex
      end
    elseif key == keys.down and selectedFileIndex < #audioFiles then
      selectedFileIndex = selectedFileIndex + 1
      if selectedFileIndex > topVisibleIndex + 4 then
        topVisibleIndex = selectedFileIndex - 4
      end
    end
  end
else
  audioFilePath = args[1]
end

-- Check if the audio file exists
if not fs.exists(audioFilePath) then
  print("File not found: " .. audioFilePath)
  return
end

-- Create a decoder
local decoder = dfpwm.make_decoder()

-- Read and decode the audio data from the file
local success = true
local decodedAudio = {}

-- Create a central control computer for synchronization
local centralComputer = peripheral.find("computer")

if centralComputer then
  centralComputer.turnOn()
end

print("Playing audio from file: " .. audioFilePath)

-- Clear audio on all speakers before playing
for _, speaker in ipairs(speakers) do
  speaker.stop()
end

for chunk in io.lines(audioFilePath, 16 * 1024) do
  local buffer = decoder(chunk)

  -- Synchronize playback on all detected speakers
  for _, speaker in ipairs(speakers) do
    while true do
      -- Central computer signals all speakers to play
      if centralComputer then
        centralComputer.transmit(speaker.getName(), 1, "play")
      end

      if not speaker.playAudio(buffer) then
        os.pullEvent("speaker_audio_empty")
        sleep(0.05)
      else
        break
      end
    end
  end
end

print("Audio playback complete.")
