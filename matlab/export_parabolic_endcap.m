%% PARABOLIC END CAP — EXPORT FOR CAD & CFD
%  Generates the 3D parabolic venturi end cap surface
%  Exports in multiple formats for Autodesk Inventor and CFD tools
%
%  Outputs:
%    parabolic_endcap.stl      — mesh for Inventor / Fusion 360 / CFD
%    parabolic_endcap_pts.csv  — point cloud (x,y,z) for loft/surface
%    parabolic_endcap_ribs.csv — cross-section curves at stations
%    parabolic_endcap.dxf      — 2D profile for Inventor sketch import
%    full_trailer.stl          — complete trailer body for CFD
%
%  Chapter 12 — The Trailer
% =========================================================================

clear; close all; clc;

%% ── 1. PARAMETERS (must match trailer_geometry.m) ───────────────────────
ft2mm   = 304.8;
W       = 7.5 * ft2mm;     % 2286 mm
L       = 24  * ft2mm;     % 7315 mm
FH      = 4.0 * ft2mm;     % 1219 mm
ARC_DEG = 120;

arc_half = deg2rad(ARC_DEG/2);
R_arc    = (W/2) / sin(arc_half);

% Dome apex
barrel_apex = FH + R_arc * cos(0);   % = FH + R

% Parabola parameters
parab_depth = 600;                    % mm — how far south the parabola extends
parab_a     = barrel_apex / parab_depth^2;

fprintf('=== PARABOLIC END CAP GEOMETRY ===\n');
fprintf('Barrel apex:     %.0f mm  (%.1f ft)\n', barrel_apex, barrel_apex/ft2mm);
fprintf('Parabola depth:  %.0f mm\n', parab_depth);
fprintf('Parabola coeff:  a = %.6f mm^-1\n', parab_a);
fprintf('Focal length:    %.1f mm\n', 1/(4*parab_a));

%% ── 2. GENERATE 3D SURFACE MESH ─────────────────────────────────────────
% The end cap is a "ruled surface" between:
%   - The barrel vault cross-section (arc) at z = 0 (south end of barrel)
%   - A scaled-down version at z = -parab_depth (tip of parabola)
%
% At each longitudinal station z_s:
%   The cross-section is the barrel arc scaled by the parabola profile
%   height_scale = (barrel_apex - parab_a * z_s^2) / barrel_apex

n_long  = 40;    % stations along parabola depth
n_circ  = 60;    % points around cross-section

z_stations = linspace(0, -parab_depth, n_long);  % 0 = barrel junction, negative = south
theta_cs   = linspace(-arc_half, arc_half, n_circ);

% Preallocate mesh
X = zeros(n_long, n_circ);
Y = zeros(n_long, n_circ);
Z = zeros(n_long, n_circ);

for i = 1:n_long
    zs = z_stations(i);
    
    % Parabolic height envelope at this station
    h_env = barrel_apex - parab_a * zs^2;
    h_env = max(h_env, 0);   % clamp to zero
    
    % Scale factor: 1.0 at barrel junction, 0.0 at parabola tip
    scale_f = h_env / barrel_apex;
    
    % Cross-section at this station:
    % Arc from dome formula, scaled vertically
    for j = 1:n_circ
        th = theta_cs(j);
        
        % Full barrel cross-section point
        x_barrel = R_arc * sin(th);
        y_barrel = FH + R_arc * cos(th);
        
        % Scale the profile height above floor
        y_scaled = FH * scale_f + (y_barrel - FH) * scale_f;
        
        % Also narrow the width as we go south
        x_scaled = x_barrel * scale_f;
        
        X(i,j) = zs;         % longitudinal (south)
        Y(i,j) = x_scaled;   % width
        Z(i,j) = y_scaled;   % height
    end
end

% Close the bottom: add floor points
% Left wall descending
for i = 1:n_long
    zs = z_stations(i);
    h_env = max(barrel_apex - parab_a * zs^2, 0);
    scale_f = h_env / barrel_apex;
    
    % Floor width at this station
    floor_hw = (W/2) * scale_f;
end

%% ── 3. VISUALIZE ────────────────────────────────────────────────────────
figure('Name','Parabolic End Cap — 3D Surface','Position',[100 100 900 700]);

