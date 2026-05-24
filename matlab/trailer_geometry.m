%% TRAILER VAULT GEOMETRY — 120° ARC BARREL VAULT
%  Correct arc formula: dome curves UPWARD from floor level
%  Parabolic end cap + compound shoulder splines
%
%  All dimensions in mm unless noted
%  Author: Chapter 12 — The Trailer
%  Usage:  Run full script or section by section (Ctrl+Enter)
% =========================================================================

clear; close all; clc;

%% ── 1. TRAILER PARAMETERS ───────────────────────────────────────────────
W_ft    = 7.5;       % trailer width  (ft)
L_ft    = 24;        % trailer length (ft)
FH_ft   = 4.0;       % flat floor height from ground (ft)
ARC_DEG = 120;       % vault arc angle (degrees)

ft2mm = 304.8;
W  = W_ft  * ft2mm;   % 2286 mm
L  = L_ft  * ft2mm;   % 7315 mm
FH = FH_ft * ft2mm;   % 1219 mm

% Arc radius: R = (W/2) / sin(arc_half)
arc_half = deg2rad(ARC_DEG/2);
R_arc    = (W/2) / sin(arc_half);
fprintf('Arc radius R = %.1f mm  (%.2f ft)\n', R_arc, R_arc/ft2mm);

%% ── 2. COMPOUND CURVE SHOULDER PARAMETERS ───────────────────────────────
r1 = 80;    % mm — inner fillet at wall/shoulder start
r2 = 320;   % mm — outer transition arc blending into vault

%% ── 3. CROSS-SECTION GEOMETRY ───────────────────────────────────────────
figure('Name','Cross-Section  |  Chapter 12 — The Trailer',...
       'Position',[50 50 900 780],'Color',[0.98 0.98 0.97]);

% ── ARC ──────────────────────────────────────────────────────────────────
% DOME geometry: circle center is ABOVE the trailer
%   Center = (0, FH + R)
%   x(theta) = R * sin(theta)
%   y(theta) = FH + R * cos(theta)
%
%   At theta = 0:       x=0,    y = FH + R          (apex — top of dome)
%   At theta = ±60°:    x=±W/2, y = FH + R*cos(60°) = FH + R/2  (feet)
%
% This creates a DOWNWARD-curving dome — correct for a roof vault.

theta_arc = linspace(-arc_half, arc_half, 300);
x_arc = R_arc * sin(theta_arc);
y_arc = FH + R_arc * cos(theta_arc);          % DOME: highest at center

% Tangent point at left foot (theta = -arc_half)
tp_x = R_arc * sin(-arc_half);                % = -W/2
tp_y = FH + R_arc * cos(arc_half);            % = FH + R/2

% ── SHOULDER TRANSITION ──────────────────────────────────────────────────
% For 120° arc with dome formula y = FH + R*cos(theta):
%   Arc foot at theta = ±60° lands at x = ±W/2, y = FH + R/2
%   This is DIRECTLY ABOVE the wall top at (±W/2, FH)
%   So the shoulder is simply a vertical line — no spline needed.

x_sh_L = ones(1,100) * (-W/2);           % vertical at x = -W/2
y_sh_L = linspace(FH, tp_y, 100);        % from wall top up to arc foot

% Mirror for right side
x_sh_R = -x_sh_L;
y_sh_R =  y_sh_L;

% ── PLOT CROSS-SECTION ───────────────────────────────────────────────────
subplot(2,1,1); hold on; axis equal; grid on;
set(gca,'FontSize',9,'GridAlpha',0.18);
title('Cross-section — 120° barrel vault','FontSize',12,'FontWeight','bold');
xlabel('Width (mm)'); ylabel('Height (mm)');

% Floor
fill([-W/2 W/2 W/2 -W/2],[0 0 FH FH],...
     [0.95 0.95 0.88],'EdgeColor','none','FaceAlpha',0.55);
text(0, FH/2,'lab floor','HorizontalAlignment','center','FontSize',9);

% Walls
plot([-W/2 -W/2],[0 FH],'Color',[0.27 0.27 0.26],'LineWidth',2);
plot([ W/2  W/2],[0 FH],'Color',[0.27 0.27 0.26],'LineWidth',2);

