%% Initialization
ComPrices = readtable(fullfile('..','Data','ComPrices-DL1995.csv'),'ReadRowNames',true);

ComList = {'Coffee'; 'Copper'; 'Jute'; 'Maize'; 'Palmoil'; 'Sugar'; 'Tin'};

PL        = zeros(length(ComList),1);
exitflag  = zeros(length(ComList),1);
output    = cell(length(ComList),1);
V         = zeros(length(ComList),3);
theta     = zeros(length(ComList),3);
thetainit = zeros(length(ComList),3);
pstar     = zeros(length(ComList),1);

GridLimits = table(-5*ones(7,1),[30 40 30 40 30 20 45]','RowNames',ComList, ...
                   'VariableNames',{'Min' 'Max'});

options = struct('explicit'   , 1,...
                 'useapprox'  , 0,...
                 'display'    , 0,...
                 'optimsolveroptions',optimset('DiffMinChange', eps^(1/3),...
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

N = 1000;

%% Estimate in all situations
iter = 0;
for r=[0.02 0.05]
  for optimsolver={'fminsearch','fminunc'}
    iter = iter+1;
    options.optimsolver = optimsolver{:};
    parfor com=1:length(ComList)
      [Pobs,model,interp,thetainit(com,:)] = initpb(ComList{com},...
                                                    [],...
                                                    r,...
                                                    GridLimits{com,:},...
                                                    N, ...
                                                    ComPrices,...
                                                    options);
      try
        [PL(com),theta(com,:),pstar(com),exitflag(com),output{com},V(com,:)] = MaxPL(...
            thetainit(com,:),...
            Pobs,...
            model,...
            interp,...
            options);
      catch err
        exitflag(com) = 0;
        output{com}   = err;
        PL(com)       = NaN;
        pstar(com)    = NaN;
        theta(com,:)  = NaN;
        V(com,:)      = NaN;
      end
    end

    Results(iter).r           = r; %#ok<*SAGROW>
    Results(iter).optimsolver = optimsolver{:};
    Results(iter).exitflag    = exitflag;
    Results(iter).output      = output;
    Results(iter).PL          = PL;
    Results(iter).pstar       = pstar;
    Results(iter).theta       = theta;
    Results(iter).thetainit   = thetainit;
    Results(iter).V           = V;

  end
end

%% Display estimation results
for i=1:length(Results)
  tmp = FormatResults(Results(i));
  disp(tmp.Properties.Description)
  disp(tmp)
end
