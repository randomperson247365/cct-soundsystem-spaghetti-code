local songs = fs.list("disk/")
local playlistContent = {}

-- Create a table to store song information with filenames and their respective file sizes
local songInfo = {}

for _, song in ipairs(songs) do
  local songPath = "disk/" .. song
  if not fs.isDir(songPath) and song:match("%.dfpwm$") then
    local fileSize = fs.getSize(songPath)
    table.insert(songInfo, {name = song, size = fileSize})
  end
end

-- Sort the songs by file size in ascending order
table.sort(songInfo, function(a, b) return a.size < b.size end)

-- Generate the playlist content with sorted songs
for _, info in ipairs(songInfo) do
  playlistContent[#playlistContent + 1] = 'shell.run("SoundSystem.lua", "disk/' .. info.name .. '")'
  playlistContent[#playlistContent + 1] = 'sleep(5)'
end

-- Add a command to run "startup.lua" after all the songs
playlistContent[#playlistContent + 1] = 'shell.run("startup.lua")'

-- Write the playlist to a file
local playlistFile = fs.open("playlist.lua", "w")
playlistFile.write(table.concat(playlistContent, "\n"))
playlistFile.close()
print("Done creating playlist sorted from smallest to largest file")