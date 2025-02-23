%% Supplementary results 1 (S1)
% Late Combination shows that MEG adds to MRI in classifying MCI versus Controls
% (BioFIND dataset)
%
% This script contains noise simulation analyses in supplementary materials
% paper ""

% Henson R.N 2020, Vaghari D 2020

%% Define Paths ands variables

% Assumed you are in the MKL directory (see readme),
%cd MKL
addpath('supplementary'); 
 
clear

participants = readtable('participants-imputed.tsv','FileType','text');
% Remove noisy-MRIs and non-MRI subjects
mri_num      = grp2idx(participants.sImaging);
mri_num([23 197]) = 2;
participants(mri_num==2,:) = [];

X = [participants.MMSE  participants.Edu_years participants.age participants.sex]; 
X = zscore(X);

y = csvread(fullfile('derived','labels.csv'));

No  = size(y,1) % Number of observations
Nsf = size(X,2) % Number of signal features
Nnf = 1000       % Number of noise features

Np = 1000;      % Number of  noise randomisations (not permutations)

% test whether parpool  already open with numel(group etc...)
if isempty(gcp('nocreate')) 
    try parpool(min(Np,100)); end
end

rng('default') % for reproducibility

Signal = X; 

accuracy1 = cell(1,Np); % For intermediate combination
accuracy2 = cell(1,Np); % For late combination
    
parfor p = 1:Np % Number of noise realisations
    
    Noise = randn(No, Nnf);
    
    V = {};
    V{1} = {Noise};
    V{2} = {Signal(:,1)};
    V{3} = {[Signal(:,1) Noise]}; % early combination (concatenation)
    % V{4} = {Signal(:,1), Noise};  % two separate kernels
    V{4} = mat2cell([Signal(:,1) Noise],No,ones(1,1+Nnf));  % all separate kernels
    V{5} = mat2cell(Signal,No,ones(1,Nsf));

    [acc1,acc2] = mkl_ens(V,y,'Hyper1',0.1,'Hyper2',1,'Nfold',5,'Nrun',1,'PCA_cut',0,'feat_norm',1,'ens',1);
    
    accuracy1{p} = mean(mean(acc1,3),1);
    accuracy2{p} = mean(mean(acc2,3),1);
    fprintf('p=%d, acc1=%s, acc2=%s\n',p,mat2str(round(accuracy1{p})),mat2str(round(accuracy2{p})))
end

accuracy1 = cat(1,accuracy1{:});
mean(accuracy1)
accuracy2 = cat(1,accuracy2{:});
mean(accuracy2)

save noise_sim accuracy1 accuracy2

% Plot resluts (Classification accuracy and Pos-hoc comparison)

titles = {'Noise','Signal1','Signal1+Noise','Signal1,Noise','Signal1,Signal2-4'};
%  define contrasts
c   = [-1 1 0 0 0;
       0 1 0 -1 0;
       0 0 -1 1 0];
%con_titles = {'Signal1>Noise','Signal1>Signal1,Noise','Signal1,Noise>Signal1+Noise'};
% Plot resluts (Classification accuracy and Pos-hoc comparison)

titles = {'Noise','Signal1','Signal1+Noise','Signal1,Noise','Signal1,Signal2-4'};
%  define contrasts
c   = [-1 1 0 0 0;
       0 1 0 -1 0;
       0 0 -1 1 0];
   
[f1] = plot_results(titles,accuracy1)%,con_titles,c)
sgtitle(sprintf('Intermediate, Nf = %d', Nnf)) % supp fig1 - left panel

[f2] = plot_results(titles,accuracy2)
sgtitle(sprintf('Late, Nf = %d', Nnf)) % supp fig1 - right panel
   
[f3] = plot_results([],[],titles,[-eye(5) eye(5)],[accuracy1 accuracy2]) 
sgtitle(sprintf('Late - Intermediate'))  % supp fig2 - right panel