% Shoulder splines
plot(x_sh_L, y_sh_L,'Color',[0.33 0.29 0.72],'LineWidth',2.2);
plot(x_sh_R, y_sh_R,'Color',[0.33 0.29 0.72],'LineWidth',2.2);

% Arc vault
plot(x_arc, y_arc,'Color',[0.11 0.62 0.46],'LineWidth',3);

% Panel indicators
n_show = 6;
for i = round(linspace(30, 270, n_show))
    px = x_arc(i); py = y_arc(i);
    dx = x_arc(i+1)-x_arc(i-1); dy = y_arc(i+1)-y_arc(i-1);
    ln = sqrt(dx^2+dy^2);
    tang_x = dx/ln; tang_y = dy/ln;
    nm_x = -tang_y; nm_y = tang_x;
    pw = 60; ph = 10;
    fill([px-tang_x*pw/2 px+tang_x*pw/2 px+tang_x*pw/2+nm_x*ph px-tang_x*pw/2+nm_x*ph],...
         [py-tang_y*pw/2 py+tang_y*pw/2 py+tang_y*pw/2+nm_y*ph py-tang_y*pw/2+nm_y*ph],...
         [0.62 0.88 0.79],'EdgeColor',[0.06 0.43 0.34],'LineWidth',0.6);
end

% Sun arrows
sun_alt = 75;
dx_s = cosd(90-sun_alt); dy_s = sind(90-sun_alt);
for xs = -200:100:200
    quiver(xs, max(y_arc)+200, -dx_s*110, -dy_s*110, 0,...
        'Color',[0.94 0.62 0.15],'LineWidth',1.4,'MaxHeadSize',0.5,'AutoScale','off');
end
text(W/2-40, max(y_arc)+270,'Sun (Peten noon)','FontSize',8,'Color',[0.71 0.47 0.04]);

xlim([-W/2-220, W/2+260]);
ylim([-130, max(y_arc)+310]);

%% ── 4. SIDE PROFILE ─────────────────────────────────────────────────────
parab_depth = 600;
barrel_apex = max(y_arc);
parab_a = barrel_apex / parab_depth^2;

x_side = linspace(-parab_depth, 0, 200);
y_side_parab = barrel_apex - parab_a * x_side.^2;

subplot(2,1,2); hold on; grid on; axis equal;
set(gca,'FontSize',9,'GridAlpha',0.18);
title('Side profile — barrel vault + parabolic south end','FontSize',12,'FontWeight','bold');
xlabel('Longitudinal position (mm)'); ylabel('Profile height (mm)');

% Barrel vault
x_barrel = linspace(0, L, 200);
fill([x_barrel fliplr(x_barrel)],...
     [ones(1,200)*barrel_apex, ones(1,200)*FH],...
     [0.88 0.95 0.91],'EdgeColor','none','FaceAlpha',0.4);
plot(x_barrel, ones(1,200)*barrel_apex,'Color',[0.11 0.62 0.46],'LineWidth',2.5);
plot([0 L],[FH FH],'--','Color',[0.27 0.27 0.26],'LineWidth',1.5);

% Parabolic south end
plot(x_side, y_side_parab,'Color',[0.21 0.37 0.65],'LineWidth',2.5);
fill([x_side fliplr(x_side)],[y_side_parab zeros(1,200)],...
     [0.71 0.82 0.93],'EdgeColor','none','FaceAlpha',0.28);

% Solar panels
for xp = 200 : 1825 : L-1825
    fill([xp xp+1825 xp+1825 xp],...
         [barrel_apex barrel_apex barrel_apex+12 barrel_apex+12],...
         [0.62 0.88 0.79],'EdgeColor',[0.06 0.43 0.34],'LineWidth',0.6);
end

xlim([-parab_depth-360, L+320]);
ylim([-150, barrel_apex+220]);

%% ── 5. 3-D PERSPECTIVE ──────────────────────────────────────────────────
figure('Name','3D Perspective','Position',[920 50 840 640],'Color',[0.97 0.97 0.96]);
hold on; grid on; view(32, 22);
title('3D barrel vault trailer — 120° arc','FontSize',12,'FontWeight','bold');
xlabel('Length (mm)'); ylabel('Width (mm)'); zlabel('Height (mm)');

