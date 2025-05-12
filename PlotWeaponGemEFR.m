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
        
        % hunt duration
        %[attack bonus, affinity bonus, duty cycle, start time;
        % attack bonus2, affinity bonus2, duty cycle2, start time2]
        
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
            weapon_slots = [...
            obj.m_editboxes{3}.Value;...
            obj.m_editboxes{4}.Value;...
            obj.m_editboxes{5}.Value
                ];
            if sum(weapon_slots) > 3
                msgbox("Sum of slots must be 3 or less.", "Note");
            else
                for idx = 1:obj.m_nFrames
                    cla(obj.m_axes{idx}, 'reset');
                end
                drawnow;
                obj.MakePlots();
            end
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
        
        weapon = Weapon(baseattack, baseaffinity, weapon_slots);

        % v is [Attack Boost Level; Expert Level; Crit Boost Level]
        EVdWrapper = @(v) Weapon.EVd(weapon.WeaponStats([v;0;0]));
        
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
    

    
   
end %%% End Methods section %%%


end %%% End class definition %%%

