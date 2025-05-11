classdef PlotWeaponGemEFR  < handle

    properties
        m_rootfigure; % The main figure (window) for our application
        m_toplayout; % The layout which holds all others
        m_editpanel; % Layout that holds edit controls

        m_updatebutton; % Updates plots on press
        m_editboxes = cell(1, 5); %Edit boxes to hold plot arguments

        m_labels = cell(1, 5);
        m_labeltext = ["Base Attack"; "Base Affinity"; ...
                        "Lvl 1 Slots"; "Lvl 2 Slots"; ...
                        "Lvl 3 Slots"];

        m_editranges = [0 300;-100 100;0 3;0 3;0 3]; % Valid bounds for edit boxes
        m_editdefaults = [200 15 0 0 3]; % Default values for edit boxes

        %%% Plot Properties %%%
        m_axes = cell(1, 6);
        m_colorbars;
        m_plotlayout;
        m_nFrames = 6;
    end %%% End Properties section %%%

methods

    function obj = PlotWeaponGemEFR()
        % Only use local versions of user functions so I am reminded that
        % this script should not require more than one file
        warning('off', 'MATLAB:dispatcher:nameConflict');
        rmpath(genpath('path/to/other/functions'));

        obj.InitUI();
        obj.MakePlots();
    end

    function InitUI(obj)
        obj.m_rootfigure = uifigure;
        
        obj.m_toplayout = uigridlayout(obj.m_rootfigure, [2 2]);
        obj.m_toplayout.RowHeight = {'fit','9x'};
        obj.m_toplayout.ColumnWidth = {'2x','1x'};
        
        obj.m_editpanel = uigridlayout(obj.m_toplayout, [2 5]);
        obj.m_editpanel.Layout.Row = 1;
        obj.m_editpanel.Layout.Column = 1;
        obj.m_editpanel.Padding = [1, 1, 1, 1];
        
        obj.m_updatebutton = uibutton(obj.m_toplayout);
        obj.m_updatebutton.Layout.Row = 1;
        obj.m_updatebutton.Layout.Column = 2;
        obj.m_updatebutton.Text = "Update";
    
        for idx=1:5
            hLabel = uilabel(obj.m_editpanel);
            obj.m_labels{idx} = hLabel;
            hLabel.Layout.Row = 1;
            hLabel.Layout.Column = idx;
            hLabel.Text = obj.m_labeltext(idx);
            hLabel.HorizontalAlignment = 'center';

            obj.m_editboxes{idx} = uieditfield(obj.m_editpanel, "Numeric");
            obj.m_editboxes{idx}.Layout.Row = 2;
            obj.m_editboxes{idx}.Layout.Column = idx;
            obj.m_editboxes{idx}.Limits = obj.m_editranges(idx,:);
            obj.m_editboxes{idx}.Value = obj.m_editdefaults(idx);
        end
        
        obj.m_plotlayout = uigridlayout(obj.m_toplayout, [2 3]);
        obj.m_plotlayout.Layout.Row = 2;
        obj.m_plotlayout.Layout.Column = [1,2];
        obj.m_plotlayout.RowSpacing = 20;
        obj.m_plotlayout.ColumnSpacing = 40;
        %obj.m_plotlayout.RowHeight = {100, '1x'};
        obj.m_plotlayout.ColumnWidth = {'1x', '1x', '1x',};
        obj.m_plotlayout.Padding = [20, 20, 20, 20];

        obj.m_updatebutton.ButtonPushedFcn = {@OnUpdateButtonPushed};
        
        obj.m_axes = cell(1, obj.m_nFrames);
        for idx=1:obj.m_nFrames
            obj.m_axes{idx} = uiaxes(obj.m_plotlayout);
        end

        function OnUpdateButtonPushed(src, event)
            for idx = 1:obj.m_nFrames
                cla(obj.m_axes{idx}, 'reset');
            end

            obj.MakePlots();
        end

    end

    function MakePlots(obj)

        baseattack = obj.m_editboxes{1}.Value;
        baseaffinity = obj.m_editboxes{2}.Value;
        weapon_slots = [...
            obj.m_editboxes{3}.Value;...
            obj.m_editboxes{4}.Value;...
            obj.m_editboxes{5}.Value
        ];
        
        obj.m_rootfigure.Name = sprintf([...
            'EFR for weapon w/ Base Attack: %.2f, Base Affinity:...' ...
            ' %.2f%%; Deco Slots: %d Lvl 1, %d Lvl 2, %d Lvl 3'], ...
            baseattack, baseaffinity, weapon_slots(1), weapon_slots(2), ...
            weapon_slots(3));
        
        vec_atk = 0:1:5;
        vec_exp = 0:1:5;
        vec_crit = 0:1:5;
        
        efr_col_palette = turbo(32);
        
        efrlb = baseattack - 0.1*baseattack;
        efrub = 1.2*baseattack + 5;

        vec_colorbar_bounds = [efrlb efrub];
        
        [nEXP, nCRIT] = meshgrid(vec_exp, vec_crit);
        
        %%% Plots Setup %%%
        
        % Bind base attack, affinity, and weapon slots to the function
        % for convenience
        
        % v is [Attack Boost Level; Expert Level; Crit Boost Level]
        EVdWrapper = @(v) EVd(WeaponStats([baseattack;baseaffinity;weapon_slots;v]));
        
    
        
        % Track the minimum and maximum values of EFR to scale
        % the range of the colorbar later
        maxefr = 0;
        minefr = EVdWrapper([0; 0; 0]);

        nFrames = 6;

        for idx = 1:nFrames
        
            % Bind the EVd function to this frame's attack skill level
            EFR = arrayfun(@(nExp, nCrit) ...
                EVdWrapper([vec_atk(idx); nExp; nCrit]), nEXP, nCRIT);

            thismaxefr = max(EFR(:));
            thisminefr = min(EFR(:));
        
            maxefr = max(maxefr, thismaxefr);
        
            if thisminefr < minefr && thisminefr > 0
                minefr = thisminefr;
            end
        
            hAxes = obj.m_axes{idx};
            axis(hAxes, 'tight');
        
            imagesc(hAxes, 'XData', vec_exp, 'YData', vec_crit, 'CData', EFR);
            grid(hAxes, 'on');
            set(hAxes, 'YDir', 'normal');
            clim(hAxes, vec_colorbar_bounds);
            colormap(hAxes, efr_col_palette);
                
            xlabel(hAxes, 'Expert Level');
            ylabel(hAxes, 'Critical Boost Level');
            xticks(hAxes, 0:1:5);
            yticks(hAxes, 0:1:5);
        
            title(hAxes, sprintf('For Attack Boost Level = %.2f', vec_atk(idx)));
        
            for row = 1:6
                for col = 1:6
                    value = EFR(row, col);
        
                    if value > 0
                        disptxt = sprintf('%.2f', value);
                    else
                        disptxt = 'X';
                    end
        
                    text(hAxes, col - 1 + 0.015, row - 1 - 0.0125, disptxt, ...
                        'Color', 'black', 'FontWeight', 'bold', ...
                        'HorizontalAlignment', 'center', 'FontSize', 18);
                    text(hAxes, col - 1, row - 1, disptxt, ...
                        'Color', 'white', 'FontWeight', 'bold', ...
                        'HorizontalAlignment', 'center', 'FontSize', 18);
                end
            end
        
            
        end
        
        % Update colorbar thresholds based on the min/max values found
        for idx = 1:nFrames
            clim(obj.m_axes{idx}, [minefr maxefr + 5]);
            hColorBar = colorbar(obj.m_axes{idx});
            hColorBar.Ticks = minefr:5:maxefr + 5;
            ylabel(hColorBar, 'Effective Raw Attack');
        end
    
        drawnow;

    end %%% End MakePlots function %%%
    
    function [OutgoingRaw] = EVd(v)
        % Expected Value of Outgoing Raw Damage, before multiplication by 
        % MV, HZ, and Sharpness
        
        % v(1) = True Raw Attack of weapon, including bonus
        % v(2) = Affinity %, including bonus
        % v(3) = Critical Damage Bonus, including base +25%
        
        if v(2) >= 0
            OutgoingRaw = v(1) + v(1)*(v(2)/100)*(v(3)/100);
        else
            OutgoingRaw = v(1) + v(1)*(v(2)/100)*(25/100);
        end
    
    end
    
    function [stats] = WeaponStats(v)
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

    function [bValid] = IsSkillComboPossible(weapon_gem_slots, skills)
        % weapon_slots = [lvl1 lvl2 lvl3]
        % skills = [Attack Lvl, Expert Lvl, Crit Boost Lvl];
        
        % Brute force. Short explanation for why this function is even necessary:
        % By using skill levels rather than gems, it reduces the dimension from 9 to 3
        % which makes the information easier to plot; however, this complicates
        % detecting whether or not a combination of skills is possible in a
        % particular slot configuration
        
        bValid = false;
        
        persistent A B C combos dim
        
        if isempty(dim)
            dim = [3;3;3]; %Because of how we do this, only 3 total gems are ever allowed
            [A, B, C] = ndgrid(0:dim(1), 0:dim(2), 0:dim(3));
            combos = [A(:), B(:), C(:)];
        end
        
        for idx = 1:length(combos)
            % Copy the weapon gem combination to subtract from
            % By subtracting the available weapon slot levels, we
            % can figure out if the weapon has enough to fit

            %  This can be replaced later by something more efficient

            gemcombination = combos(idx,:);
            combsum = sum(gemcombination);
            weapslotsum = sum(weapon_gem_slots .* [1;2;3]);
            if combsum <= weapslotsum
        
                gemcomb = gemcombination;
                slots = weapon_gem_slots;
                combidx = 1;
        
                gemcomb = sort(gemcomb);
        
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
        
                bIsCombValid = sum(gemcomb > 0) <= 0;
        
                if bIsCombValid
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
                        bValid = true;
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
        (8 + 0.02*atk)*(UnitStep(nLvl - 4) - UnitStep(nLvl - 5)) + ...
        7*(UnitStep(nLvl - 3) - UnitStep(nLvl - 4)) + ...
        5*(UnitStep(nLvl - 2) - UnitStep(nLvl - 3)) + ...
        3*(UnitStep(nLvl - 1) - UnitStep(nLvl - 2));
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

end %%% End Methods section %%%


end %%% End class definition %%%