% Surface mesh
surf(X, Y, Z, 'FaceColor',[0.71 0.82 0.93],'FaceAlpha',0.6,...
     'EdgeColor',[0.21 0.37 0.65],'EdgeAlpha',0.3);
hold on; grid on; axis equal;
view(35, 25);

% Barrel vault body (wireframe outline)
theta_b = linspace(-arc_half, arc_half, 60);
yb = R_arc * sin(theta_b);
zb = FH + R_arc * cos(theta_b);
for xb_pos = linspace(0, L, 5)
    plot3(ones(1,60)*xb_pos, yb, zb, 'Color',[0.11 0.62 0.46],'LineWidth',0.8);
end

% Floor plane
fill3([0 L L 0 0 -parab_depth -parab_depth 0],...
      [-W/2 -W/2 W/2 W/2 W/2*0 0 0 -W/2*0],...
      [0 0 0 0 0 0 0 0],...
      [0.93 0.93 0.87],'FaceAlpha',0.3,'EdgeColor',[0.6 0.6 0.5]);

title('Parabolic End Cap — 3D Surface for CAD Export','FontSize',13,'FontWeight','bold');
xlabel('Longitudinal (mm) — south'); ylabel('Width (mm)'); zlabel('Height (mm)');
colorbar('off');

% Wind flow arrows
for yw = linspace(-W/4, W/4, 5)
    quiver3(-parab_depth-300, yw, barrel_apex*0.4, 250, 0, 0,...
        'Color',[0.22 0.60 0.85],'LineWidth',1.5,'MaxHeadSize',0.4,...
        'AutoScale','off');
end
text(-parab_depth-350, 0, barrel_apex*0.4, 'canyon breeze',...
     'FontSize',9,'Color',[0.22 0.60 0.85]);

%% ── 4. EXPORT STL (for Inventor / Fusion 360 / CFD) ─────────────────────
fprintf('\n=== EXPORTING CAD FILES ===\n');

% --- 4a. STL via triangulation ---
% Convert surface mesh to triangulated faces
stl_file = 'parabolic_endcap.stl';
fid = fopen(stl_file, 'w');
fprintf(fid, 'solid parabolic_endcap\n');

for i = 1:n_long-1
    for j = 1:n_circ-1
        % Triangle 1: (i,j), (i+1,j), (i+1,j+1)
        v1 = [X(i,j)   Y(i,j)   Z(i,j)];
        v2 = [X(i+1,j) Y(i+1,j) Z(i+1,j)];
        v3 = [X(i+1,j+1) Y(i+1,j+1) Z(i+1,j+1)];
        n = cross(v2-v1, v3-v1);
        n = n / (norm(n) + eps);
        fprintf(fid, '  facet normal %.6e %.6e %.6e\n', n(1), n(2), n(3));
        fprintf(fid, '    outer loop\n');
        fprintf(fid, '      vertex %.4f %.4f %.4f\n', v1(1), v1(2), v1(3));
        fprintf(fid, '      vertex %.4f %.4f %.4f\n', v2(1), v2(2), v2(3));
        fprintf(fid, '      vertex %.4f %.4f %.4f\n', v3(1), v3(2), v3(3));
        fprintf(fid, '    endloop\n');
        fprintf(fid, '  endfacet\n');
        
        % Triangle 2: (i,j), (i+1,j+1), (i,j+1)
        v4 = [X(i,j+1) Y(i,j+1) Z(i,j+1)];
        n = cross(v3-v1, v4-v1);
        n = n / (norm(n) + eps);
        fprintf(fid, '  facet normal %.6e %.6e %.6e\n', n(1), n(2), n(3));
        fprintf(fid, '    outer loop\n');
        fprintf(fid, '      vertex %.4f %.4f %.4f\n', v1(1), v1(2), v1(3));
        fprintf(fid, '      vertex %.4f %.4f %.4f\n', v3(1), v3(2), v3(3));
        fprintf(fid, '      vertex %.4f %.4f %.4f\n', v4(1), v4(2), v4(3));
        fprintf(fid, '    endloop\n');
        fprintf(fid, '  endfacet\n');
    end
end

fprintf(fid, 'endsolid parabolic_endcap\n');
fclose(fid);
fprintf('Exported: %s  (%d triangles)\n', stl_file, 2*(n_long-1)*(n_circ-1));

