% Purpose: Extract Central European spatial patterns of all ten circulation
%          types during the four seasons for the two time periods (past) 1988-2017
%          and future (2070-2099) in the CMIP5 ensembles which have the
%          data available
%          -> data is prepared beforehand with: preprocessing_cmip5_maps_data.py
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
%                                                                                               #
% Project:  Practicum MeteoSwiss/ETH Zurich                                                     #
%           Frequency and Persistence of Central European Circulation Types                     #
% My Name:  Maurice Huguenin-Virchaux                                                           #
% My Email: hmaurice@student.ethz.ch                                                            #
% Date:     20.02.2019, 10:47 CET                                                               #
%                                                                                               #
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
season = 1; % indicate which season to plot: spring (1), summer (2), autumn (3) or winter (4)
m = 23; % [max = 23] number of ensemble members to consider here
circulation_types = [1:10];



% preamble and data preparation
tic;

% preliminary file to load in longitude and latitude values
f1 = ['zg_day_ACCESS1-0_r1i1p1_1988-2017.nc'];

% path_names
p1 = '/net/h2o/climphys/hmaurice/Practicum_meteoswiss_output/cost/';
p2 = '/net/h2o/climphys/hmaurice/Practicum_meteoswiss_output/patterns/cmip5_data_for_spatial_maps/';
p3 = '/net/h2o/climphys/hmaurice/Practicum_meteoswiss_output/patterns/cmip5_spatial_maps_figures/';

% add path to matlab packages and functions
addpath(genpath('/net/h2o/climphys1/hmaurice/NOAA_SSTa_1991_2018/matlab_packages_and_functions')); % add path with subfolders that

% define colours
RdBu_short = cbrewer('div', 'RdBu', 20, 'PCHIP');
RdYlGn_short = cbrewer('div', 'RdYlGn', 20, 'PCHIP'); 
% BrBG_short = cbrewer('div', 'BrBG', 20, 'PCHIP'); 
% RdYlGn_short(1:10,:) = BrBG_short(1:10,:);
Greens_short = cbrewer('seq', 'Greens', 20, 'PCHIP');
%BuGn_short = cbrewer('seq', 'BuGn', 20, 'PCHIP');
BrBG_short = cbrewer('div','BrBG', 20, 'PCHIP')
purple = [160, 0, 160]*1/255;
YlGn_short = cbrewer('seq', 'YlGn', 20, 'PCHIP'); 
% antarctica colourbar -> load in RGB values and divide by 255
antarctica =    [150,   0,  17; 165,   0,  33; 200,   0,  40; ...
                 216,  21,  47; 247,  39,  53; 255,  61,  61; ...
                 255, 120,  86; 255, 172, 117; 255, 214, 153; ...
                 255, 241, 188; 255, 255, 255; 188, 249, 255; ...
                 153, 234, 255; 117, 211, 255;  86, 176, 255; ...
                  61, 135, 255;  40,  87, 255;  24,  28, 247; ...
                  30,   0, 230;  36,   0, 216;  45,   0, 200]*1./255;
a = [146,81,32;
    166,104,36;
    191,133,60;
    237,209,137;
    253,247,193;
    223,234,203;
    187,213,170;
    96,132,163;
    60,91,124;
    42,57,86]*1/255;              
% interpolate antarctica colourbar to 20 colours
antarctica_hres = nan(20,3); precip_diff = nan(20,3);
precip_short = nan(20,3);
for i = 1:3 % antarctica colour bar
   antarctica_hres(:,i) = interp1(1:21, antarctica(:,i), ...
                      linspace(1, 21, 20), 'linear');
   BuGn_short(:,i) = interp1(1:10, BrBG_short(11:20,i), ...
                      linspace(1, 10, 20), 'linear');
end
clear antarctica i a; 
antarctica = antarctica_hres; clear antarctica_hres;
green = [0, 134, 0]*1/255;



lon = getnc([p2 f1], 'longitude'); % load in longitude and latitude values
lat = getnc([p2 f1], 'latitude');  % as I remapped to a 1x1 degree grid they are
                                   % the same now for all CMIP5 ensemble members
