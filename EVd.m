function [OutgoingRaw] = EVd(v)
% Expected Value of Outgoing Raw Damage, before multiplication by MV, HZ,
% and Sharpness

% v(1) = True Raw Attack of weapon, including bonus
% v(2) = Affinity %, including bonus
% v(3) = Critical Damage Bonus, including base +25%

%OutgoingRaw = v(1) + (v(1).*v(2).*v(3))/10000;
%OutgoingRaw = v(1)*(1+(25*v(2)+v(2)*v(3))/10000);

if v(2) >= 0
    OutgoingRaw = v(1) + v(1)*(v(2)/100)*(v(3)/100);
else
    OutgoingRaw = v(1) + v(1)*(v(2)/100)*(25/100);
end

end