% --- 4b. Point cloud CSV (for loft in Inventor) ---
pts_file = 'parabolic_endcap_pts.csv';
fid = fopen(pts_file, 'w');
fprintf(fid, 'x_mm,y_mm,z_mm,station,theta_deg\n');
for i = 1:n_long
    for j = 1:n_circ
        fprintf(fid, '%.2f,%.2f,%.2f,%d,%.1f\n',...
            X(i,j), Y(i,j), Z(i,j), i, rad2deg(theta_cs(j)));
    end
end
fclose(fid);
fprintf('Exported: %s  (%d points)\n', pts_file, n_long*n_circ);

% --- 4c. Cross-section ribs CSV (for Inventor loft guide curves) ---
ribs_file = 'parabolic_endcap_ribs.csv';
fid = fopen(ribs_file, 'w');
fprintf(fid, 'station,x_mm,y_mm,z_mm\n');
for i = 1:4:n_long   % every 4th station
    for j = 1:n_circ
        fprintf(fid, '%d,%.2f,%.2f,%.2f\n', i, X(i,j), Y(i,j), Z(i,j));
    end
    fprintf(fid, '\n');  % blank line between stations
end
fclose(fid);
fprintf('Exported: %s  (%d rib stations)\n', ribs_file, ceil(n_long/4));

% --- 4d. 2D Parabola profile DXF (for Inventor sketch) ---
dxf_file = 'parabolic_profile.dxf';
fid = fopen(dxf_file, 'w');

% DXF header
fprintf(fid, '0\nSECTION\n2\nENTITIES\n');

% Parabola centerline profile as POLYLINE
x_prof = linspace(0, -parab_depth, 100);
y_prof = barrel_apex - parab_a * x_prof.^2;

fprintf(fid, '0\nPOLYLINE\n8\nParabola_Profile\n66\n1\n70\n8\n');
for k = 1:length(x_prof)
    fprintf(fid, '0\nVERTEX\n8\nParabola_Profile\n');
    fprintf(fid, '10\n%.4f\n20\n%.4f\n30\n0.0\n', x_prof(k), y_prof(k));
end
fprintf(fid, '0\nSEQEND\n');

% Barrel arc cross-section as POLYLINE
fprintf(fid, '0\nPOLYLINE\n8\nBarrel_Arc\n66\n1\n70\n8\n');
th_dxf = linspace(-arc_half, arc_half, 100);
for k = 1:length(th_dxf)
    xd = R_arc * sin(th_dxf(k));
    yd = FH + R_arc * cos(th_dxf(k));
    fprintf(fid, '0\nVERTEX\n8\nBarrel_Arc\n');
    fprintf(fid, '10\n%.4f\n20\n%.4f\n30\n0.0\n', xd, yd);
end
fprintf(fid, '0\nSEQEND\n');

% Wall lines
fprintf(fid, '0\nLINE\n8\nWall_Left\n');
fprintf(fid, '10\n%.4f\n20\n0.0\n30\n0.0\n', -W/2);
fprintf(fid, '11\n%.4f\n21\n%.4f\n31\n0.0\n', -W/2, FH);

fprintf(fid, '0\nLINE\n8\nWall_Right\n');
fprintf(fid, '10\n%.4f\n20\n0.0\n30\n0.0\n', W/2);
fprintf(fid, '11\n%.4f\n21\n%.4f\n31\n0.0\n', W/2, FH);

fprintf(fid, '0\nENDSEC\n0\nEOF\n');
fclose(fid);
fprintf('Exported: %s\n', dxf_file);

%% ── 5. FULL TRAILER STL (for CFD) ───────────────────────────────────────
% Complete closed body: barrel vault + parabolic end + flat north end + floor
full_stl = 'full_trailer.stl';
fid = fopen(full_stl, 'w');
fprintf(fid, 'solid full_trailer\n');

% Helper: write one triangle
write_tri = @(f, v1, v2, v3) deal(...
    fprintf(f, '  facet normal %.6e %.6e %.6e\n', ...
        cross(v2-v1,v3-v1)/max(norm(cross(v2-v1,v3-v1)),eps)),...
    fprintf(f, '    outer loop\n'),...
    fprintf(f, '      vertex %.4f %.4f %.4f\n', v1),...
    fprintf(f, '      vertex %.4f %.4f %.4f\n', v2),...
    fprintf(f, '      vertex %.4f %.4f %.4f\n', v3),...
    fprintf(f, '    endloop\n  endfacet\n'));