[lat, lon]  = meshgrid(lat, lon); % create meshgrid



% CMIP5 model list
model = {'ACCESS1-0_r1i1p1', 'ACCESS1-3_r1i1p1', 'CMCC-CM_r1i1p1', 'CMCC-CMS_r1i1p1', ...
    'CNRM-CM5_r1i1p1', 'MPI-ESM-LR_r1i1p1', 'MPI-ESM-LR_r2i1p1', 'MPI-ESM-LR_r3i1p1', ...
    'MRI-CGCM3_r1i1p1', 'MRI-ESM1_r1i1p1', ... % these models above here have a leap day  -> i.e. the first 10 
    'BNU-ESM_r1i1p1', 'CanESM2_r2i1p1', 'CanESM2_r3i1p1', 'CanESM2_r4i1p1', ... % these models down here have no leap day  -> i.e. the last 13
    'FGOALS-g2_r1i1p1', 'GFDL-CM3_r1i1p1', 'GFDL-ESM2G_r1i1p1', 'GFDL-ESM2M_r1i1p1', ...
    'IPSL-CM5A-LR_r1i1p1', 'IPSL-CM5A-LR_r3i1p1', 'IPSL-CM5A-MR_r1i1p1', ...
    'IPSL-CM5B-LR_r1i1p1', 'NorESM1-M_r1i1p1'};

    
% initiate empty data frame which gets filled up for each circulation type
% each season
domain_temperature_past = zeros(10,m+1); domain_temperature_past(:,1) = 1:10;
% copy-paste data frame structure for precipitation and CH region (Switzerland)
domain_temperature_future = domain_temperature_past;
domain_precipitation_past = domain_temperature_past;
domain_precipitation_future = domain_temperature_past;

% ch_temperature_past = domain_temperature_past;
% ch_temperature_future = domain_temperature_past;
% ch_precipitation_past = domain_temperature_past;
% ch_precipitation_future = domain_temperature_past;

Z500_past = nan([size(lat),m]); T_past = nan([size(lat),m]);
slp_past = nan([size(lat),m]); pr_past = nan([size(lat),m]);
    Z500_future = Z500_past; T_future = T_past; % copy-paste data frame structure
    slp_future = slp_past; pr_future = pr_past;

% the data structure looks like this:
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% circulation type | spring | summer | autumn | winter %
%       ...           ...      ...       ...     ...   %
%       ...           ...      ...       ...     ...   %
%       ...           ...      ...       ...     ...   %
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% (oh gosh, this is painful in matlab :D)

toc;
clear day green month year purple;


