-- lib/sun_mode_1.lua
local sun_mode_1 = {}

function sun_mode_1.init(self)
        -- add code here to do create state variables 
        -- required for sun mode 1        
        self.active_photons = {1}
        print("sun mode init")
        self:update_state()

        -- define a deinit function to
        --   remove any variables or tables that might stick around
        --   after switching to a different sun mode
        --   for example: a lattice or reflection instance
        self.deinit = function()
            print("deinit sun mode: 1")
        end    

end

function sun_mode_1.enc(self, n, delta)
    if n==1 then return end
    self:set_active_photons_rel(delta)
end

function sun_mode_1.redraw(self)
        -- add code here to do something only when sun mode == 1
end

return sun_mode_1
