function [result] = UnitStep(x)
            % Matlab defines heaviside(0) to be 0.5, which is a perfectly sensible
            % perversion. It can be changed globally but I'd rather not screw around
            % with a user's settings
            result = (x >= 0);
end