% loop over all subplots and plotting routine
for s = season % loop over the summer (2) and winter (4) season
    %dat_circ = dat_circ(1:51100,:); % remove NA data entries
    for i = circulation_types % loop over all circulation types
        tic;
        for period = 1:2
            % read in classification time series
            dat_circ_leap = table2array(readtable([p1 ...
                'cost_CMIP5_historical_rcp85_1960-2099_Z500.dat'])); 
            dat_circ_no_leap = table2array(readtable([p1 ...
                'cost_CMIP5_historical_rcp85_1960-2099_Z500_no_leap_days.dat'])); 
            if period == 1
                % select past period: 01-01-1988 - 31-12-2017    % select future period: 01-01-2070 - 31-12-2099
                dat_circ_leap = dat_circ_leap(10228:21185,:); 
                dat_circ_no_leap = dat_circ_no_leap(10221:21170,:);
            elseif period == 2
                % select future period: 01-01-2070 - 31-12-2099
                dat_circ_leap = dat_circ_leap(40179:51135,:);
                dat_circ_no_leap = dat_circ_no_leap(40151:51100,:);
            end

            % add another data column with an index which goes from 1:length of array
            year = dat_circ_leap(:,1); month = dat_circ_leap(:,2); day = dat_circ_leap(:,3);
            dat_circ_leap(:,14) = 1:length(dat_circ_leap); % 88th column = index
                
            year = dat_circ_no_leap(:,1); month = dat_circ_no_leap(:,2); day = dat_circ_no_leap(:,3);
            dat_circ_no_leap(:,17) = 1:length(dat_circ_no_leap); % 88th column = index
            % I have 9 (with leap days) + 13 (without leap days) = 21 ensemble members 

            % replace values for month with seasonal values, i.e.
            % spring = 1, summer = 2, autumn = 4 and winter = 4

            % winter -> insert index 41 (which gets afterwards replaced with 4)
            dat_circ_leap(dat_circ_leap(:,2)==12 | dat_circ_leap(:,2)==1 | dat_circ_leap(:,2)==2, 2)= 41; 
            dat_circ_no_leap(dat_circ_no_leap(:,2)==12 | dat_circ_no_leap(:,2)==1 | dat_circ_no_leap(:,2)==2, 2)= 41; 
            % spring -> insert index 2
            dat_circ_leap(dat_circ_leap(:,2)==3 | dat_circ_leap(:,2)==4 | dat_circ_leap(:,2)==5, 2)= 1;
            dat_circ_no_leap(dat_circ_no_leap(:,2)==3 | dat_circ_no_leap(:,2)==4 | dat_circ_no_leap(:,2)==5, 2)= 1;
            % summer -> insert index 3
            dat_circ_leap(dat_circ_leap(:,2)==6 | dat_circ_leap(:,2)==7 | dat_circ_leap(:,2)==8, 2)= 2;
            dat_circ_no_leap(dat_circ_no_leap(:,2)==6 | dat_circ_no_leap(:,2)==7 | dat_circ_no_leap(:,2)==8, 2)= 2;
            % autumn -> insert index 4
            dat_circ_leap(dat_circ_leap(:,2)==9 | dat_circ_leap(:,2)==10 | dat_circ_leap(:,2)==11, 2)= 3;
            dat_circ_no_leap(dat_circ_no_leap(:,2)==9 | dat_circ_no_leap(:,2)==10 | dat_circ_no_leap(:,2)==11, 2)= 3;


            dat_circ_leap(dat_circ_leap(:,2)==41, 2)= 4; % workaround as I replace 1 (JAN) with 4 (Winter)
            dat_circ_no_leap(dat_circ_no_leap(:,2)==41, 2)= 4; % workaround as I replace 1 (JAN) with 4 (Winter)


                Z500_mean = nan(61,51,m);
                T_mean = nan(61,51,m); 
                slp_mean = nan(61,51,m); 
                pr_mean = nan(61,51,m); 
                tic;
                for e = 1:m % loop over all ensemble members
                    if e <= 10
                        dat_circ = dat_circ_leap;
                    elseif e == 15
                        continue % data for the 15th ensemble member (CNRM-CM5) and 
                                 % not available
                    elseif e > 10
                        dat_circ = dat_circ_no_leap;
                    end
                    
                    % filename for this particular ensemble member
                    if period == 1
                        f1 = ['zg_day_' char(model(e)) '_1988-2017.nc'];
                        f2 = ['tas_day_' char(model(e)) '_1988-2017.nc'];
                        f3 = ['psl_day_' char(model(e)) '_1988-2017.nc'];
                        f4 = ['pr_day_' char(model(e)) '_1988-2017.nc'];
                    elseif period == 2
                        f1 = ['zg_day_' char(model(e)) '_2070-2099.nc'];
                        f2 = ['tas_day_' char(model(e)) '_2070-2099.nc'];
                        f3 = ['psl_day_' char(model(e)) '_2070-2099.nc'];
                        f4 = ['pr_day_' char(model(e)) '_2070-2099.nc'];
                    end
                    % find index of all those circulation types which are exactly in season s and of type i    
                    %                 +4 as the first three columns = date (year, month, day)
                    if e <= 10
                        ind = dat_circ(:,e+3) == i & dat_circ(:,2) == s;
                    elseif e > 10
                        ind = dat_circ(:,e-10+3) == i & dat_circ(:,2) == s;
                    end
                    A1 = dat_circ(ind,end); % A = [1, 6, 10, 11, ...]
                                          % i.e. the 1st, 6th, 10th, 11th, ... day have all
                                          % a West (W) circulation since that one has the
                                          % index 1
                                          if isempty(A1) == 1 % skip ensemble/iteration if that
                                              continue       % circulation type does not occur
                                          end
        % plot 1: geopotential height contours
                    Z500 = squeeze(permute(getnc([p2 f1], 'zg'), [4 3 2 1]));
                    % select only days with specific circulation types and
                    % calculate mean over this single ensemble
                    Z500 = squeeze(nanmean(Z500(:,:,A1),3)); 
        % plot 1: temperature anomaly map
                    T = squeeze(permute(getnc([p2 f2], 'tas'), [4 3 2 1])); 
                    T = squeeze(nanmean(T(:,:,A1),3));
        % plot 2: sea level pressure contours
                    slp = squeeze(permute(getnc([p2 f3], 'psl'), [4 3 2 1])); 
                    slp = squeeze(nanmean(slp(:,:,A1),3));
        % plot 2: precipitation colour map
                    pr = squeeze(permute(getnc([p2 f4], 'pr'), [4 3 2 1])); 
                    pr = squeeze(nanmean(pr(:,:,A1),3));
                
                    % convert precipitation from [kg m^-2 s^-1] to [mm day^-1]               
                    % by dividing by the density of water and multiplying by seconds            
                    % per day
                    pr = pr * 86400; 

                if period == 1
                    Z500_past(:,:,e) = Z500;
                    T_past(:,:,e) = T;
                    slp_past(:,:,e) = slp;
                    pr_past(:,:,e) = pr;
                    % insert mean values over the Central European Domain into
                    domain_temperature_past(i,e+1) = round(squeeze(nanmean(squeeze(nanmean(T(24:41,29:40))))),2);
                    domain_precipitation_past(i,e+1) = round(squeeze(nanmean(squeeze(nanmean(pr(24:41,29:40))))),2);

