%% Initialization
ComPrices = readtable(fullfile('..','Data','ComPrices-DL1995.csv'),'ReadRowNames',true);

ComList = {'Coffee'; 'Copper'; 'Jute'; 'Maize'; 'Palmoil'; 'Sugar'; 'Tin'};

NActiveParams = 3;
Lik           = zeros(length(ComList),1);
exitflag      = zeros(length(ComList),1);
output        = cell(length(ComList),1);
V             = zeros(length(ComList),NActiveParams);
theta         = zeros(4,length(ComList));
thetainit     = zeros(4,length(ComList));
pstar         = zeros(length(ComList),1);
G             = zeros(length(ComList),1);

GridLimits = table(-5*ones(7,1),[30 40 30 40 30 20 45]','RowNames',ComList, ...
                   'VariableNames',{'Min' 'Max'});

options = struct('ActiveParams' , [1 1 0 1],...
                 'explicit'     , 1,...
                 'useapprox'    , 0,...
                 'display'      , 0,...
                 'reesolveroptions',struct('atol',1E-10),...
                 'cov'          , 3,...
                 'ParamsTransformInvDer', @(P) [1; -exp(P(2)); exp(P(3)); exp(P(4))],...
                 'solveroptions',optimset('DiffMinChange', eps^(1/3),...
                                          'Display'      , 'off',...
                                          'FinDiffType'  , 'central',...
                                          'LargeScale'   , 'off',...
                                          'MaxFunEvals'  , 2000,...
                                          'MaxIter'      , 1000,...
                                          'TolFun'       , 1e-6,...
                                          'TolX'         , 1e-7,...
                                          'UseParallel'  , 'never'),...
                 'numjacoptions',struct([]),...
                 'numhessianoptions',struct('FinDiffRelStep'  , 1E-3,...
                                            'UseParallel'     , 'never'),...
                 'T'          , 5,...
                 'UseParallel', 'never');

warning('off','backtrace');
warning('off','RECS:FailureREE');
warning('off','MATLAB:interp1:ppGriddedInterpolant');
N = 1000;

r=0.02;
options.ParamsTransform = @(P) [P(1); log(-P(2)); log(P(3)+r); log(P(4))];
options.ParamsTransformInv = @(P) [P(1); -exp(P(2)); exp(P(3))-r; exp(P(4))];
solver={'fminsearch'};
options.solver = solver{:};
com=1;
[Pobs,model,interp,tmp] = initpb(ComList{com},...
                                 [],...
                                 r,...
                                 GridLimits{com,:},...
                                 N, ...
                                 ComPrices,...
                                 options);
interp            = SolveStorageRECS(model,interp,options);
par                   = num2cell(model.params);
[a, b, delta, k, r]   = par{:}; %#ok<ASGLU>
s = interp.s;
Agrid = linspace(min(s),max(s),1000)';
cx = interp.cx;
invDemandFunction = interp1(interp.x(:,2),s,'spline','pp');
[breaks,coefs,l,order,d] = unmkpp(invDemandFunction);
dinvDemandFunction       = mkpp(breaks,repmat(order-1:-1:1,d*l,1).*coefs(:,1:order-1),d);

dPriceFunction    = 1./funeval(cx(:,2),interp.fspace,Agrid,1);

plot(funeval(cx(:,2),interp.fspace,Agrid),[dPriceFunction ...
                    ppval(dinvDemandFunction,funeval(cx(:,2),interp.fspace,Agrid)) ones(size(Agrid))/b])
plot(funeval(cx(:,2),interp.fspace,Agrid),[dPriceFunction ones(size(Agrid))/b])
plot(funeval(cx(:,2),interp.fspace,Agrid),[ppval(dinvDemandFunction,funeval(cx(:,2),interp.fspace,Agrid)) ones(size(Agrid))/b])
xlim([0 1])
ylim([-50 0])