n_body  = 60;   % circumferential resolution
n_len   = 20;   % barrel length divisions

% Barrel vault body
theta_body = linspace(-arc_half, arc_half, n_body);
x_len      = linspace(0, L, n_len);

tri_count = 0;
for i = 1:n_len-1
    for j = 1:n_body-1
        % Vault surface points
        yA = R_arc*sin(theta_body(j));   zA = FH + R_arc*cos(theta_body(j));
        yB = R_arc*sin(theta_body(j+1)); zB = FH + R_arc*cos(theta_body(j+1));
        
        v1 = [x_len(i),   yA, zA];
        v2 = [x_len(i+1), yA, zA];
        v3 = [x_len(i+1), yB, zB];
        v4 = [x_len(i),   yB, zB];
        
        % Triangle 1
        nn = cross(v2-v1, v3-v1); nn = nn/max(norm(nn),eps);
        fprintf(fid, '  facet normal %.6e %.6e %.6e\n', nn);
        fprintf(fid, '    outer loop\n');
        fprintf(fid, '      vertex %.4f %.4f %.4f\n', v1);
        fprintf(fid, '      vertex %.4f %.4f %.4f\n', v2);
        fprintf(fid, '      vertex %.4f %.4f %.4f\n', v3);
        fprintf(fid, '    endloop\n  endfacet\n');
        
        % Triangle 2
        nn = cross(v3-v1, v4-v1); nn = nn/max(norm(nn),eps);
        fprintf(fid, '  facet normal %.6e %.6e %.6e\n', nn);
        fprintf(fid, '    outer loop\n');
        fprintf(fid, '      vertex %.4f %.4f %.4f\n', v1);
        fprintf(fid, '      vertex %.4f %.4f %.4f\n', v3);
        fprintf(fid, '      vertex %.4f %.4f %.4f\n', v4);
        fprintf(fid, '    endloop\n  endfacet\n');
        
        tri_count = tri_count + 2;
    end
end

% Left wall
for i = 1:n_len-1
    v1 = [x_len(i),   -W/2, 0];
    v2 = [x_len(i+1), -W/2, 0];
    v3 = [x_len(i+1), -W/2, FH];
    v4 = [x_len(i),   -W/2, FH];
    nn = cross(v2-v1,v3-v1); nn=nn/max(norm(nn),eps);
    fprintf(fid,'  facet normal %.6e %.6e %.6e\n',nn);
    fprintf(fid,'    outer loop\n');
    fprintf(fid,'      vertex %.4f %.4f %.4f\n',v1);
    fprintf(fid,'      vertex %.4f %.4f %.4f\n',v2);
    fprintf(fid,'      vertex %.4f %.4f %.4f\n',v3);
    fprintf(fid,'    endloop\n  endfacet\n');
    nn = cross(v3-v1,v4-v1); nn=nn/max(norm(nn),eps);
    fprintf(fid,'  facet normal %.6e %.6e %.6e\n',nn);
    fprintf(fid,'    outer loop\n');
    fprintf(fid,'      vertex %.4f %.4f %.4f\n',v1);
    fprintf(fid,'      vertex %.4f %.4f %.4f\n',v3);
    fprintf(fid,'      vertex %.4f %.4f %.4f\n',v4);
    fprintf(fid,'    endloop\n  endfacet\n');
    tri_count = tri_count + 2;
end

% Right wall
for i = 1:n_len-1
    v1 = [x_len(i),   W/2, 0];
    v2 = [x_len(i+1), W/2, 0];
    v3 = [x_len(i+1), W/2, FH];
    v4 = [x_len(i),   W/2, FH];
    nn = cross(v2-v1,v3-v1); nn=nn/max(norm(nn),eps);
    fprintf(fid,'  facet normal %.6e %.6e %.6e\n',nn);
    fprintf(fid,'    outer loop\n');
    fprintf(fid,'      vertex %.4f %.4f %.4f\n',v1);
    fprintf(fid,'      vertex %.4f %.4f %.4f\n',v2);
    fprintf(fid,'      vertex %.4f %.4f %.4f\n',v3);
    fprintf(fid,'    endloop\n  endfacet\n');
    nn = cross(v3-v1,v4-v1); nn=nn/max(norm(nn),eps);
    fprintf(fid,'  facet normal %.6e %.6e %.6e\n',nn);
    fprintf(fid,'    outer loop\n');
    fprintf(fid,'      vertex %.4f %.4f %.4f\n',v1);
    fprintf(fid,'      vertex %.4f %.4f %.4f\n',v3);
    fprintf(fid,'      vertex %.4f %.4f %.4f\n',v4);
    fprintf(fid,'    endloop\n  endfacet\n');
    tri_count = tri_count + 2;
