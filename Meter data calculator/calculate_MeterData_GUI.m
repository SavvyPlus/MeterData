%% mcc -m calculate_MeterData_GUI.m

function calculate_MeterData_GUI

%  Create and then hide the UI as it is being constructed.
f = figure('Visible','off','Position',[360,500,600,285],'ToolBar','none', 'MenuBar','None');

% Construct the components.

htext1  = uicontrol('Style','text','String','Historical Data Start Date: ', ...
                'FontWeight','bold','Position',[5,220,150,25]);

hdate1_d    = uicontrol('Style','edit',...
             'String','1','Position',[155,220,30,25] );
hdate1_m    = uicontrol('Style','edit',...
             'String','1','Position',[185,220,30,25]);
hdate1_y    = uicontrol('Style','edit',...
             'String','2015','Position',[220,220,40,25]);

         
htext2  = uicontrol('Style','text','String','Historical Data End Date: ', ...
                'FontWeight','bold','Position',[5,190,150,25]);

hdate2_d    = uicontrol('Style','edit',...
             'String','1','Position',[155,190,30,25] );
hdate2_m    = uicontrol('Style','edit',...
             'String','4','Position',[185,190,30,25]);
hdate2_y    = uicontrol('Style','edit',...
             'String','2018','Position',[220,190,40,25]);
         
         
htext3  = uicontrol('Style','text','String','Input File: ', ...
                'FontWeight','bold','Position',[5,160,150,25]);

hinputFile    = uicontrol('Style','edit',...
             'String','Calc.xlsm','Position',[155,160,440,25] );

        
htext4  = uicontrol('Style','text','String','Period Start: ', ...
                'FontWeight','bold','Position',[5,130,150,25]);

hdate4_d    = uicontrol('Style','edit',...
             'String',' ','Position',[155,130,30,25] );
hdate4_m    = uicontrol('Style','edit',...
             'String',' ','Position',[185,130,30,25]);
hdate4_y    = uicontrol('Style','edit',...
             'String',' ','Position',[220,130,40,25]);
         

htext5  = uicontrol('Style','text','String','Number of Months: ', ...
                'FontWeight','bold','Position',[5,100,150,25]);

hdate5_nPeriods    = uicontrol('Style','edit',...
             'String',' ','Position',[155,100,60,25] );         
         
htext6  = uicontrol('Style','text','String','Output File: ', ...
                'FontWeight','bold','Position',[5,70,150,25]);

houtputFile    = uicontrol('Style','edit',...
             'String','MeterData_Client_yyyy-mm-dd.xlsx','Position',[155,70,440,25] );

           
         
h_run = uicontrol('Style','pushbutton',...
             'String','Run','FontWeight','bold','Position',[155,30,70,25],...
             'Callback',@runbutton_Callback);


align([htext1,htext2,htext3,htext4,htext5,htext6],'None','Distribute');
align([hdate1_d,hdate1_m,hdate1_y],'Distribute','Distribute');
align([hdate2_d,hdate2_m,hdate2_y],'Distribute','Distribute');
align([hdate4_d,hdate4_m,hdate4_y],'Distribute','Distribute');


% Initialize the UI.
% Change units to normalized so components resize automatically.
f.Units = 'normalized';
htext1.Units = 'normalized'; htext2.Units = 'normalized'; htext3.Units = 'normalized'; htext4.Units = 'normalized'; htext5.Units = 'normalized'; htext6.Units = 'normalized';
hdate1_d.Units = 'normalized'; hdate1_m.Units = 'normalized'; hdate1_y.Units = 'normalized';
hdate2_d.Units = 'normalized'; hdate2_m.Units = 'normalized'; hdate2_y.Units = 'normalized';
hdate4_d.Units = 'normalized'; hdate4_m.Units = 'normalized'; hdate4_y.Units = 'normalized';
hinputFile.Units = 'normalized'; hdate5_nPeriods.Units = 'normalized'; houtputFile.Units = 'normalized';

h_run.Units = 'normalized';

% Variables
HistStartDate = datenum([str2double(hdate1_y.String), str2double(hdate1_m.String), str2double(hdate1_d.String)]);
HistEndDate = datenum([str2double(hdate2_y.String), str2double(hdate2_m.String), str2double(hdate2_d.String)]);
InputFile = hinputFile.String;
ps = datenum([str2double(hdate4_y.String), str2double(hdate4_m.String), str2double(hdate4_d.String)]);
nPeriods = str2double(hdate5_nPeriods.String);
OutputFile = houtputFile.String;

% Assign the a name to appear in the window title.
f.Name = 'Meter Data Calculator';
f.NumberTitle = 'off';

% Move the window to the center of the screen.
movegui(f,'center')

% Make the window visible.
f.Visible = 'on';



   function runbutton_Callback(source,eventdata)       
       HistStartDate = datenum([str2double(hdate1_y.String), str2double(hdate1_m.String), str2double(hdate1_d.String)]);
       HistEndDate = datenum([str2double(hdate2_y.String), str2double(hdate2_m.String), str2double(hdate2_d.String)]);
       InputFile = hinputFile.String;
       ps = datenum([str2double(hdate4_y.String), str2double(hdate4_m.String), str2double(hdate4_d.String)]);
       nPeriods = str2double(hdate5_nPeriods.String);
       OutputFile = houtputFile.String;

       calculate_MeterData_func(HistStartDate, HistEndDate, InputFile, ps, nPeriods, OutputFile);
   end


end