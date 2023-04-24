--- === FirefoxProfiles ===
---
--- A menubar applet to open Firefox profiles
---

local obj = {}
setmetatable(obj, obj)

-- Metadata
obj.name = "FirefoxProfiles"
obj.version = "0.0.1"
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

local function isProfileActive(profile)
    return not hs.settings.get("FirefoxProfiles/" .. profile)
end

local function toggleProfile(profile)
    hs.settings.set("FirefoxProfiles/" .. profile, isProfileActive(profile))
end

-- Private
function obj:_toggleProfile(profile)
    toggleProfile(profile)
    self:_refresh()
end

function obj:_onChoice(choice)
    if choice ~= nil then
        startProfile(choice.text)
    end
end

function obj:_startChooser()
    self.chooser:query(nil)
    self.chooser:show()
end

function obj:_buildMenuTable()
    local menuTable = {}

    for _, profile in ipairs(self.profiles) do
        local active = isProfileActive(profile)
        local state = active and "on" or "mixed"
        table.insert(menuTable, { 
            title = profile, 
            state = state, 
            profile = profile,
            menu = {
                {
                    title = "Start",
                    disabled = not active,
                    fn = hs.fnutils.partial(startProfile, profile),
                },
                {
                    title = active and "Disable" or "Enable",
                    fn = hs.fnutils.partial(self._toggleProfile, self, profile)
                }
            }
        })
    end

    table.insert(menuTable, { title = "-" })
    table.insert(menuTable, { 
        title = "Chooser", 
        fn = hs.fnutils.partial(self._startChooser, self) 
    })

    return menuTable
end

function obj:_refreshMenu()
    self.menubar:setMenu(self:_buildMenuTable())
end

function obj:_buildChoices()
    local choices = {}

    for _, profile in ipairs(self.profiles) do
        if isProfileActive(profile) then
            table.insert(choices, { text = profile })
        end
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
    self:_refreshMenu()
    self:_refreshChoices()
end

-- Public
function obj:init()
    self.profiles = buildProfiles(self.profilesDirectory)

    self.menubar = hs.menubar.new()

    local icon = hs.image.imageFromAppBundle("org.mozilla.firefox"):size({ w = 20, h = 20 })
    self.menubar:setIcon(icon, false)

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