%                    ch_temperature_past(i,e+1) = round(squeeze(nanmean(squeeze(nanmean(T(27:32,33:35))))),2);
%                    ch_precipitation_past(i,e+1) = round(squeeze(nanmean(squeeze(nanmean(pr(27:32,33:35))))),2);
                elseif period == 2
                    Z500_future(:,:,e) = Z500;
                    T_future(:,:,e) = T;
                    slp_future(:,:,e) = slp;
                    pr_future(:,:,e) = pr;
                    domain_temperature_future(i,e+1) = round(squeeze(nanmean(squeeze(nanmean(T(24:41,29:40))))),2);
                    domain_precipitation_future(i,e+1) = round(squeeze(nanmean(squeeze(nanmean(pr(24:41,29:40))))),2);
                    
%                    ch_temperature_future(i,e+1) = round(squeeze(nanmean(squeeze(nanmean(T(27:32,33:35))))),2);
%                    ch_precipitation_future(i,e+1) = round(squeeze(nanmean(squeeze(nanmean(pr(27:32,33:35))))),2);
                end
                
                end
                
        end % end of loop over past (1) and future (2) period
                   
        % calculate mean over all ensembles
                % first change in each individual ensemble, then mean of all the changes for
                % the difference between past and future
                Z500_difference = squeeze(nanmean(Z500_future - Z500_past,3));
                % then calculate the mean of the past and future period for
                % all ensembles separately
                Z500_past = squeeze(nanmean(Z500_past,3));
                Z500_future = squeeze(nanmean(Z500_future,3));
                
                T_difference = squeeze(nanmean(T_future - T_past,3));
                T_past = squeeze(nanmean(T_past,3));
                T_future = squeeze(nanmean(T_future,3));

                slp_difference = squeeze(nanmean(slp_future - slp_past,3));
                slp_past = squeeze(nanmean(slp_past,3));
                slp_future = squeeze(nanmean(slp_future,3));

                pr_difference = squeeze(nanmean(pr_future - pr_past,3));
                pr_past = squeeze(nanmean(pr_past,3));
                pr_future = squeeze(nanmean(pr_future,3));
                

                domain_temperature_difference = domain_temperature_future-domain_temperature_past;
                % calculate difference in values of [%]
                domain_precipitation_difference = domain_precipitation_future ./ (domain_precipitation_past ./ 100) + 100 * -1;
