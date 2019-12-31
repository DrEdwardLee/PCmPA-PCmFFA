clc;  clear;  
close all;

%% load paths
currentFolder = pwd;
addpath(genpath(currentFolder)) 
run dipstart.m 

%% Choise a Image for detection 
[filename,pathname]=uigetfile({'*.jpg;*.bmp;*.tif;*.pgm;*.png;*.gif','All Image Files';'*.*','All Files'});
Img = imread([pathname,filename]);
imgPath=strcat(pathname,filename);
disp(['The processing image path is - ',  imgPath ]); 

if ~isequal(ndims(Img), 2)
    Img = rgb2gray(Img);
end
Img = double(Img);
  
%% step 1: preprocessing
Param.winSize = 2;
Param.MapType = 'MinValue';   % 'MinValue'\'MaxValue'
Param.verbose = false;
CellMap = GCAmodel(Img, Param);
if strcmp(Param.MapType, 'MinValue')
   ImgCell = uint8(CellMap.minimum); 
else
   ImgCell = uint8(CellMap.maximum); 
end 


%% step 2: Phase Congruency Enhancement 
nscale = 4; 
norient = 12; 
minWaveLength = 2.5;  
mult = 2.0; 
sigmaOnf = 0.625; 
wb = 'black';  %  'black'\'white'; 
[M,m,or,featType,PC,EO,t,pcSum] = phasecong3(ImgCell, nscale, norient, minWaveLength, mult, sigmaOnf);
maxImPC = PCM( ImgCell, PC, featType, wb, norient );

Dist = 1.5;
WinSize = 3; L = 50;
Imask = gernMask( maxImPC,  Dist,WinSize, L ); 
maxImPC(Imask==0) = 0;
maxImPC = normalize8(maxImPC, 0);


figure(), 
subplot(2, 2, 1),  imshow(Img,[]),            title('Input Image'); 
subplot(2, 2, 2);  imshow(ImgCell, []);       title('Grid Cell Image'); 
subplot(2, 2, 3);  imshow(maxImPC, []);       title('maximum phase congruency map');  
subplot(2, 2, 4);  imshow(Imask, []);         title('mask image');  

% storage the phase congruency result that will be filtered by PCmPA and PCmFFA algorithm
% Do not change the path direction and file's name.
storagepath =strcat(currentFolder  ,'\','PCmFFA'); 
newFilesname =strcat(storagepath ,'\',char('ImgPC'),'.','jpg');  
imwrite(mat2gray(maxImPC), newFilesname);  



%% step 3: PCmPA filtering 
OptionsPCmPA.Lmin = 20;  OptionsPCmPA.Lstep = 5;  OptionsPCmPA.Lmax = 50;   
OptionsPCmPA.constrained = 1;
OptionsPCmPA.rankoder = 'descend';
ResponsePCmPA = PCmPA( uint8(normalize8(maxImPC, 1)), OptionsPCmPA); 
ResponsePCmPA(Imask ==0) = 0; 


%% step 4: PCmFFA filtering
% Do not change the path direction and file's name.
currentPath = strcat(char(currentFolder), '/PCmFFA');
cd(char(currentPath)) ; 
ImgName = char('ImgPC.jpg'); 

DistPCFFA.Dmin = 20;
DistPCFFA.Dstep = 5;
DistPCFFA.Dmax = 50;
wb = 'white'; 
ResponsePCmFFA = PCmFFA( ImgName, Imask, DistPCFFA, wb );
cd(char(currentFolder)) ; 

figure(), 
subplot(1, 3, 1),  imshow(ImgCell,[]),                   title('Input Image');  
subplot(1, 3, 2);  imshow(ResponsePCmPA, []);            title('PCmPA result'); 
subplot(1, 3, 3);  imshow(ResponsePCmFFA, []);            title('PCmFFA result');   


%% storage the results 
storagepath =strcat(currentFolder ,'\','Results');
imageName = strtok( filename,'.bmp');   %返回files(ii)中由'.jpg'指定的字符串前的部分; 
Filesname0 =strcat(storagepath ,'\',char(imageName),'_raw','.','bmp'); 
Filesname1 =strcat(storagepath ,'\',char(imageName),'_PCmPA','.','bmp'); 
Filesname2 =strcat(storagepath ,'\',char(imageName),'_PCmFFA','.','bmp'); 
imwrite(mat2gray(Img) , Filesname0);            % storage raw image
imwrite(mat2gray(ResponsePCmPA) , Filesname1);  % storage PCmPA filtering result
imwrite(mat2gray(ResponsePCmFFA) , Filesname2); % storage PCmFFA filtering result



