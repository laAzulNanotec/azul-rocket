classdef TrailerVaultApp2 < matlab.apps.AppBase
    % TRAILER VAULT GEOMETRY & SOLAR HARVEST CALCULATOR
    % App Designer GUI  — Chapter 12: The Trailer
    %
    % Replicates Python dashboard functionality in native MATLAB App Designer.
    % Run:   TrailerVaultApp2
    %
    % REQUIRES: MATLAB R2019b or later with App Designer.
    %           No additional toolboxes needed.
    %
    % CONTROLS:
    %   Site presets  — Petén / California / Austin / Custom
    %   Vault presets — Semicircle / Low arc 120° / Raised arc 150° / Gothic / Catenary
    %   Sliders       — latitude, PSH, albedo, canyon angle, W, L, FH
    %   Panel sliders — panels along length, arc rows, derating, north panels
    %
    % OUTPUTS (live-updated on every slider change):
    %   • Cross-section axes  — vault shape with shoulder + sun arrows
    %   • Hourly harvest axes — kW by face (arc + north) across 6h–18h
    %   • Bar chart           — shape comparison (daily kWh)
    %   • Summary panel       — total panels, peak kW, daily kWh, annual MWh
    % =========================================================================

    properties (Access = public)
        UIFigure            matlab.ui.Figure
        LeftPanel           matlab.ui.container.Panel
        BtnPeten            matlab.ui.control.Button
        BtnCalifornia       matlab.ui.control.Button
        BtnAustin           matlab.ui.control.Button
        BtnCustom           matlab.ui.control.Button
        BtnSemi             matlab.ui.control.Button
        BtnLow60            matlab.ui.control.Button
        BtnRaised150        matlab.ui.control.Button
        BtnGothic           matlab.ui.control.Button
        BtnCatenary         matlab.ui.control.Button
        SliderLat           matlab.ui.control.Slider
        SliderPSH           matlab.ui.control.Slider
        SliderAlbedo        matlab.ui.control.Slider
        SliderCanyon        matlab.ui.control.Slider
        SliderW             matlab.ui.control.Slider
        SliderL             matlab.ui.control.Slider
        SliderFH            matlab.ui.control.Slider
        SliderNlong         matlab.ui.control.Slider
        SliderNrow          matlab.ui.control.Slider
        SliderDerate        matlab.ui.control.Slider
        SliderNnorth        matlab.ui.control.Slider
        LblLat              matlab.ui.control.Label
        LblPSH              matlab.ui.control.Label
        LblAlbedo           matlab.ui.control.Label
        LblCanyon           matlab.ui.control.Label
        LblW                matlab.ui.control.Label
        LblL                matlab.ui.control.Label
        LblFH               matlab.ui.control.Label
        LblNlong            matlab.ui.control.Label
        LblNrow             matlab.ui.control.Label
        LblDerate           matlab.ui.control.Label
        LblNnorth           matlab.ui.control.Label
        ValLat              matlab.ui.control.Label
        ValPSH              matlab.ui.control.Label
        ValAlbedo           matlab.ui.control.Label
        ValCanyon           matlab.ui.control.Label
        ValW                matlab.ui.control.Label
        ValL                matlab.ui.control.Label
        ValFH               matlab.ui.control.Label
        ValNlong            matlab.ui.control.Label
        ValNrow             matlab.ui.control.Label
        ValDerate           matlab.ui.control.Label
        ValNnorth           matlab.ui.control.Label
        KpiPanelsVal        matlab.ui.control.Label
        KpiPeakVal          matlab.ui.control.Label
        KpiDailyVal         matlab.ui.control.Label
        KpiNorthVal         matlab.ui.control.Label
        KpiAnnualVal        matlab.ui.control.Label
        LblDesc             matlab.ui.control.Label
        AxXsec              matlab.ui.control.UIAxes
        AxHourly            matlab.ui.control.UIAxes
        AxBar               matlab.ui.control.UIAxes
        LblFooter           matlab.ui.control.Label
    end

    methods (Access = private)

        function createComponents(app)
            % Figure
            app.UIFigure = uifigure('Visible','off');
            app.UIFigure.Position = [60 60 1240 820];
            app.UIFigure.Name     = 'Trailer Vault Geometry & Solar Harvest — Chapter 12';
            app.UIFigure.Color    = [0.97 0.97 0.96];

            % Color palette
            CLR_GREEN  = [0.11 0.62 0.46];
            CLR_PURP   = [0.33 0.29 0.72];
            CLR_BLUE   = [0.21 0.37 0.65];
            CLR_AMBER  = [0.72 0.47 0.09];
            CLR_BG     = [0.97 0.97 0.96];
            CLR_PANEL  = [1.00 1.00 0.99];
            CLR_BORDER = [0.82 0.82 0.80];
            CLR_HEAD   = [0.18 0.18 0.18];

            % Left control panel
            app.LeftPanel = uipanel(app.UIFigure,...
                'Position',[8 8 318 804],'BackgroundColor',CLR_PANEL,...
                'BorderType','line','HighlightColor',CLR_BORDER,...
                'Title','','FontSize',1);

            y = 765;
            % Title
            uilabel(app.LeftPanel,'Text','TRAILER VAULT  |  Chapter 12',...
                'Position',[10 y 298 22],'FontSize',12,'FontWeight','bold',...
                'FontColor',CLR_HEAD,'HorizontalAlignment','center');
            y = y - 28;

            % Site presets
            uilabel(app.LeftPanel,'Text','Site & season',...
                'Position',[10 y 120 18],'FontSize',9,'FontColor',[0.4 0.4 0.4]);
            y = y - 24;
            bw = 68; bh = 26; gap = 4;
            app.BtnPeten      = app.makePresetBtn(app.LeftPanel,'Petén 16.5°N',[10    y bw bh],CLR_GREEN);
            app.BtnCalifornia = app.makePresetBtn(app.LeftPanel,'California 34°N',[10+bw+gap y bw+14 bh],CLR_GREEN);
            app.BtnAustin     = app.makePresetBtn(app.LeftPanel,'Austin 30°N',[10+2*(bw+gap)+14 y bw bh],CLR_GREEN);
            app.BtnCustom     = app.makePresetBtn(app.LeftPanel,'Custom',[10+3*(bw+gap)+14 y bw-6 bh],[0.6 0.6 0.6]);
            y = y - 32;

            % Site sliders
            [app.SliderLat,   app.LblLat,   app.ValLat]   = app.makeSlider(app.LeftPanel,'Latitude (°N)',       y, 0,  60, 16.5,  '%.0f');   y=y-36;
            [app.SliderPSH,   app.LblPSH,   app.ValPSH]   = app.makeSlider(app.LeftPanel,'Peak sun hrs/day',    y, 3,   9,  6.0,  '%.1f');    y=y-36;
            [app.SliderAlbedo,app.LblAlbedo,app.ValAlbedo] = app.makeSlider(app.LeftPanel,'Canyon albedo',       y, 0,   1,  0.45, '%.2f');    y=y-36;
            [app.SliderCanyon,app.LblCanyon,app.ValCanyon] = app.makeSlider(app.LeftPanel,'Canyon wall angle',   y, 0,  90, 70,   '%.0f');   y=y-40;

            % Vault presets
            uilabel(app.LeftPanel,'Text','Vault geometry',...
                'Position',[10 y 150 18],'FontSize',9,'FontColor',[0.4 0.4 0.4]);
            y = y - 24;
            vbw = 56; vbh = 24;
            app.BtnSemi    = app.makePresetBtn(app.LeftPanel,'Semicircle',  [10          y vbw+4 vbh],CLR_BLUE);
            app.BtnLow60   = app.makePresetBtn(app.LeftPanel,'Low arc 120°', [10+vbw+8    y vbw+8 vbh],CLR_BLUE);
            app.BtnRaised150=app.makePresetBtn(app.LeftPanel,'Raised 150°', [10+2*vbw+20 y vbw+8 vbh],CLR_BLUE);
            y = y - 28;
            app.BtnGothic  = app.makePresetBtn(app.LeftPanel,'Gothic',      [10          y vbw   vbh],[0.50 0.35 0.65]);
            app.BtnCatenary= app.makePresetBtn(app.LeftPanel,'Catenary',    [10+vbw+8    y vbw+8 vbh],[0.50 0.35 0.65]);
            y = y - 6;

            % Vault description
            app.LblDesc = uilabel(app.LeftPanel,'Text','120° low arc — optimal east-west solar sweep.',...
                'Position',[10 y-30 298 36],'FontSize',8,'FontColor',[0.45 0.45 0.45],...
                'WordWrap','on');
            y = y - 54;

            % Trailer dimensions
            uilabel(app.LeftPanel,'Text','Trailer dimensions',...
                'Position',[10 y 150 18],'FontSize',9,'FontColor',[0.4 0.4 0.4]);
            y = y - 24;
            [app.SliderW, app.LblW, app.ValW] = app.makeSlider(app.LeftPanel,'Width (ft)',       y, 6, 10, 7.5, '%.1f'); y=y-36;
            [app.SliderL, app.LblL, app.ValL] = app.makeSlider(app.LeftPanel,'Length (ft)',      y,16, 32,  24, '%.0f'); y=y-36;
            [app.SliderFH,app.LblFH,app.ValFH]= app.makeSlider(app.LeftPanel,'Flat floor ht (ft)',y,2,  6,   4, '%.1f'); y=y-40;

            % Panel configuration
            uilabel(app.LeftPanel,'Text','Panel (Lensun 400W 48V)',...
                'Position',[10 y 200 18],'FontSize',9,'FontColor',[0.4 0.4 0.4]);
            y = y - 24;
            [app.SliderNlong, app.LblNlong, app.ValNlong] = app.makeSlider(app.LeftPanel,'Panels along length', y, 1, 8,   4, '%.0f'); y=y-36;
            [app.SliderNrow,  app.LblNrow,  app.ValNrow]  = app.makeSlider(app.LeftPanel,'Panels rows on arc',  y, 1, 4,   2, '%.0f'); y=y-36;
            [app.SliderDerate,app.LblDerate,app.ValDerate] = app.makeSlider(app.LeftPanel,'System derating',    y, 0.7, 1.0, 0.87, 'pct'); y=y-36;
            [app.SliderNnorth,app.LblNnorth,app.ValNnorth] = app.makeSlider(app.LeftPanel,'North face panels',  y, 0, 6,   2, '%.0f'); y=y-40;

            % KPI summary strip
            y = y - 10;
            kpi_labels = {'Total panels','Peak power','Daily harvest','North face bonus','Annual yield'};
            kpi_units  = {'','kW rated','kWh/day','kWh/day reflected','MWh/year'};
            kpi_colors = {CLR_HEAD, CLR_GREEN, CLR_GREEN, CLR_BLUE, CLR_AMBER};
            kpiW = 55; kpiX = [10 10+kpiW+5 10+2*(kpiW+5) 10+3*(kpiW+5) 10+4*(kpiW+5)];
            
            app.KpiPanelsVal = uilabel(app.LeftPanel,'Text','—',...
                'Position',[kpiX(1) y-20 kpiW+4 20],'FontSize',13,'FontWeight','bold',...
                'FontColor',kpi_colors{1},'HorizontalAlignment','center');
            app.KpiPeakVal   = uilabel(app.LeftPanel,'Text','—',...
                'Position',[kpiX(2) y-20 kpiW+4 20],'FontSize',13,'FontWeight','bold',...
                'FontColor',kpi_colors{2},'HorizontalAlignment','center');
            app.KpiDailyVal  = uilabel(app.LeftPanel,'Text','—',...
                'Position',[kpiX(3) y-20 kpiW+4 20],'FontSize',13,'FontWeight','bold',...
                'FontColor',kpi_colors{3},'HorizontalAlignment','center');
            app.KpiNorthVal  = uilabel(app.LeftPanel,'Text','—',...
                'Position',[kpiX(4) y-20 kpiW+4 20],'FontSize',13,'FontWeight','bold',...
                'FontColor',kpi_colors{4},'HorizontalAlignment','center');
            app.KpiAnnualVal = uilabel(app.LeftPanel,'Text','—',...
                'Position',[kpiX(5) y-20 kpiW+4 20],'FontSize',13,'FontWeight','bold',...
                'FontColor',kpi_colors{5},'HorizontalAlignment','center');

            for k = 1:5
                uilabel(app.LeftPanel,'Text',kpi_labels{k},...
                    'Position',[kpiX(k) y kpiW+4 16],'FontSize',7,...
                    'FontColor',[0.5 0.5 0.5],'HorizontalAlignment','center','WordWrap','on');
                uilabel(app.LeftPanel,'Text',kpi_units{k},...
                    'Position',[kpiX(k) y-34 kpiW+4 14],'FontSize',6.5,...
                    'FontColor',[0.6 0.6 0.6],'HorizontalAlignment','center');
            end

            % Right axes
            app.AxXsec = uiaxes(app.UIFigure,'Position',[334 412 450 390]);
            title(app.AxXsec,'Cross-section — vault shape','FontSize',10,'FontWeight','bold');
            xlabel(app.AxXsec,'Width (mm)'); ylabel(app.AxXsec,'Height (mm)');
            app.AxXsec.Color = CLR_BG; app.AxXsec.GridAlpha = 0.15;

            app.AxHourly = uiaxes(app.UIFigure,'Position',[792 412 440 390]);
            title(app.AxHourly,'Hourly harvest by face','FontSize',10,'FontWeight','bold');
            xlabel(app.AxHourly,'Hour'); ylabel(app.AxHourly,'kW');
            app.AxHourly.Color = CLR_BG; app.AxHourly.GridAlpha = 0.15;
            app.AxHourly.XLim = [6 18];

            app.AxBar = uiaxes(app.UIFigure,'Position',[334 28 900 370]);
            title(app.AxBar,'Shape comparison — daily harvest (kWh) at current settings',...
                  'FontSize',10,'FontWeight','bold');
            xlabel(app.AxBar,'kWh/day');
            app.AxBar.Color = CLR_BG; app.AxBar.GridAlpha = 0.15;

            % Footer
            app.LblFooter = uilabel(app.UIFigure,...
                'Text','',...
                'Position',[334 8 900 18],'FontSize',7.5,...
                'FontColor',[0.45 0.45 0.45],'WordWrap','on');

            % Callbacks
            app.BtnPeten.ButtonPushedFcn       = @(~,~) app.setSite(16.5, 6.0, 0.45, 70);
            app.BtnCalifornia.ButtonPushedFcn  = @(~,~) app.setSite(34.0, 5.5, 0.25, 50);
            app.BtnAustin.ButtonPushedFcn      = @(~,~) app.setSite(30.0, 5.8, 0.35, 60);
            app.BtnCustom.ButtonPushedFcn      = @(~,~) app.updateAll();
            app.BtnSemi.ButtonPushedFcn        = @(~,~) app.setVault(180,'arc');
            app.BtnLow60.ButtonPushedFcn       = @(~,~) app.setVault(120,'arc');
            app.BtnRaised150.ButtonPushedFcn   = @(~,~) app.setVault(240,'arc');
            app.BtnGothic.ButtonPushedFcn      = @(~,~) app.setVault(190,'gothic');
            app.BtnCatenary.ButtonPushedFcn    = @(~,~) app.setVault(0,  'catenary');

            sliders = {app.SliderLat, app.SliderPSH, app.SliderAlbedo, app.SliderCanyon,...
                       app.SliderW, app.SliderL, app.SliderFH,...
                       app.SliderNlong, app.SliderNrow, app.SliderDerate, app.SliderNnorth};
            for s = sliders
                s{1}.ValueChangedFcn = @(~,~) app.updateAll();
            end

            app.UIFigure.Visible = 'on';
        end

        function btn = makePresetBtn(~, parent, txt, pos, clr)
            btn = uibutton(parent,'push','Text',txt,'Position',pos,...
                'BackgroundColor',clr,'FontColor',[1 1 1],...
                'FontSize',8,'FontWeight','bold');
        end

        function [sld, lbl, val] = makeSlider(~, parent, name, y, lo, hi, def, fmt)
            lbl = uilabel(parent,'Text',name,...
                'Position',[10 y+16 180 16],'FontSize',8,...
                'FontColor',[0.35 0.35 0.35]);
            sld = uislider(parent,'Limits',[lo hi],'Value',def,...
                'Position',[10 y 240 3],'MajorTicks',[],'MinorTicks',[]);
            if strcmp(fmt, 'pct')
                vstr = sprintf('%.0f%%', def*100);
            else
                vstr = sprintf(fmt, def);
            end
            val = uilabel(parent,'Text',vstr,...
                'Position',[255 y+12 60 16],'FontSize',8,...
                'FontColor',[0.15 0.15 0.15],'HorizontalAlignment','right');
        end

        function setSite(app, lat, psh, alb, canyon)
            app.SliderLat.Value    = lat;
            app.SliderPSH.Value    = psh;
            app.SliderAlbedo.Value = alb;
            app.SliderCanyon.Value = canyon;
            app.updateAll();
        end

        function setVault(app, arc_deg, shape_type)
            app.UIFigure.UserData = struct('arc_deg', arc_deg, 'shape', shape_type);
            app.updateAll();
        end

        function updateAll(app)
            % Read controls
            lat      = app.SliderLat.Value;
            psh      = app.SliderPSH.Value;
            albedo   = app.SliderAlbedo.Value;
            canyon   = app.SliderCanyon.Value;
            W_ft     = app.SliderW.Value;
            L_ft     = app.SliderL.Value;
            FH_ft    = app.SliderFH.Value;
            n_long   = round(app.SliderNlong.Value);
            n_row    = round(app.SliderNrow.Value);
            derate   = app.SliderDerate.Value;
            n_north  = round(app.SliderNnorth.Value);

            ud = app.UIFigure.UserData;
            if isempty(ud)
                arc_deg    = 120;
                shape_type = 'arc';
            else
                arc_deg    = ud.arc_deg;
                shape_type = ud.shape;
            end

            % Update labels
            app.ValLat.Text    = sprintf('%.0f°',     lat);
            app.ValPSH.Text    = sprintf('%.1f',      psh);
            app.ValAlbedo.Text = sprintf('%.2f',      albedo);
            app.ValCanyon.Text = sprintf('%.0f°',     canyon);
            app.ValW.Text      = sprintf('%.1f',      W_ft);
            app.ValL.Text      = sprintf('%.0f',      L_ft);
            app.ValFH.Text     = sprintf('%.1f',      FH_ft);
            app.ValNlong.Text  = sprintf('%d',        n_long);
            app.ValNrow.Text   = sprintf('%d',        n_row);
            app.ValDerate.Text = sprintf('%.0f%%',    derate*100);
            app.ValNnorth.Text = sprintf('%d',        n_north);

            % Geometry
            ft2mm = 304.8;
            W  = W_ft  * ft2mm;
            L  = L_ft  * ft2mm;
            FH = FH_ft * ft2mm;

            [x_arc, y_arc, x_sh_L, y_sh_L, x_sh_R, y_sh_R, R_arc, barrel_apex, desc_str] = ...
                app.computeGeometry(W, FH, arc_deg, shape_type);

            app.LblDesc.Text = desc_str;

            % PLOT 1: Cross-section
            ax = app.AxXsec;
            cla(ax); hold(ax,'on'); axis(ax,'equal'); grid(ax,'on');

            fill(ax, [-W/2 W/2 W/2 -W/2],[0 0 FH FH],...
                 [0.95 0.95 0.88],'EdgeColor','none','FaceAlpha',0.55);
            text(ax, 0, FH/2,'lab floor','HorizontalAlignment','center',...
                 'FontSize',8,'Color',[0.50 0.50 0.40]);

            plot(ax,[-W/2 -W/2],[0 FH],'Color',[0.27 0.27 0.26],'LineWidth',2);
            plot(ax,[ W/2  W/2],[0 FH],'Color',[0.27 0.27 0.26],'LineWidth',2);

            if ~isempty(x_sh_L)
                plot(ax, x_sh_L, y_sh_L,'Color',[0.33 0.29 0.72],'LineWidth',2.2);
                plot(ax, x_sh_R, y_sh_R,'Color',[0.33 0.29 0.72],'LineWidth',2.2);
            end

            plot(ax, x_arc, y_arc,'Color',[0.11 0.62 0.46],'LineWidth',3);

            n_show = min(6, n_row*2+2);
            for i = round(linspace(20, length(x_arc)-20, n_show))
                if i >= 2 && i < length(x_arc)
                    dx = x_arc(i+1)-x_arc(i-1); dy_t = y_arc(i+1)-y_arc(i-1);
                    ln = hypot(dx, dy_t);
                    tang = [dx/ln dy_t/ln]; nm = [-tang(2) tang(1)];
                    pw = 60; ph = 10;
                    px1 = x_arc(i) - tang(1)*pw/2; py1 = y_arc(i) - tang(2)*pw/2;
                    px2 = x_arc(i) + tang(1)*pw/2; py2 = y_arc(i) + tang(2)*pw/2;
                    fill(ax,[px1 px2 px2+nm(1)*ph px1+nm(1)*ph],...
                            [py1 py2 py2+nm(2)*ph py1+nm(2)*ph],...
                        [0.62 0.88 0.79],'EdgeColor',[0.06 0.43 0.34],'LineWidth',0.6);
                end
            end

            sun_alt = 90 - lat + 23.5;
            sun_alt = min(sun_alt, 89);
            dx_s = cosd(90-sun_alt); dy_s = sind(90-sun_alt);
            for xs = -200:100:200
                quiver(ax, xs, barrel_apex+200, -dx_s*110, -dy_s*110, 0,...
                    'Color',[0.94 0.62 0.15],'LineWidth',1.4,'MaxHeadSize',0.5,'AutoScale','off');
            end
            text(ax, W/2-40, barrel_apex+270, sprintf('☀  alt %.0f°',sun_alt),...
                 'FontSize',8,'Color',[0.71 0.47 0.04]);

            dim_y = -80;
            plot(ax,[-W/2 W/2],[dim_y dim_y],'k-','LineWidth',0.6);
            for xi = [-W/2 W/2]; plot(ax,[xi xi],[dim_y-15 dim_y+15],'k-','LineWidth',0.6); end
            text(ax, 0, dim_y-35, sprintf('%.0f mm  (%.1f ft)',W,W_ft),...
                 'HorizontalAlignment','center','FontSize',8);
            text(ax, 0, barrel_apex+60, sprintf('arc R = %.0f mm',R_arc),...
                 'HorizontalAlignment','center','FontSize',8,'Color',[0.06 0.43 0.34]);

            ax.XLim = [-W/2-220, W/2+260];
            ax.YLim = [-130, barrel_apex+310];
            title(ax, sprintf('%s  |  %.1f ft wide', desc_str, W_ft),...
                  'FontSize',10,'FontWeight','bold');

            % PLOT 2: Hourly harvest
            ax2 = app.AxHourly;
            cla(ax2); hold(ax2,'on'); grid(ax2,'on');

            hours   = 6 : 0.25 : 18;
            P_panel = 400;

            hour_angle = (hours - 12) * 15;
            vault_f = 1 + 0.18 .* abs(cosd(hour_angle));

            cos_inc_arc = max(0, sind(lat).*sind(23.5) + cosd(lat).*cosd(23.5).*cosd(hour_angle));
            P_arc_hour  = n_long .* n_row .* P_panel .* cos_inc_arc .* vault_f .* derate / 1000;

            refl_factor  = albedo .* sind(canyon);
            north_extra  = max(0, cos_inc_arc .* (1 - cos_inc_arc));
            P_north_hour = n_north .* P_panel .* (0.08 + refl_factor .* north_extra) .* derate / 1000;

            P_arc_hour(cos_inc_arc <= 0)   = 0;
            P_north_hour(cos_inc_arc <= 0) = 0;

            % Shaded fill areas
            h_t = hours; h_r = fliplr(hours);
            fill(ax2, [h_t h_r], [P_arc_hour+P_north_hour, zeros(1,length(hours))],...
                 [0.11 0.62 0.46],'FaceAlpha',0.20,'EdgeColor','none');
            fill(ax2, [h_t h_r], [P_north_hour, zeros(1,length(hours))],...
                 [0.21 0.37 0.65],'FaceAlpha',0.25,'EdgeColor','none');

            plot(ax2, hours, P_arc_hour + P_north_hour,...
                 'Color',[0.11 0.62 0.46],'LineWidth',2,...
                 'Marker','o','MarkerSize',3,'MarkerIndices',1:4:length(hours));
            plot(ax2, hours, P_north_hour,...
                 '--','Color',[0.21 0.37 0.65],'LineWidth',1.2,...
                 'Marker','o','MarkerSize',2,'MarkerIndices',1:4:length(hours));

            ax2.XLim = [6 18];
            ax2.XTick = 6:2:18;
            ax2.YLim  = [0 max(P_arc_hour+P_north_hour)*1.25 + 0.05];
            legend(ax2,{'Arc (direct)','North (diffuse+refl)'},...
                   'Location','north','FontSize',8,'Box','off');
            title(ax2,'Hourly harvest by face','FontSize',10,'FontWeight','bold');
            xlabel(ax2,'Hour'); ylabel(ax2,'kW');

            % KPIs
            n_arc_panels = n_long * n_row;
            n_total      = n_arc_panels + n_north;
            P_peak       = n_arc_panels * P_panel * 1.10 * derate / 1000;
            E_day_arc    = trapz(hours, P_arc_hour);
            E_day_north  = trapz(hours, P_north_hour);
            E_day_total  = E_day_arc + E_day_north;
            E_year       = E_day_total * 365 / 1000;

            app.KpiPanelsVal.Text = sprintf('%d', n_total);
            app.KpiPeakVal.Text   = sprintf('%.1f', P_peak);
            app.KpiDailyVal.Text  = sprintf('%.1f', E_day_total);
            app.KpiNorthVal.Text  = sprintf('%.1f', E_day_north);
            app.KpiAnnualVal.Text = sprintf('%.1f', E_year);

            % PLOT 3: Shape comparison
            ax3 = app.AxBar;
            cla(ax3); hold(ax3,'on'); grid(ax3,'on');

            shapes   = {'Semicircle 180°','Low arc 120°','Raised arc 240°',...
                        'Gothic pointed 190°','Catenary curve'};
            harvest_f = [1.00, 1.02, 0.94, 0.96, 0.98];
            shape_idx = 2;
            switch shape_type
                case 'arc'
                    if arc_deg == 180;      shape_idx = 1;
                    elseif arc_deg == 120;  shape_idx = 2;
                    elseif arc_deg == 240;  shape_idx = 3;
                    end
                case 'gothic';   shape_idx = 4;
                case 'catenary'; shape_idx = 5;
            end
            harvest_f(shape_idx) = 1.0;
            ref = E_day_total / harvest_f(shape_idx);
            vals = ref * harvest_f;

            clr_bars = repmat([0.62 0.88 0.79], 5, 1);
            clr_bars(shape_idx,:) = [0.06 0.43 0.34];

            hb2 = barh(ax3, vals, 0.55, 'FaceColor','flat');
            hb2.CData = clr_bars;
            hb2.EdgeColor = 'none';

            ax3.YTickLabel = shapes;
            ax3.YDir = 'reverse';
            ax3.XLim = [0 max(vals)*1.15];
            xlabel(ax3,'kWh/day');
            title(ax3,'Shape comparison — daily harvest (kWh) at current settings',...
                  'FontSize',10,'FontWeight','bold');

            for k = 1:5
                text(ax3, vals(k)+0.05, k, sprintf('%.1f',vals(k)),...
                     'FontSize',8,'VerticalAlignment','middle',...
                     'Color',[0.2 0.2 0.2],'FontWeight','bold');
            end

            % Footer
            best_idx = find(harvest_f == max(harvest_f),1);
            delta = (vals(shape_idx)-vals(best_idx))/vals(best_idx)*100;
            app.LblFooter.Text = sprintf([...
                'Current: %s · %.1f kWh/day · %.1f%% vs best (%s: %.1f kWh/day)  ·  ',...
                'North bonus: %.1f kWh/day (%.0f%%)  ·  Annual: %.1f MWh/year  ·  ',...
                'Lat %.0f°N  ·  Lensun 400W 48V: direct to Sol-Arc bus — no strings, one MPPT per panel'],...
                shapes{shape_idx}, vals(shape_idx), delta, shapes{best_idx}, vals(best_idx),...
                E_day_north, E_day_north/E_day_total*100,...
                E_year, lat);
        end

        function [x_arc, y_arc, x_sh_L, y_sh_L, x_sh_R, y_sh_R, R_arc, barrel_apex, desc] = ...
                 computeGeometry(~, W, FH, arc_deg, shape_type)
            arc_half = deg2rad(arc_deg/2);

            switch shape_type
                case 'arc'
                    R_arc = (W/2) / sin(arc_half);
                    theta = linspace(-arc_half, arc_half, 300);
                    x_arc = R_arc * sin(theta);
                    y_arc = FH   + R_arc * (1 - cos(theta));
                    switch arc_deg
                        case 180; desc = 'Semicircle 180° — classic half-circle, max interior volume.';
                        case 120; desc = 'Low arc 120° — optimal east-west sweep. Best structural efficiency.';
                        case 240; desc = 'Raised arc 240° — high headroom, more E/W panel area.';
                        otherwise; desc = sprintf('Arc %.0f° — custom arc vault.', arc_deg);
                    end

                case 'gothic'
                    R_arc = W * 0.85;
                    t_L   = linspace(deg2rad(30), deg2rad(150), 150);
                    t_R   = linspace(deg2rad(30), deg2rad(150), 150);
                    x_arc = [R_arc*cos(t_L)-W/4, fliplr(-(R_arc*cos(t_R)-W/4))];
                    y_arc = [FH + R_arc*sin(t_L), fliplr(FH + R_arc*sin(t_R))];
                    desc  = 'Gothic pointed 190° — medieval geometry, dramatic ridge line.';

                case 'catenary'
                    R_arc = NaN;
                    a = W/2 / acosh(2);
                    x_arc = linspace(-W/2, W/2, 300);
                    y_arc = FH + (W/2)*0.42 * (cosh(x_arc/a) - 1);
                    desc  = 'Catenary curve — pure compression, zero bending in membrane.';

                otherwise
                    R_arc = (W/2) / sin(arc_half);
                    theta = linspace(-arc_half, arc_half, 300);
                    x_arc = R_arc * sin(theta);
                    y_arc = FH   + R_arc * (1 - cos(theta));
                    desc  = 'Custom vault.';
            end

            barrel_apex = max(y_arc);

            if strcmp(shape_type, 'arc') && ~isnan(R_arc)
                tp_x = R_arc * sin(-arc_half);
                tp_y = FH   + R_arc * (1 - cos(arc_half));
                rad_vec  = [tp_x; tp_y - FH];
                rad_unit = rad_vec / norm(rad_vec);
                t_end    = [-rad_unit(2); rad_unit(1)];
                P0 = [-W/2; FH]; P1 = [tp_x; tp_y];
                d0 = [0; 1]; d1 = t_end;
                t_s  = linspace(0, 1, 100);
                H00  =  2*t_s.^3 - 3*t_s.^2 + 1;
                H10  =    t_s.^3 - 2*t_s.^2 + t_s;
                H01  = -2*t_s.^3 + 3*t_s.^2;
                H11  =    t_s.^3 -   t_s.^2;
                scl  = norm(P1 - P0);
                x_sh_L = H00*P0(1) + H10*scl*d0(1) + H01*P1(1) + H11*scl*d1(1);
                y_sh_L = H00*P0(2) + H10*scl*d0(2) + H01*P1(2) + H11*scl*d1(2);
                x_sh_R = -x_sh_L; y_sh_R = y_sh_L;
            else
                x_sh_L = []; y_sh_L = []; x_sh_R = []; y_sh_R = [];
            end
        end
    end

    methods (Access = public)
        function app = TrailerVaultApp2()
            createComponents(app);
            registerApp(app, app.UIFigure);
            app.UIFigure.UserData = struct('arc_deg',120,'shape','arc');
            app.updateAll();
            if nargout == 0; clear app; end
        end

        function delete(app)
            delete(app.UIFigure);
        end
    end
end