%                ch_temperature_difference = ch_temperature_future-ch_temperature_past;
%                ch_precipitation_difference = ch_precipitation_future-ch_precipitation_past;

                % again retype circulation type number in the first column,
                % i.e. 1:10 which got messed up when I took the difference
                % above
                domain_temperature_difference(:,1) = 1:10;
                domain_precipitation_difference(:,1) = 1:10;
                % clean up workspace for plotting
                clearvars -except Z500_past T_past slp_past pr_past ...
                      domain_temperature_past domain_precipitation_past ...
                      ch_temperature_past ch_precipitation_past ...
                      Z500_future T_future slp_future pr_future ...
                      domain_temperature_future domain_precipitation_future ...
                      ch_temperature_future ch_precipitation_future ...
                      Z500_difference T_difference slp_difference pr_difference ...
                      domain_temperature_difference domain_precipitation_difference ...              
                      ch_temperature_difference ch_precipitation_difference ...              
                      RdBu_short YlGn_short p3 season lon lat model i season ...
                      period s p1 p2 p3 m RdYlGn_short precip_diff precip_short ...
                      BuGn_short BrBG_short
                % ~~~~~~ here comes the plotting routine ~~~~
                % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        for f = 1:6 % data preparation for the two subplots
        if f == 1
            map_contour = Z500_past;
            map_colour = T_past;
            colour_map = RdBu_short;
            limits = [-12 12];
            colour_label = '[\circC]';
            path = [p3 'season_' num2str(s) '/period_1/CMIP5_geopotential_height_pattern_season_' ...
            num2str(s) '_type_' num2str(i) '_plot_' num2str(f) '_period_1'];
            domain_value_temperature = [num2str(round(nanmean(domain_temperature_past(i,2:end)),2)) ' °C'];
%            ch_value_temperature = [num2str(round(mean(ch_temperature_past(i,2:end)),2)) ' °C'];
        elseif f == 2
%            map_contour = slp_past/100; % plot in [hPa]
            map_colour = pr_past;
            colour_map = flipud(BuGn_short);
            limits = [0 10];
            colour_label = '[mm / day]';
            path = [p3 'season_' num2str(s) '/period_1/CMIP5_geopotential_height_pattern_season_' ...
            num2str(s) '_type_' num2str(i) '_plot_' num2str(f) '_period_1'];
            domain_value_precipitation = [num2str(round(nanmean(domain_precipitation_past(i,2:end)),2)) 'mm day⁻¹'];
%            ch_value_precipitation = [num2str(round(mean(ch_precipitation_past(i,2:end)),2)) 'mm day⁻¹'];
        elseif f == 3
            map_contour = Z500_future;
            map_colour = T_future;
            colour_map = RdBu_short;
            limits = [-12 12];
            colour_label = '[\circC]';
            path = [p3 'season_' num2str(s) '/period_2/CMIP5_geopotential_height_pattern_season_' ...
            num2str(s) '_type_' num2str(i) '_plot_' num2str(f) '_period_2'];
            domain_value_temperature = [num2str(round(nanmean(domain_temperature_future(i,2:end)),2)) ' °C'];
%            ch_value_temperature = [num2str(round(mean(ch_temperature_future(i,2:end)),2)) ' °C'];
        elseif f == 4
%            map_contour = slp_future/100;
            map_colour = pr_future;
            colour_map = flipud(BuGn_short);
            limits = [0 10];
            colour_label = '[mm / day]';
            path = [p3 'season_' num2str(s) '/period_2/CMIP5_geopotential_height_pattern_season_' ...
            num2str(s) '_type_' num2str(i) '_plot_' num2str(f) '_period_2'];
            domain_value_precipitation = [num2str(round(nanmean(domain_precipitation_future(i,2:end)),2)) ' mm day⁻¹'];
