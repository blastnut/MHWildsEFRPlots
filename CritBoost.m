function [critboost] = CritBoost(lvl)
if heaviside(0) ~= 1
    sympref('HeavisideAtOrigin', 1);
end
nLvl = floor(lvl);
critboost = ((nLvl) * 3) * (heaviside(nLvl - 1) - heaviside(nLvl - 6)) ...
    + 15*heaviside(nLvl - 6);
end


