--- === FirefoxProfiles ===
---
--- A menubar applet to open Firefox profiles
---

local obj = {}
setmetatable(obj, obj)

-- Metadata
obj.name = "FirefoxProfiles"
obj.version = "0.0.3"
obj.author = "Neta Elad <elad.neta@gmail.com>"
obj.homepage = "https://github.com/netaelad/FirefoxProfiles"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Local
obj.profilesDirectory = os.getenv("HOME") .. "/Library/Caches/Firefox/Profiles"

local function getProfileFromDirectory(directory)
    return directory:match("^.+%.(.+)$")
end

local function buildProfiles(directory)
    local profiles = {}
    for file in hs.fs.dir(directory) do
        if file ~= "." and file ~= ".." then
            local profile = getProfileFromDirectory(file)
            table.insert(profiles, profile)
        end
    end

    table.sort(profiles, function(a, b)
        return a < b
    end)

    return profiles
end

local function startProfile(profile)
    hs.task.new("/usr/bin/open", nil, {
        "-n", "/Applications/Firefox.app", "--args", "-P", profile
    }):start()
end

-- Private
function obj:_onChoice(choice)
    if choice ~= nil then
        startProfile(choice.text)
    end
end

function obj:_startChooser()
    self.chooser:query(nil)
    self.chooser:show()
end

function obj:_buildChoices()
    local choices = {}

    for _, profile in ipairs(self.profiles) do
        table.insert(choices, { text = profile })
    end

    return choices
end


function obj:_buildChooser()
    local chooser = hs.chooser.new(hs.fnutils.partial(self._onChoice, self))

    chooser:width(30)

    return chooser
end

function obj:_refreshChoices()
    local choices = self:_buildChoices()

    self.chooser:choices(choices)
    self.chooser:rows(math.min(10, #choices))
end

function obj:_refresh()
    self:_refreshChoices()
end

-- Public
function obj:init()
    self.profiles = buildProfiles(self.profilesDirectory)

    self.menubar = hs.menubar.new()

    local icon = hs.image.imageFromAppBundle("org.mozilla.firefox"):size({ w = 20, h = 20 })
    self.menubar:setIcon(icon, false)
    self.menubar:setTooltip("Firefox Profiles")
    self.menubar:setClickCallback(hs.fnutils.partial(self._startChooser, self))

    self.chooser = self:_buildChooser()

    self:_refresh()

    return self
end

function obj:bindHotKeys(mapping)
    local spec = {
        chooser = hs.fnutils.partial(self._startChooser, self)
    }

    hs.spoons.bindHotkeysToSpec(spec, mapping)

    return self
end

return obj