%            ch_value_precipitation = [num2str(round(mean(ch_precipitation_future(i,2:end)),2)) ' mm day⁻¹'];
        elseif f == 5
%            map_contour = Z500_difference;
            map_colour = T_difference;
            colour_map = RdBu_short;
            limits = [-12 12];
            colour_label = '[\circC]';
            path = [p3 'season_' num2str(s) '/differences/CMIP5_geopotential_height_pattern_season_' ...
            num2str(s) '_type_' num2str(i) '_plot_' num2str(f)];
            domain_value_temperature = [num2str(round(nanmean(domain_temperature_difference(i,2:end)),2)) ' °C'];
%            ch_value_temperature = [num2str(round(mean(ch_temperature_difference(i,2:end)),2)) ' °C'];
        elseif f == 6
%            map_contour = slp_difference/100;
            map_colour = pr_difference;
            colour_map = flipud(BrBG_short);
            limits = [-5 5];
            colour_label = '[%]';
            path = [p3 'season_' num2str(s) '/differences/CMIP5_geopotential_height_pattern_season_' ...
            num2str(s) '_type_' num2str(i) '_plot_' num2str(f)];
            domain_value_precipitation = [num2str(round(nanmean(domain_precipitation_difference(i,2:end)),2)) ' %'];
%            ch_value_precipitation = [num2str(round(mean(ch_precipitation_difference(i,2:end)),2)) ' mm day⁻¹'];
        end

            figure(f)
                % plotting routine
            labels_1 = {'a) West', 'c) Southwest', 'e) Northwest', 'g) North', ...
                    'i) Northeast', 'l) East', 'n) Southeast', 'p) South', ...
                    'r) Cyclonic', 't) Anticyclonic'};
            labels_2 = {'b) West', 'd) Southwest', 'f) Northwest', 'h) North', ...
                    'k) Northeast', 'm) East', 'o) Southeast', 'q) South', ...
                    's) Cyclonic', 'u) Anticyclonic'};


            %figure('Visible','on'); % keep figure from popping up
            % set(0, 'DefaultFigureRenderer', 'OpenGL') % also tried 'zbuffer' and 'painters' 
            colormap(flipud(colour_map));
            m_proj('equidistant cylindrical','lat', [30  70], 'lon',[-20 40]);
            m_coast('color',[0.5 0.5 0.5], 'linewidth', 1.2); % black coastline
            m_grid('box', 'on', 'xtick', 5, 'ytick', 5, 'tickdir', 'in', ...
                'yaxislocation', 'left',  ...
                'Fontsize', 17, 'color', 'k', 'linewidth', .5);

            h=m_pcolor(lon    , lat, map_colour); set(h,'linestyle','none'); hold on;
            h=m_pcolor(lon+359, lat, map_colour); set(h,'linestyle','none'); hold on;
            %[cs2, h2] = m_contour(lon, lat, pr_mean, [1,2,4,6,8], ...
            %    'linewidth', 1.2, 'color', [214, 0, 214]*1/255);
            %clabel(cs2, h2, 'fontsize', 17, 'color', [214, 0, 214]*1/255,'LabelSpacing', 85);
            shading interp

            if f == 1 | f == 3 | f == 5
            [cs, h] = m_contour(lon, lat, map_contour, 'color', 'k', 'linewidth', 1.2);
            clabel(cs,h,'fontsize',16, 'color', 'k');
            end
            
            m_coast('color',[.5 .5 .5], 'linewidth', 1.75); % black coastline

            m_grid('box', 'on', 'xtick', 5, 'ytick', 5, 'tickdir', 'in', ...
                'yaxislocation', 'left',  ...
                'Fontsize', 17, 'color', 'k', 'linewidth', .5);

            m_line([3, 3],[41, 52],'color', RdBu_short(end,:), 'linewidth', 1.2); % m_line([lat],[lon])
            m_line([20, 20], [41, 52], 'color', RdBu_short(end,:), 'linewidth', 1.2); % m_line([lat],[lon])
            m_line([3, 20],[41, 41], 'color', RdBu_short(end,:), 'linewidth', 1.2); % m_line([lat],[lon])
            m_line([3, 20],[52, 52], 'color', RdBu_short(end,:), 'linewidth', 1.2); % m_line([lat],[lon])
            
