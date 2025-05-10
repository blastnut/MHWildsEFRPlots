function [OutgoingRaw] = EVdPos(v)
OutgoingRaw = v(1) + v(1).*(v(2)/100).*(v(3)/100);
end

