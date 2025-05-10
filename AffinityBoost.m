function [affboost] = AffinityBoost(lvl)
if heaviside(0) ~= 1
    sympref('HeavisideAtOrigin', 1);
end
nLvl = floor(lvl);
affboost = (nLvl * 4) * (heaviside(nLvl - 1) - heaviside(nLvl - 6)) ...
    + 20*heaviside(nLvl - 6);
end

