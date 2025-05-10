function [] = PlotWeaponGemEFR(baseattack, baseaffinity, weapon_slots_in)
warning('off', 'MATLAB:dispatcher:nameConflict');
rmpath(genpath('path/to/other/functions'));
% Argument examples:
% baseattack = 200;
% baseaffinity = 15;
% weapon_slots = [1;1;1]; % 1 level 1, 1 level 2, 1 level 3 deco slots

if isrow(weapon_slots_in)
    weapon_slots = weapon_slots_in.';
else
    weapon_slots = weapon_slots_in;
end

% v is [Attack Boost Level; Expert Level; Crit Boost Level]
EVdWrapper = @(v) EVd(WeaponStats([baseattack;baseaffinity;weapon_slots;v]));

nFrames = 6;

vec_atk = 0:1:5;
vec_exp = 0:1:5;
vec_crit = 0:1:5;

efr_col_palette = turbo(32);

efrlb = baseattack - 0.1*baseattack;
efrub = 1.2*baseattack + 5;
vec_colorbar_domain = efrlb:5:efrub;
vec_colorbar_bounds = [efrlb efrub];

[nEXP, nCRIT] = meshgrid(vec_exp, vec_crit);

rootfigure = uifigure('Name',  ...
    sprintf('EFR for weapon w/ Base Attack: %.2f, Base Affinity: %.2f%%; Deco Slots: %d Lvl 1, %d Lvl 2, %d Lvl 3', ...
    baseattack, baseaffinity, weapon_slots(1), weapon_slots(2), ...
    weapon_slots(3)));

m_layout = uigridlayout(rootfigure, [2 3]);
m_layout.Padding = [20, 20, 20, 20];

r = 1;
c = 1;

m_axes = zeros(nFrames);
m_colorbars = zeros(nFrames);

maxefr = 0;
minefr = EVdWrapper([0; 0; 0]);