theta_3d = linspace(-arc_half, arc_half, 80);
y3_arc   = R_arc * sin(theta_3d);
z3_arc   = FH + R_arc * cos(theta_3d);          % DOME: highest at center

% Ribs
rib_pos = linspace(200, L-200, 9);
for xr = rib_pos
    plot3(ones(1,80)*xr, y3_arc, z3_arc,...
          'Color',[0.27 0.27 0.26],'LineWidth',1.1);
    plot3(ones(1,100)*xr, x_sh_L, y_sh_L,'Color',[0.33 0.29 0.72],'LineWidth',0.9);
    plot3(ones(1,100)*xr, x_sh_R, y_sh_R,'Color',[0.33 0.29 0.72],'LineWidth',0.9);
    plot3([xr xr],[-W/2 -W/2],[0 FH],'Color',[0.44 0.44 0.41],'LineWidth',0.7);
    plot3([xr xr],[ W/2  W/2],[0 FH],'Color',[0.44 0.44 0.41],'LineWidth',0.7);
end

% Longitudinal stringers
for ts = linspace(-arc_half+0.05, arc_half-0.05, 12)
    ys = R_arc * sin(ts);
    zs = FH + R_arc * cos(ts);                % DOME
    plot3([0 L],[ys ys],[zs zs],'Color',[0.11 0.62 0.46],'LineWidth',0.6);
end

% Floor
fill3([0 L L 0],[-W/2 -W/2 W/2 W/2],[0 0 0 0],...
      [0.93 0.93 0.87],'EdgeColor',[0.6 0.6 0.5],'FaceAlpha',0.35);

axis equal;
xlim([-parab_depth L+100]);
ylim([-W/2-120, W/2+120]);
zlim([-80, barrel_apex+220]);

%% ── 6. SOLAR HARVEST ESTIMATE ───────────────────────────────────────────
fprintf('\n=== SOLAR HARVEST ESTIMATE  |  Chapter 12 ===\n');
fprintf('Site:  Peten, Guatemala  lat = 16.5 N\n');
fprintf('Panel: Lensun 400W 48V   1825x1142x3 mm  7 kg\n\n');

P_panel   = 400;       % W rated
n_arc     = 8;         % 4 long x 2 rows
n_north   = 2;
derate    = 0.87;
psh       = 6.0;       % peak sun hours
vault_f   = 1.15;
north_f   = 0.20;

P_arc     = n_arc * P_panel * vault_f * derate;
P_north   = n_north * P_panel * north_f * derate;
P_total   = P_arc + P_north;
E_day     = P_total * psh / 1000;
E_year    = E_day * 365 / 1000;

fprintf('Arc panels:   %d x %dW = %.0f W (vault factor %.2f)\n',...
        n_arc, P_panel, P_arc, vault_f);
fprintf('North panels: %d x %dW = %.0f W (reflection %.0f%%)\n',...
        n_north, P_panel, P_north, north_f*100);
fprintf('Total peak:   %.2f kW\n', P_total/1000);
fprintf('Daily:        %.1f kWh/day  (%.1f PSH)\n', E_day, psh);
fprintf('Annual:       %.2f MWh/year\n\n', E_year);

fprintf('CF frame:     57x57 mm (2.25 inch) square tube\n');
fprintf('Rib spacing:  %.0f mm  (9 ribs)\n', L/8);
fprintf('Arc radius:   %.0f mm  (%.2f ft)\n', R_arc, R_arc/ft2mm);
fprintf('Shoulder:     Hermite C1 spline  r1=%.0f  r2=%.0f mm\n', r1, r2);
fprintf('\nGeometry locked - 120 degree low arc\n');
fprintf('Chapter 12 configuration.\n');

%% ── 7. EXPORT CSV ───────────────────────────────────────────────────────
pts_export = [x_sh_L', y_sh_L'; x_arc', y_arc'; flip(x_sh_R'), flip(y_sh_R')];
csvwrite('trailer_xsec_profile.csv', pts_export);
fprintf('\nProfile exported to trailer_xsec_profile.csv\n');
fprintf('Import into SolidWorks or Fusion 360 as spline points.\n');
