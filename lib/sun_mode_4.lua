-- lib/sun_mode_4.lua
local sun_mode_4 = {}

function sun_mode_4.init(self)
    ------------------------------------------------------
    --
    
    
    -- add code here to do create state variables 
    -- required for sun mode 4
    
    
    ------------------------------------------------------
    
    
    -- define a deinit function to
    --   remove any variables or tables that might stick around
    --   after switching to a different sun mode
    --   for example: a lattice or reflection instance
    self.deinit = function()
        print("deinit sun mode: 4")
        self.deinit = nil
    end    
end

function sun_mode_4.enc(self, n, delta)
  -- sun_mode_3ode 3 may use a separate reflection or animation library,
  -- so we do not handle encoder input here.
  return
end

function sun_mode_4.redraw(self)
    -- add code here to do something only when sun mode == 4
end


return sun_mode_4
