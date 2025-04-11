-- lib/sun_mode_2.lua
local sun_mode_2 = {}

function sun_mode_2.init(self)
        self.active_photons = {1}
        self.wait_clock = nil
        self.velocity_deltas = {}
        self.pulsing = false
        self.pulse_phase = 0
        self.pulse_speed = 0.2
        self.previous_input_direction = 0
        self.reversed = false
        self.reversal_cooldown = false
        self.previewing = false
        self:update_state()

        -- define a deinit function to
        --   remove any variables or tables that might stick around
        --   after switching to a different sun mode
        --   for example: a lattice or reflection instance
        self.deinit = function()
            print("deinit sun mode: 2")
        end    

end

function sun_mode_2.enc(self, n, delta)
    if n==1 then return end
    local input_direction = sign(delta)

    if input_direction ~= self.previous_input_direction and self.previous_input_direction ~= 0 then
        if self.motion_clock then
            clock.cancel(self.motion_clock)
            self.motion_clock = nil
        end
        if self.wait_clock then
            clock.cancel(self.wait_clock)
            self.wait_clock = nil
        end

        self.velocity = 0
        self.direction = 0
        self.pulsing = false
        self.previewing = false
        self.velocity_deltas = {}
        self.reversed = true
        self.reversal_cooldown = true
        self.previous_input_direction = input_direction

        clock.run(function()
            clock.sleep(0.5)
            self.reversal_cooldown = false
        end)
        return
    end

    if self.reversal_cooldown then
        return
    end

    if self.reversed then
        self.reversed = false
        self.velocity_deltas = {}
    end

    self.previous_input_direction = input_direction
    sun_mode_2.set_velocity(self,delta)
end

function sun_mode_2.set_velocity(self,delta)
        local now = util.time()
        table.insert(self.velocity_deltas, {delta = delta, time = now})
    
        self.previewing = true
        self.pulsing = true
    
        if #self.velocity_deltas >= 2 then
            local total_delta = 0
            for _, e in ipairs(self.velocity_deltas) do
                total_delta = total_delta + e.delta
            end
            local duration = math.max(now - self.velocity_deltas[1].time, 0.01)
            local velocity = total_delta / duration
            self.pulse_speed = util.clamp(math.abs(velocity) * 0.01, 0.05, 2.0)
        end
    
        if self.wait_clock then clock.cancel(self.wait_clock) end
    
        self.wait_clock = clock.run(function()
            clock.sleep(0.5)
            if #self.velocity_deltas == 0 then
                self.previewing = false
                return
            end
    
            local total_delta = 0
            for _, e in ipairs(self.velocity_deltas) do
                total_delta = total_delta + e.delta
            end
            local duration = math.max(self.velocity_deltas[#self.velocity_deltas].time - self.velocity_deltas[1].time, 0.01)
            local new_velocity = total_delta / duration
            local new_direction = sign(new_velocity)
    
            self.velocity_deltas = {}
            self.wait_clock = nil
            self.previewing = false
    
            if math.abs(new_velocity) < 0.01 then
                self.velocity = 0
                self.direction = 0
                self.pulsing = false
                return
            end
    
            self.velocity = new_velocity
            self.direction = new_direction
            self.pulsing = false
            self.reversed = false
    
            if not self.motion_clock then
                self.motion_clock = clock.run(function()
                    while true do
                        clock.sleep(1 / math.abs(self.velocity))
                        self:set_active_photons_rel(self.direction)
                    end
                end)
            end
        end)
end

function sun_mode_2.redraw(self)
        local base_level = 10
        local pulse_amp = 5
    
        if self.pulsing or self.previewing then
            self.pulse_phase = (self.pulse_phase + self.pulse_speed) % (2 * math.pi)
            local pulse = math.sin(self.pulse_phase) * pulse_amp
            self.sun_level = util.clamp(base_level + pulse, 0, 15)
        elseif not self.pulsing then
            self.sun_level = self.sun_level + (base_level - self.sun_level) * 0.2
            if math.abs(self.sun_level - base_level) < 0.01 then
                self.sun_level = base_level
            end
        end    
end

return sun_mode_2