%            m_line([6, 6],[46, 48],'color', RdBu_short(end,:), 'linewidth', 1.2); % m_line([lat],[lon])
%            m_line([10, 10], [46, 48], 'color', RdBu_short(end,:), 'linewidth', 1.2); % m_line([lat],[lon])
%            m_line([6, 10],[46, 46], 'color', RdBu_short(end,:), 'linewidth', 1.2); % m_line([lat],[lon])
%            m_line([6, 10],[48, 48], 'color', RdBu_short(end,:), 'linewidth', 1.2); % m_line([lat],[lon])


            h3 = colorbar('color', 'k', 'box', 'on', 'tickdirection', 'in', ...
            'Fontsize', 17, 'location', 'southoutside');
            h = ylabel(h3, colour_label, 'color', 'k', 'Fontsize', 17);
            set(h3, 'YTick', linspace(limits(1), limits(2), 5)); % set colourbar limit
            set(gca, 'clim', [limits(1) limits(2)]); hold on; % set colour limit

            %h5 = m_text(5, 43, 'D06', 'Fontsize', 25);
            %f1 = ['a) West (W)']
            %h4 = title(labels(i));
            if f == 1 || f == 3 || f == 5
                m_text(-20, 72.3, labels_1(i), 'color', 'k', 'fontsize', 19);
%                m_text(40, 71.5, [domain_value_temperature], ...
%                    'color', 'k', 'fontsize', 12, 'horizontalAlignment', 'right');
%            m_text(-18,33,['CH: ', ch_value_temperature],'fontsize',12,'color','k',...
%            'vertical','middle','horizontal','center', 'backgroundcolor', 'w', ...
%            'horizontalAlignment', 'left');
            m_text(-18,33,['CE: ', domain_value_temperature],'fontsize',12,'color','k',...
            'vertical','middle','horizontal','center', 'backgroundcolor', 'w', ...
            'horizontalAlignment', 'left');

            elseif f == 2 || f == 4 || f == 6
                m_text(-20, 72.3, labels_2(i), 'color', 'k', 'fontsize', 19);
%                m_text(40, 71.5, [domain_value_precipitation], ...
%                   'color', 'k', 'fontsize', 12, 'horizontalAlignment', 'right');
%            m_text(-18,33,['CH: ', ch_value_precipitation],'fontsize',12,'color','k',...
%            'vertical','middle','horizontal','center', 'backgroundcolor', 'w', ...
%            'horizontalAlignment', 'left');
            m_text(-18,33,['CE: ', domain_value_precipitation],'fontsize',12,'color','k',...
            'vertical','middle','horizontal','center', 'backgroundcolor', 'w', ...
            'horizontalAlignment', 'left');

            end
            % printing
            set(gcf, 'color', 'w', 'PaperPositionMode', 'auto');
            print('-dpng','-r300', path);
        boom; % close figure
        end % end over all subplots
        toc;
    end % end over the ten circulation types



end % end of loop over all four seasons: spring (1), summer (2), autumn (3) and winter (4)

% save change in temperature and precipitation as workspaces for use in
% summary figure Fig. 4 of my manuscript

path2 = '/net/h2o/climphys/hmaurice/Practicum_meteoswiss_output/patterns/';
save([path2 'domain_temp_diff_cmip5_season_' num2str(season) '.txt'],'domain_temperature_difference','-ascii')
save([path2 'domain_precip_diff_cmip5_season_' num2str(season) '.txt'],'domain_precipitation_difference','-ascii')

% type('a.txt') % the type function displays the contents of the file


%%
        
        