for idx = 1:nFrames

    EFR = arrayfun(@(nExp, nCrit) EVdWrapper([vec_atk(idx); nExp; nCrit]), nEXP, nCRIT);
    thismaxefr = max(EFR(:));
    thisminefr = min(EFR(:));

    maxefr = max(maxefr, thismaxefr);

    if thisminefr < minefr && thisminefr > 0
        minefr = thisminefr;
    end

    ax = uiaxes(m_layout);
    m_axes(idx) = ax;
    axis(ax, 'tight');

    imagesc(ax, 'XData', vec_exp, 'YData', vec_crit, 'CData', EFR);
    grid(ax, 'on');
    set(ax, 'YDir', 'normal');
    clim(ax, vec_colorbar_bounds);
    colormap(ax, efr_col_palette);

    hColBar = colorbar(ax);
    m_colorbars(idx) = hColBar;
    hColBar.Ticks = vec_colorbar_domain;
    ylabel(hColBar, 'Effective Raw Attack');


    xlabel(ax, 'Expert Level');
    ylabel(ax, 'Critical Boost Level');
    xticks(ax, 0:1:5);
    yticks(ax, 0:1:5);

    title(ax, sprintf('For Attack Boost Level = %.2f', vec_atk(idx)));

    for row = 1:6
        for col = 1:6
            value = EFR(row, col);

            if value > 0
                disptxt = num2str(value);
            else
                disptxt = 'X';
            end

            text(ax, col - 1 + 0.015, row - 1 - 0.0125, disptxt, ...
                'Color', 'black', 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', 'FontSize', 18);
            text(ax, col - 1, row - 1, disptxt, ...
                'Color', 'white', 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', 'FontSize', 18);
        end
    end

    drawnow;

    if c >= 3
        r = r + 1;
        c = 1;
    else
        c = c + 1;
    end
end

for idx = 1:nFrames
    clim(m_axes(idx), [minefr maxefr + 5]);
    hColorBar = colorbar(m_axes(idx));
    hColorBar.Ticks = minefr:5:maxefr + 5;
end


end

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

function [stats] = WeaponStats(v)
% #Atk + #Expert + #Crit <= 3
baseattack = v(1);
baseaffinity = v(2);
basecrit = 25;
nSlots = v(3:5);

attacklevel = v(6);
explevel = v(7);
critlevel = v(8);

validmultiple = IsSkillComboPossible(nSlots, v(6:8));

atkboost = AttackBoost(attacklevel, baseattack);
affinityboost = AffinityBoost(explevel);
critboost = CritBoost(critlevel);

stats = validmultiple * ...
    [atkboost + baseattack; ...
    min(100,baseaffinity + affinityboost);...
    critboost + basecrit];

end


function [valid] = IsSkillComboPossible(weapon_gem_slots, skills)
% weapon_slots = [lvl1 lvl2 lvl3]
% skills = [Attack Lvl, Expert Lvl, Crit Boost Lvl];

% Brute force. Short explanation for why this function is even necessary:
% By using skill levels rather than gems, it reduces the dimension from 9 to 3
% which makes the information easier to plot; however, this complicates
% detecting whether or not a combination of skills is possible in a
% particular slot configuration

valid = false;

persistent A B C combos dim

if isempty(dim)
    dim = [3;3;3];
    [A, B, C] = ndgrid(0:dim(1), 0:dim(2), 0:dim(3));
    combos = [A(:), B(:), C(:)];
end

for idx = 1:length(combos)
    gemcombination = combos(idx,:);
    combsum = sum(gemcombination);
    weapslotsum = sum(weapon_gem_slots .* [1;2;3]);
    if combsum <= weapslotsum && weapslotsum <= 9

        gemcomb = gemcombination;
        slots = weapon_gem_slots;
        combidx = 1;
        slotidx = 1;

        gemcomb = sort(gemcomb);
        iscombvalid = false;

        while combidx <= 3
            if(gemcomb(combidx) > 0)
                foundidx = findminslot(slots, gemcomb(combidx));
                if ~isempty(foundidx)
                    % Have a slot available for this gem level; now use it to
                    % remove it
                    gemcomb(combidx) = gemcomb(combidx) - foundidx;
                    slots(foundidx) = slots(foundidx) - 1;
                end
            end
            combidx = combidx + 1;
        end

        iscombvalid = sum(gemcomb > 0) <= 0;

        if iscombvalid
            % A gem combination which meets the above condition could
            % fit in the weapon's available gem slots

            % We need to check if the combination can meet or
            % exceed the skill levels requested while requiring
            % that each gem of the combination only be used for one
            % skill
            skcopy = skills;
            skidx = 1;
            combidx = 1;
            while skidx <= 3 && combidx <= 3
                if skcopy(skidx) == 0
                    skidx = skidx + 1;
                    continue;
                end
                skcopy(skidx) = skcopy(skidx) - gemcombination(combidx);
                combidx = combidx + 1;
                if(skcopy(skidx) <= 0)
                    skidx = skidx + 1;
                end
            end

            if sum(skcopy > 0) == 0
%                 fprintf("Valid: skills %d %d %d for combo %d %d %d\n", ...
%                     skills(1), skills(2), skills(3), ...
%                     gemcombination(1), gemcombination(2), gemcombination(3));
%                     
                valid = true;
                return;
            end

        end

    end
end
end

function retval = findminslot(v, value)
    for idx = value:length(v)
        if(idx >= value && v(idx) > 0)
            retval = idx;
            return;
        end
    end
    retval = [];
end

function [result] = UnitStep(x)
% Matlab defines heaviside(0) to be 0.5, which is a perfectly sensible
% perversion. It can be changed globally but I'd rather not screw around
% with a user's settings
result = (x >= 0);
end

function [boost] = AttackBoost(lvl, attack)
nLvl = floor(lvl);
atk = floor(attack);
boost = ...
    (9+  0.04*atk)*UnitStep(nLvl - 5) + ...
    (8 + 0.02*atk)*UnitStep(nLvl - 4) - (8+.02*atk)*UnitStep(nLvl - 5) + ...
    7*UnitStep(nLvl - 3) - 7*UnitStep(nLvl - 4) + ...
    5*UnitStep(nLvl - 2) - 5*UnitStep(nLvl - 3) + ...
    3*UnitStep(nLvl - 1) - 3*UnitStep(nLvl - 2);
end

function [critboost] = CritBoost(lvl)
nLvl = floor(lvl);
critboost = ((nLvl) * 3) * (UnitStep(nLvl - 1) - UnitStep(nLvl - 6)) ...
    + 15*UnitStep(nLvl - 6);
end

function [affboost] = AffinityBoost(lvl)
nLvl = floor(lvl);
affboost = (nLvl * 4) * (UnitStep(nLvl - 1) - UnitStep(nLvl - 6)) ...
    + 20*UnitStep(nLvl - 6);
end