end

% Parabolic end cap (reuse surface mesh from section 2)
for i = 1:n_long-1
    for j = 1:n_circ-1
        v1 = [X(i,j)     Y(i,j)     Z(i,j)];
        v2 = [X(i+1,j)   Y(i+1,j)   Z(i+1,j)];
        v3 = [X(i+1,j+1) Y(i+1,j+1) Z(i+1,j+1)];
        v4 = [X(i,j+1)   Y(i,j+1)   Z(i,j+1)];
        nn = cross(v2-v1,v3-v1); nn=nn/max(norm(nn),eps);
        fprintf(fid,'  facet normal %.6e %.6e %.6e\n',nn);
        fprintf(fid,'    outer loop\n');
        fprintf(fid,'      vertex %.4f %.4f %.4f\n',v1);
        fprintf(fid,'      vertex %.4f %.4f %.4f\n',v2);
        fprintf(fid,'      vertex %.4f %.4f %.4f\n',v3);
        fprintf(fid,'    endloop\n  endfacet\n');
        nn = cross(v3-v1,v4-v1); nn=nn/max(norm(nn),eps);
        fprintf(fid,'  facet normal %.6e %.6e %.6e\n',nn);
        fprintf(fid,'    outer loop\n');
        fprintf(fid,'      vertex %.4f %.4f %.4f\n',v1);
        fprintf(fid,'      vertex %.4f %.4f %.4f\n',v3);
        fprintf(fid,'      vertex %.4f %.4f %.4f\n',v4);
        fprintf(fid,'    endloop\n  endfacet\n');
        tri_count = tri_count + 2;
    end
end

fprintf(fid, 'endsolid full_trailer\n');
fclose(fid);
fprintf('Exported: %s  (%d triangles)\n', full_stl, tri_count);

%% ── 6. SUMMARY ──────────────────────────────────────────────────────────
fprintf('\n=== EXPORT SUMMARY ===\n');
fprintf('Files created:\n');
fprintf('  parabolic_endcap.stl       — end cap mesh for Inventor/Fusion\n');
fprintf('  parabolic_endcap_pts.csv   — point cloud for loft surface\n');
fprintf('  parabolic_endcap_ribs.csv  — rib cross-sections for guide curves\n');
fprintf('  parabolic_profile.dxf      — 2D profile for Inventor sketch\n');
fprintf('  full_trailer.stl           — complete body for CFD import\n');
fprintf('\n');
fprintf('=== IMPORT INTO AUTODESK INVENTOR ===\n');
fprintf('Option A (STL): Insert > Import > parabolic_endcap.stl\n');
fprintf('         Convert mesh to BRep: Mesh > Convert to BRep\n');
fprintf('Option B (Loft): New Part > 3D Sketch > Import Points (CSV)\n');
fprintf('         Create splines through rib points, then Loft\n');
fprintf('Option C (DXF): New Sketch > Import DXF > parabolic_profile.dxf\n');
fprintf('         Revolve or sweep the profile\n');
fprintf('\n');
fprintf('=== CFD AIRFLOW MODELING ===\n');
fprintf('Import full_trailer.stl into:\n');
fprintf('  - Autodesk CFD (built into Inventor Professional)\n');
fprintf('  - ANSYS Fluent / CFX\n');
fprintf('  - OpenFOAM (free, open source)\n');
fprintf('  - SimScale (cloud-based, free tier)\n');
fprintf('  - COMSOL Multiphysics\n');
fprintf('\nRecommended boundary conditions:\n');
fprintf('  Inlet:  canyon breeze 2-5 m/s from south\n');
fprintf('  Outlet: open boundary (north end)\n');
fprintf('  Walls:  no-slip on trailer surfaces\n');
fprintf('  Domain: 5x trailer length upstream, 10x downstream\n');
